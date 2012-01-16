/* Controller class for Gnonograms
 * Copyright (C) 2010-2011  Jeremy Wootten
 *
	This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 *  Author:
 * 	Jeremy Wootten <jeremwootten@gmail.com>
 */

using Gtk;
using Gdk;

public class Gnonogram_controller
{
	public Gnonogram_view _gnonogram_view;
	public Gnonogram_LabelBox _colbox;
	public Gnonogram_LabelBox _rowbox;
	public Gnonogram_CellGrid _cellgrid;
	public Gnonogram_model _model;
	public Gnonogram_solver _solver;

	private Cell _current_cell;
	private Cell _previous_cell;
	private Cell _guess_cell;
	private Circular_move_buffer _history;
	private Timer _timer;
	private double _time_penalty;
	private GameState _state;
	private CellPatternType _patterntype;

	private bool _is_button_down;
	private bool _have_solution;
	private bool _gridlinesvisible;
	private bool _toolbarvisible;
	private bool _advanced;
	private bool _difficult;
	private bool _penalty;
	private bool _solution_changed;

	private int _grade;
	private int _rows;
	private int _cols;
	private double screen_width;
	private double screen_height;

	public Gnonogram_controller(string game_filename)
	{
		_history=new Circular_move_buffer(Resource.MAXUNDO);
		_timer=new Timer();
		_model=new Gnonogram_model();
		_solver=new Gnonogram_solver();

		var scr = Gdk.Screen.get_default();
		screen_width=0.75*((double)scr.get_width());
		screen_height=0.75*((double)scr.get_height());

		load_config();
		create_view();
		_gnonogram_view.show_all();
		initialize_menus();


		_model.set_dimensions(_rows,_cols);
		_solver.showsolvergrid.connect(show_solver_grid);
		_solver.showprogress.connect((guesses)=>{
			_gnonogram_view.set_score(guesses.to_string());
			_gnonogram_view.show_info();
		});
		_solver.set_dimensions(_rows,_cols);

		if(game_filename.length>4){
			load_game(game_filename);
		}
		else new_game(false);
	}

	private void create_view()
	{	//stdout.printf("create view\n");
		_rowbox = new Gnonogram_LabelBox(_rows, _cols, false);
		_colbox = new Gnonogram_LabelBox(_cols, _rows, true);
		set_default_fontheight(_rows, _cols);
		_rowbox.set_all_to_zero();
		_colbox.set_all_to_zero();

		_cellgrid = new Gnonogram_CellGrid(_rows,_cols);
		_gnonogram_view = new Gnonogram_view(_rowbox, _colbox, _cellgrid);

		try{
			_gnonogram_view.set_icon_from_file(Resource.icon_dir+"/gnonograms.svg");
		}
		catch (GLib.Error e) {stdout.printf("Icon file not loaded\n");}


		_gnonogram_view.savegame.connect(this.save_game);
		_gnonogram_view.savepictogame.connect(this.save_pictogame);
		_gnonogram_view.loadgame.connect(this.load_game);
		_gnonogram_view.importimage.connect(this.import_image);
		_gnonogram_view.quitgamesignal.connect(()=>{quit_game();});
		_gnonogram_view.newgame.connect(()=>{this.new_game(true);});

		_gnonogram_view.undoredo.connect(this.undoredo);
		_gnonogram_view.undoerrors.connect(this.undo_to_no_errors);
		_gnonogram_view.hidegame.connect(this.start_solving);
		_gnonogram_view.revealgame.connect(this.reveal_solution);
		_gnonogram_view.checkerrors.connect(this.peek_game);
		_gnonogram_view.pausegame.connect(this.pause_game);
		_gnonogram_view.restartgame.connect(()=>{this.restart_game(true);});
		_gnonogram_view.randomgame.connect(this.random_game);
		_gnonogram_view.solvegame.connect(this.viewer_solve_game);
		_gnonogram_view.editgame.connect(this.edit_game);
		_gnonogram_view.trimgame.connect(this.trim_game);

		_gnonogram_view.setcolors.connect(()=>{Resource.set_colors(); redraw_all();});
		_gnonogram_view.setfont.connect(()=>{
				Resource.set_custom_font();
				_rowbox.change_font_height(false);
				_colbox.change_font_height(false);
			});
		_gnonogram_view.setpattern.connect((patterntype)=>{
				_patterntype=patterntype;
				redraw_all();
			});
		_gnonogram_view.resizegame.connect(this.change_size);
		_gnonogram_view.key_press_event.connect(this.key_pressed);
		_gnonogram_view.key_release_event.connect(this.key_released);
		_gnonogram_view.setdifficulty.connect(this.set_difficulty);
		_gnonogram_view.togglegrid.connect(this.gridlines_toggled);
		_gnonogram_view.toggletoolbar.connect(this.toolbar_toggled);
		_gnonogram_view.changefont.connect(this.change_font_size);

		_gnonogram_view.advancedmode.connect((advanced)=>{_advanced=advanced;});
		_gnonogram_view.difficultmode.connect((difficult)=>{_difficult=difficult;});
		_gnonogram_view.penaltymode.connect((penalty)=>{_penalty=penalty;});
		_gnonogram_view.resetall.connect(this.reset_all_to_default);
		_gnonogram_view.set_grade_spin_value((double)_grade);

		_cellgrid.cursor_moved.connect(this.grid_cursor_moved);
		_cellgrid.button_press_event.connect(this.button_pressed);
		_cellgrid.button_release_event.connect(()=>{this._is_button_down=false; return true;});
		_cellgrid.expose_event.connect(()=>{
			redraw_all();
			return true;
		});
	}

	private void initialize_view()
	{ 	//stdout.printf("Initialise view\n");
		initialize_cursor();
		unset_guess_cell();
		if (_have_solution) update_labels_from_model();
		_gnonogram_view.set_size_label(_rows,_cols);
		_history.initialise_pointers();
		_solution_changed=false;
	}

	private void initialize_menus()
	{	//stdout.printf("initialize_menus\n");
		_gnonogram_view.set_advancedmenuitem_active(_advanced);
		_gnonogram_view.set_difficultmenuitem_active(_difficult);
		_gnonogram_view.set_penaltymenuitem_active(_penalty);
		_gnonogram_view.set_gridmenuitem_active(_gridlinesvisible);
		_gnonogram_view.set_toolbarmenuitem_active(_toolbarvisible);
	}


	private void initialize_cursor()
	{	//stdout.printf("Initialise cursor\n");
		_current_cell.row=-1;
		_current_cell.col=-1;
		_current_cell.state=CellState.UNKNOWN;
		_previous_cell.row=-1;
		_previous_cell.col=-1;
		_previous_cell.state=CellState.UNKNOWN;
		_is_button_down=false;
	}


	private void reset_all_to_default()
	{
		Resource.reset_all();
		resize(Resource.DEFAULT_ROWS,Resource.DEFAULT_COLS);
		_gnonogram_view.set_grade_spin_value((double)Resource.DEFAULT_DIFFICULTY);
		_difficult=false;
		_advanced=true;
		_penalty=true;
		_gridlinesvisible=true;
		_toolbarvisible=true;
		initialize_view();
		initialize_menus();
	}

	private void change_size()
	{
		int r,c;
		if (Utils.get_dimensions(out r,out c,_rows,_cols))
		{
			resize(r,c);
			new_game(false);
		}
	}

	private void resize(int r, int c)
	{	//stdout.printf("Resize\n");
		if (r>Resource.MAXSIZE||c>Resource.MAXSIZE) return;
		if (r==_rows && c==_cols) return;
		if(r<1)r=1;
		if(c<1)c=1;
		resize_view(r,c);
		set_default_fontheight(r,c);
		_solver.set_dimensions(r,c);
		_model.set_dimensions(r,c);
		_rows=r; _cols=c;
	}

	private void resize_view(int r, int c)
	{	//stdout.printf("Resize_view\n");
		_rowbox.resize(r, c);
		_colbox.resize(c, r);
		_cellgrid.resize(r,c);
	}

	private void set_default_fontheight(int r, int c)
	{
		double maxrowheight, maxcolwidth, deffontheight;

		maxrowheight=screen_height/((double)(r)*1.4);
		maxcolwidth=screen_width/((double)(c)*1.4);
		deffontheight=double.min(maxrowheight,maxcolwidth)*0.7;

		_rowbox.set_font_height(deffontheight);
		_colbox.set_font_height(deffontheight);
	}

	private void gridlines_toggled(bool active)
	{	//stdout.printf("Gridlines toggled\n");
		if (_gridlinesvisible!=active){
			_gridlinesvisible=active;
			redraw_all();
		}
	}

	private void toolbar_toggled(bool active)
	{
		//stdout.printf("Toolbar visible toggled active %s \n", active.to_string());
		_toolbarvisible=active;
		_gnonogram_view.set_toolbar_visible(_toolbarvisible);
	}

	private bool button_pressed(Gdk.EventButton e)
	{
		//stdout.printf("Button pressed\n");
		ButtonPress b=ButtonPress.UNDEFINED;
		if (e.type!=EventType.@2BUTTON_PRESS){
			switch (e.button){
				case 1: b = ButtonPress.LEFT_SINGLE; break;
				case 3: b = ButtonPress.RIGHT_SINGLE; break;
				default: break;
			}
		}
		else b = ButtonPress.LEFT_DOUBLE;

		CellState cs= CellState.UNDEFINED;
		if (b!=ButtonPress.UNDEFINED){
			switch (b){
				case ButtonPress.LEFT_DOUBLE:
					if(_state==GameState.SOLVING) cs=CellState.UNKNOWN;
					break;
				case ButtonPress.LEFT_SINGLE:
					cs=CellState.FILLED;
					break;
				case ButtonPress.RIGHT_SINGLE:
					cs=CellState.EMPTY;
					break;
				default:
					break;
			}
		process_press(cs);
		}
		return true;
	}


	private bool key_pressed(Gdk.EventKey e)
	{
		string name=(Gdk.keyval_name(e.keyval)).up();
		//stdout.printf(@"Key pressed $name\n");
		int currentrow=_current_cell.row;
		int currentcol=_current_cell.col;
		if (name=="SPACE") return true; //prevent activation of toolbar items with spacebar
		if (currentrow<0||currentcol<0||currentrow>_rows-1||currentcol>_cols-1) return false;
		CellState cs=CellState.UNDEFINED;
		switch (name){
			case "UP":
					if (currentrow>0)currentrow-=1;
					break;
			case "DOWN":
					if (currentrow<_rows-1)currentrow+=1;
					break;
			case	"LEFT":
					if (currentcol>0)currentcol-=1;
					break;
			case "RIGHT":
					if (currentcol<_cols-1)currentcol+=1;
					break;
			case "F": //TODO make configurable
			case "f":
					cs=CellState.FILLED;
					break;
			case "E":  //TODO make configurable
			case "e":
					cs=CellState.EMPTY;
					break;
			case "X":  //TODO make configurable
			case "x":
					if (_state==GameState.SOLVING )cs=CellState.UNKNOWN;
					break;
			case "M":
			case "m":
					if (_state==GameState.SOLVING )	mark_cell(_current_cell);
					break;
			case "L":
			case "l":
					if (_state==GameState.SOLVING ) return_to_mark();
					break;

			default:
					return false;
		}
		if (currentrow!=_current_cell.row || currentcol!=_current_cell.col)
		{
			grid_cursor_moved(currentrow,currentcol);
		}

		process_press(cs);
		return true;
	}

	private void process_press(CellState cs)
	{
		if(cs!=CellState.UNDEFINED)
		{
			_is_button_down=true;
			if(_current_cell.state!=cs && !_current_cell.same_coords(_guess_cell))
			{
				_current_cell.state=cs;
				make_move(_current_cell);
			}
		}
	}

	private bool key_released(Gdk.EventKey e)
	{
		string name=(Gdk.keyval_name(e.keyval)).up();
		if (name=="UP"||name=="DOWN"||name=="LEFT"||name=="RIGHT") {}
		else _is_button_down=false;
		return true;
	}

	private void change_font_size(bool increase)
	{
		_rowbox.change_font_height(increase);
		_colbox.change_font_height(increase);
		// if making smaller, force to minimum window size for given font
		if (!increase) _gnonogram_view.resize(100,150);
	}

	public void grid_cursor_moved(int r, int c)
	{//deals with mouse/touchpad movement
		if (r<0||r>=_rows||c<0||c>=_cols)//pointer has left grid
		{
			//make sure no cell or label is highlighted
				highlight_labels_and_cell(_previous_cell,false);
				highlight_labels_and_cell(_current_cell,false);
			_current_cell.row=-1;
			return;
		}

		_previous_cell.copy(_current_cell);
		if (_current_cell.row!=r || _current_cell.col!=c)
		{	//pointer moved to different cell
			//remove highlights from previous cell
			highlight_labels_and_cell(_previous_cell, false);

			if (_is_button_down)
			{
				_current_cell={r,c,_previous_cell.state};
				make_move(_current_cell);
			}
			else
			{
				_current_cell=_model.get_cell(r,c);
				//redraw_cell(_current_cell,true);
			}

			highlight_labels_and_cell(_current_cell, true);
		}
	}

	private void highlight_labels_and_cell(Cell c, bool is_highlight)
	{
		_rowbox.highlight(c.row, is_highlight);
		_colbox.highlight(c.col, is_highlight);
		redraw_cell(c,is_highlight);
	}

	private void set_guess_cell(Cell c)
	{
		_guess_cell.copy(c);
	}
	private void unset_guess_cell()
	{
		_guess_cell={-1,-1,CellState.UNKNOWN};
	}

	private void mark_cell(Cell c)
	{//stdout.printf("Mark guess cell "+_current_cell.to_string()+"\n");
		if (_current_cell.state==CellState.UNKNOWN) return;
		Cell lastguess=_guess_cell;
		set_guess_cell(_current_cell);
		if (lastguess.row>=0) redraw_cell(lastguess,false);
		redraw_cell(_guess_cell,true);
	}
	private void return_to_mark()
	{
		if(_guess_cell.row<0) return;
		Cell? c;
		while (true)
		{
			c=undo_move();
			if (c==null) break;
			if (_guess_cell.same_coords(c))	break;
		}
		unset_guess_cell();
		_is_button_down=false;
		if (c!=null) grid_cursor_moved(c.row,c.col);
	}

	private void undoredo(bool undo)
	{
		//direction true = undo; false=redo
		//stdout.printf("Undoredo\n");
		if (undo) undo_move();
		else redo_move();
	}

	private void undo_to_no_errors()
	{
		int count=0;
		while(_model.count_errors()>0)
		{
			undo_move();
			count++;
		}
		if (_penalty)
		{
			incur_penalty(count);
			Utils.show_info_dialog(_("Total time penalty now %4.0f seconds").printf(_time_penalty));
		}
	}

	private void make_move(Cell c)
	{
		//stdout.printf("make_move\n");
		//move={previous contents, replacement contents}
		Move mv={_model.get_cell(c.row,c.col),c};
		_history.new_data(mv);
		update_cell(c,true);
		_gnonogram_view.set_redo_sensitive(false);
		_gnonogram_view.set_undo_sensitive(true);
	}

	private Cell? undo_move()
	{
		//stdout.printf("undo_move\n");
		Move? mv=_history.previous_data();
		if (mv==null){
			_gnonogram_view.set_undo_sensitive(false);
			return null;
		}
		//update cell with its previous contents
		update_cell(mv.previous,false);
		_gnonogram_view.set_redo_sensitive(true);

		grid_cursor_moved(mv.previous.row, mv.previous.col);

		if (_history.no_more_previous_data())
		{
			_gnonogram_view.set_undo_sensitive(false);
			if (_state==GameState.SETTING) _solution_changed=false;
		}
		return mv.previous;
	}

	private void redo_move()
	{
		//stdout.printf("redo_move\n");
		redraw_cell(_current_cell,false);
		Move? mv=_history.next_data();
		if (mv==null){
			_gnonogram_view.set_redo_sensitive(false);
			return;
		}

		//if (_previous_cell.same_coords(mv.replacement))
		_previous_cell.copy(mv.replacement);
		//if (_current_cell.same_coords(mv.replacement))
		_current_cell.copy(mv.replacement);

		update_cell(mv.replacement,true);
		_gnonogram_view.set_undo_sensitive(true);

		if (_history.no_more_next_data()) _gnonogram_view.set_redo_sensitive(false);
	}

	public void update_cell(Cell c, bool highlight)
	{
		//stdout.printf("update_cell\n");
		_model.set_data_from_cell(c);
		redraw_cell(c,highlight);

		if (_state==GameState.SETTING)
		{
			_rowbox.update_label(c.row, _model.get_label_text(c.row,false));
			_colbox.update_label(c.col, _model.get_label_text(c.col,true));
			_solution_changed=true;
		}
		else	check_solved();
	}

	private void check_solved()
	{
		if (_model.count_unsolved()==0 && check_valid_solution()) {
				_timer.stop();
				Utils.show_info_dialog(_("Congratulations - you have solved the puzzle.\n\n")+get_time_taken());
				_is_button_down=false;
		}
	}

	private bool check_valid_solution()
	{
		for (int r=0; r<_rows; r++){
			if (_model.get_label_text(r,false,false)!=_rowbox.get_label_text(r)) return false;
		}
		for (int c=0; c<_cols; c++){
			if (_model.get_label_text(c,true,false)!=_colbox.get_label_text(c)) return false;
		}
		return true;
	}

	private void redraw_all()
	{
		//stdout.printf("Redraw all\n");
		_cellgrid.prepare_to_redraw_cells(_state,_gridlinesvisible,_patterntype);
		for (int r=0; r<_rows; r++){
			for (int c=0; c<_cols; c++){
					_cellgrid.draw_cell(_model.get_cell(r,c));
			}
		}
		if (_guess_cell.row>=0) _cellgrid.draw_cell(_guess_cell,false,true);
	}

	private void redraw_cell(Cell c, bool highlight)
	{ //get state of cell from model not c
		_cellgrid.draw_cell(_model.get_cell(c.row,c.col),highlight,c.same_coords(_guess_cell));
	}

	public void new_game(bool confirm=false)
	{
		//stdout.printf("New game\n");
		if(confirm && !Utils.show_confirm_dialog(_("New puzzle?"))) return;
		_model.clear();
		_have_solution=true;
		initialize_view();
		change_state(GameState.SETTING);
		_gnonogram_view.set_name(_("New puzzle"));
		_gnonogram_view.set_source(Environment.get_user_name());
		_gnonogram_view.set_date(Utils.get_todays_date_string());
		_gnonogram_view.set_license("");
		_gnonogram_view.set_score("");
		redraw_all();
	}

	public void restart_game(bool confirm=true)
	{
		//stdout.printf("Restart game\n");
		if (_state!=GameState.SOLVING) return;
		if (confirm && !Utils.show_confirm_dialog(_("Restart solving the puzzle?"))) return;
		_model.blank_working();
		_timer.reset();

		change_state(GameState.SOLVING);//resets view etc
		redraw_all();
	}

	public void pause_game()
	{
		//stdout.printf("Pause game\n");
		if (_state!=GameState.SOLVING) return;
		_timer.stop();
		Utils.show_info_dialog(_("Timer paused"));
		_timer.continue();
		_is_button_down=false;
	}

	public void save_game()
	{
		string filename;
		filename=Utils.get_filename(
			Gtk.FileChooserAction.SAVE,
			_("Name and save this puzzle"),
			{_("Gnonogram puzzles")},
			{"*"+Resource.GAMEFILEEXTENSION},
			Resource.save_game_dir
			);

		if (filename=="") return; //user cancelled
		if (filename.length>3 && filename[-4:filename.length]!=Resource.GAMEFILEEXTENSION){
			filename = filename+Resource.GAMEFILEEXTENSION;
		}

		var f=FileStream.open(filename,"w");
		if (f==null)
		{
			Utils.show_warning_dialog((_("Could not write to '%s'")).printf(filename));
		}
		else {
			write_position_file(f);
			Utils.show_info_dialog((_("Saved as '%s'")).printf(Path.get_basename(filename)));
		}
	}

	public void save_pictogame()
	{
		string filename;
		filename=Utils.get_filename(
			Gtk.FileChooserAction.SAVE,
			_("Name and save as  picto puzzle"),
			{_("Picto puzzles")},
			{"*.pattern"},
			Resource.save_game_dir
			);

		if (filename=="") return; //message?
		if (filename.length<9||filename[-8:filename.length]!=".pattern"){
			 filename = filename+".pattern";
		}

		var f=FileStream.open(filename,"w");
		if (f==null)
		{
			Utils.show_warning_dialog((_("Could not write to '%s'")).printf(filename));
		}
		else {
			write_pictogame_file(f);
			Utils.show_info_dialog((_("Saved as '%s'")).printf(Path.get_basename(filename)));
		}
	}

	private void write_game_file(FileStream f)
	{
		//stdout.printf("In write game file\n");
		f.printf("[Description]\n");
		f.printf("%s\n",_gnonogram_view.get_name());
		f.printf("%s\n",_gnonogram_view.get_author());
		f.printf("%s\n",_gnonogram_view.get_date());
		f.printf("%s\n",_gnonogram_view.get_score());

		f.printf("[License]\n");
		f.printf("%s\n",_gnonogram_view.get_license());

		f.printf("[Dimensions]\n");
		f.printf("%d\n",_rows);
		f.printf("%d\n",_cols);
		f.printf("[Row clues]\n");
		f.printf(_rowbox.to_string());
		f.printf("[Column clues]\n");
		f.printf(_colbox.to_string());
		if(_have_solution){
			_model.use_solution();
			f.printf("[Solution]\n");
			f.printf(_model.to_string());
		}
		if (_state==GameState.SOLVING) _model.use_working();
		f.flush();
	}

	private void write_pictogame_file(FileStream f)
	{
		//stdout.printf("In write pictogame file\n");
		f.printf("# Title: ");
		f.printf("%s\n",_gnonogram_view.get_name());
		f.printf("# Author: ");
		f.printf("%s\n",_gnonogram_view.get_author());
		f.printf("# Date: ");
		f.printf("%s\n",_gnonogram_view.get_date());
		f.printf("# X Size: ");
		f.printf("%d\n",_cols);
		f.printf("# Y Size: ");
		f.printf("%d\n",_rows);
		f.printf("\n");

		_model.use_solution();
		f.printf(_model.to_hexstring());
		if (_state==GameState.SOLVING) _model.use_working();
		f.flush();
	}

	private void write_position_file(FileStream f)
	{
		//stdout.printf("In write position file\n");
		write_game_file(f);
		_model.use_working();
		f.printf("[Working grid]\n");
		f.printf(_model.to_string());
		f.printf("[State]\n");
		f.printf(_state.to_string()+"\n");
		f.flush();
		if (_state==GameState.SETTING) _model.use_solution();
	}

	public void load_game(string fname="")
	{
		//stdout.printf("load_game fname %s\n",fname);
		var reader = new Gnonogram_filereader(fname);
		if (reader.filename=="") return;
		new_game(false); //changes to setting state

		if (load_common(reader) && load_position_extra(reader))
		{
			if (reader.has_state && reader.state==(GameState.SETTING).to_string())
			{
				change_state(GameState.SETTING);
			}
			else
			{
				change_state(GameState.SOLVING);
			}
		}
		else Utils.show_warning_dialog(_("Failed to load puzzle"));
		redraw_all();
	}


	private bool load_position_extra(Gnonogram_filereader reader)
	{
		if (reader.has_working){
			_model.use_working();
			for (int i=0; i<_rows; i++){
				_model.set_row_data_from_string(i,reader.working[i]);
			}
		}
		return true;
	}

	private bool load_common(Gnonogram_filereader reader)
	{
		_have_solution=false;

		if (!reader.open_datainputstream())	{
			Utils.show_warning_dialog(_("Could not open puzzle file"));
			return false;
		}

		if (!reader.parse_game_file()){
			Utils.show_warning_dialog(_("File format incorrect")+"\n"+reader.err_msg);
			return false;
		}

		if (reader.has_dimensions){
			if (reader.rows>Resource.MAXSIZE||reader.cols>Resource.MAXSIZE){
				Utils.show_warning_dialog(_("Dimensions too large"));
				return false;
			}
			else if (reader.rows<1||reader.cols<1){
				Utils.show_warning_dialog(_("Dimensions too small"));
				return false;
			}
			else resize(reader.rows,reader.cols);
			_gnonogram_view.set_size_label(_rows,_cols);
		}
		else
		{
			Utils.show_warning_dialog(_("Dimensions data missing"));
			return false;
		}

		if (reader.has_solution){
			_model.use_solution();
			for (int i=0; i<_rows; i++)  _model.set_row_data_from_string(i,reader.solution[i]);
			update_labels_from_model();
			_have_solution=true;
		}
		else if (reader.has_row_clues && reader.has_col_clues){
			for (int i=0; i<_rows; i++) _rowbox.update_label(i,reader.row_clues[i]);
			for (int i=0; i<_cols; i++) _colbox.update_label(i,reader.col_clues[i]);
			int passes=solve_game(false,true,false);
			if (passes>0 && passes<999999){
				_have_solution=true;
				set_solution_from_solver();
			}
			else if (passes<0) {
				Utils.show_warning_dialog(_("Clues contradictory"));
				invalid_clues();
				return false;
			}
			else {
				Utils.show_info_dialog(_("Puzzle not easily soluble by computer"));
			}
		}
		else {
			Utils.show_warning_dialog(_("Clues and solution both missing"));
			return false;
		}

		if (reader.name.length>1) _gnonogram_view.set_name(reader.name);
		else _gnonogram_view.set_name(Path.get_basename(reader.filename));

		_gnonogram_view.set_source(reader.author);
		_gnonogram_view.set_date(reader.date);
		_gnonogram_view.set_license(reader.license);
		_gnonogram_view.set_score(reader.score);

		return true;
	}

	private void import_image()
	{
		//stdout.printf("Import image");
		new_game(false);
		Environment.set_current_dir("/usr/share/icons");
		Img2gno image_convertor=new Img2gno();

		image_convertor.show_all();
		var response=image_convertor.run();

		if (response==Gtk.ResponseType.OK)
		{
			int rows=image_convertor.get_rows();
			int cols= image_convertor.get_cols();

			resize(rows,cols);
			_model.use_solution();
			for (int r=0;r<_rows;r++)
			{
				_model.set_row_data_from_array(r,image_convertor.get_state_array(r));
				update_labels_from_model();
				_have_solution=true;
			}
		}
		image_convertor.destroy();
		change_state(GameState.SETTING);
		initialize_view();
		redraw_all();
	}


	public void start_solving()
	{
		//stdout.printf("Start solving\n");
		change_state(GameState.SOLVING);
		_time_penalty=0;
		redraw_all();
	}

	public void reveal_solution()
	{
		//stdout.printf("Reveal solution\n");
		change_state(GameState.SETTING);
		redraw_all();
	}

	public void peek_game()
	{
		//stdout.printf("Peek game\n");
		if (_have_solution){
			int count=_model.count_errors();
			if (_penalty)	incur_penalty(count);
			if (count==0)
			{
				Utils.show_info_dialog(_("No errors\n\n")+get_time_taken());
			}
			else{
				redraw_all(); //show incorrect cells
				Utils.show_info_dialog((_("Incorrect cells: %d\n\n"+get_time_taken())).printf(count));
				_model.clear_errors();
			}
			redraw_all();
		}
		else{
			Utils.show_info_dialog(_("No solution available\n\n"+get_time_taken()));
		}
	}

	private void incur_penalty(int incorrect_cells)
	{	//stdout.printf("incurred time penalty\n");
		if (_penalty)
		{
			_time_penalty+=Resource.FIXED_TIMEPENALTY+Resource.PER_CELL_TIMEPENALTY*incorrect_cells;
		}
		//stdout.printf(@"time penalty $_time_penalty\n");
	}

	private string get_time_taken()
	{
		double seconds=_timer.elapsed() + _time_penalty;
		int hours= ((int)seconds)/3600;
		seconds-=((double)hours)*3600.000;
		int minutes=((int)seconds)/60;
		seconds-=(double)(minutes)*60.000;
		string s=(_("Time taken: %d hours, %d minutes, %8.3f seconds")).printf(hours, minutes, seconds) +"\n\n";
		if (_penalty) s=s+(_("Including %4.0f seconds time penalty")).printf(_time_penalty);
		return s;
	}


	private void viewer_solve_game()
	{
		//stdout.printf("Viewer_solve_game\n");
		change_state(GameState.SOLVING);
		if (_rows==1) //assume testing mode keep existing cell entries
		{}
		else restart_game(false); //clears any erroneous entries and also re-starts timer

		int passes = solve_game(true, _advanced,_advanced);
		_timer.stop();
		double secs_taken=_timer.elapsed();
		show_solver_grid();
		switch (passes) {
			case -2:
				break;  //debug mode
			case -1:
				invalid_clues();
				break;
			case 0:
				Utils.show_info_dialog(_("Failed to solve or no unique solution"));
				break;
			case 9999999:
				Utils.show_info_dialog(_("Cancelled by user"));
				break;
			default:
				_gnonogram_view.set_score(passes.to_string());
				Utils.show_info_dialog((_("Solved in %8.3f seconds").printf(secs_taken)));

				if (!_have_solution){
					_have_solution=true;
					set_solution_from_solver();
				}
				break;
		}
		redraw_all();
	}

	private void show_solver_grid()
	{
		set_working_from_solver();
	}

	private int solve_clues(string[] row_clues, string[] col_clues, My2DCellArray? startgrid, bool use_advanced, bool use_ultimate)
	{
		int passes=0;
		_solver.initialize(row_clues, col_clues, startgrid);
		//assume debug mode for single row
		passes=_solver.solve_it(_rows==1, use_advanced, use_ultimate);
		return passes;
	}

	private int solve_game(bool use_startgrid, bool use_advanced, bool use_ultimate)
	{
		var row_clues= new string[_rows];
		var col_clues= new string[_cols];
		My2DCellArray startgrid;

		if (use_startgrid) {
			startgrid = new My2DCellArray(_rows,_cols,CellState.UNKNOWN);
			for(int r=0; r<_rows; r++){
				for(int c=0;c<_cols; c++){
					startgrid.set_data_from_cell(_model.get_cell(r,c));
				}
			}
		}
		else startgrid=null;

		for (int i =0; i<_rows; i++) row_clues[i]=_rowbox.get_label_text(i);
		for (int i =0; i<_cols; i++) col_clues[i]=_colbox.get_label_text(i);

		return solve_clues(row_clues,col_clues, startgrid, use_advanced, use_ultimate);
	}

	private void set_solution_from_solver()
	{
		if (_have_solution)
		{
		_model.use_solution();
		set_model_from_solver();
		}
	}

	private void set_working_from_solver()
	{
		_model.use_working();
		set_model_from_solver();
	}

	private void set_model_from_solver()
	{
		for (int r=0; r<_rows; r++) {
			for(int c=0; c<=_cols; c++) {
				_model.set_data_from_cell(_solver.get_cell(r,c));
			}
		}
	}

	public void set_difficulty(double d)
	{
		_grade=(int)d;
	}

	public void random_game()
	{
		stdout.printf("Random game\n");
		Utils.process_events();
		_gnonogram_view.set_name(_("Thinking ..."));
		_gnonogram_view.set_score("");
		_gnonogram_view.set_source(Environment.get_host_name());
		Utils.process_events();
		blank_labels();
		Utils.process_events();
		_model.use_solution();
		change_state(GameState.SOLVING);
		Utils.process_events();
		_gnonogram_view.show_all();
		Utils.process_events();

		_have_solution=true;
		int passes=0, count=0;
		int grade = _grade; //grade may be reduced but _grade always matches spin setting

		if (_difficult) { //generate difficult games
			while (count<1000) {
				count++;
				passes=generate_difficult_game(grade);
				if(passes>0)
				{	//failed to generate difficult puzzle
					if(grade<12)grade++;
					continue;
				}
				//try to solve with advanced solver
				passes=solve_game(false,true,false);

				if(passes>Resource.MINADVANCEDGRADE && passes<Resource.MAXADVANCEDGRADE)break;
//				if(passes<Resource.MINADVANCEDGRADE) continue;
				if(passes>Resource.MAXADVANCEDGRADE & grade>5)
				{
					grade--;
				}
			}
		}
		else{ //generate simple games
			while (count<10) {
				count++;
				passes=generate_simple_game(grade); //tries max tries times
				//if (passes>_grade||passes<0) break;
				if(passes>grade||passes<0) break;
				if (passes==0 && grade>1)grade--;
				//no simple game generated with this setting -
				//reduce complexity setting (relationship between complexity setting
				//and ease of solution not simple - depends also on grid size)
			}
		}

		if (passes>=0) {
			string name= (passes>15) ? _("Difficult random") : _("Simple random");
			_gnonogram_view.set_name(name);
//			_gnonogram_view.set_source(_("Computer"));
			_gnonogram_view.set_date(Utils.get_todays_date_string());
			_gnonogram_view.set_score(passes.to_string());

			_model.use_working();
			redraw_all();
		}
		else {
			Utils.show_warning_dialog(_("Error occurred in solver"));
			stdout.printf(_solver.get_error()+"\n");
			_gnonogram_view.set_name(_("Error in solver"));
			_gnonogram_view.set_source("");
			_gnonogram_view.set_date("");
			_model.use_solution();

			change_state(GameState.SETTING);
			redraw_all();
		}
	}

	private int generate_simple_game(int grade)
	{
		/* returns 0 - failed to generate solvable game
		 * returns value>1 - generated game took value passes to solve
		 * returns -1 - an error occurred in the solver
		*/
		int tries=0, passes=0;
		while (passes==0 && tries<=Resource.MAXTRIES)
		{
			tries++;
			passes=generate_game(grade);
		}
		return passes;
	}

	private int generate_difficult_game(int grade)
	{
		int tries=0, passes=1;
		//takes longer to generate a difficult game so try fewer times.
		while (passes>0 && tries<=Resource.MAXTRIES/10)
		{//generate a puzzle not soluble with simple solver
			tries++;
			passes=generate_game(grade);
		}
		return passes;
	}

	private int generate_game(int grade)
	{
		//stdout.printf("Generate game GRADE %d\n", grade);
		_model.fill_random(grade); //fills solution grid
		update_labels_from_model();
		return solve_game(false,false,false); // no start grid, no advanced
	}

	private void edit_game()
	{
		//stdout.printf("Edit game\n");
		change_state(GameState.SETTING);

		var game_editor=new Game_Editor(_rows,_cols);
		game_editor.set_name(_gnonogram_view.get_name());
		game_editor.set_source(_gnonogram_view.get_author());
		game_editor.set_date(_gnonogram_view.get_date());
		game_editor.set_license(_gnonogram_view.get_license());

		for (int i =0; i<_rows; i++) game_editor.set_rowclue(i,_rowbox.get_label_text(i));
		for (int i =0; i<_cols; i++) game_editor.set_colclue(i,_colbox.get_label_text(i));

		game_editor.show_all();
		var response=game_editor.run();

		if (response==Gtk.ResponseType.OK) {
			_gnonogram_view.set_name(game_editor.get_name());
			_gnonogram_view.set_source(game_editor.get_source());
			_gnonogram_view.set_date(game_editor.get_date());
			_gnonogram_view.set_license(game_editor.get_license());

			int[] b;
			//Format & validate clues by passing through block array.
			for (int i =0; i<_rows; i++) {
				b=Utils.block_array_from_clue(game_editor.get_rowclue(i));
				_rowbox.update_label(i,Utils.clue_from_block_array(b));
			}
			for (int i =0; i<_cols; i++){
				b=Utils.block_array_from_clue(game_editor.get_colclue(i));
				_colbox.update_label(i,Utils.clue_from_block_array(b));
			}
			validate_game();
		}
		game_editor.destroy();
		redraw_all();
	}

	private void validate_game()
	{
		_have_solution=false;
		int passes=solve_game(false,true,false);
		if (passes==-1) {
			invalid_clues();
		}
		else if (passes>0) 	{
			_have_solution=true;
			set_solution_from_solver();
			_gnonogram_view.set_score(passes.to_string());
		}
	}

	private void invalid_clues()
	{
		_model.blank_solution();
		_have_solution=false;
		_gnonogram_view.set_score("invalid");
	}

	private void trim_game()
	{	//remove blank edge rows and columns.
		 //Note: Only clues are trimmed and the puzzle re-generated from the clues
		 //Should only be used on soluble game.
		string[] row_clues;
		string[] col_clues;
		int blank_left_edge=0;
		int blank_top_edge=0;
		int blank_right_edge=0;
		int blank_bottom_edge=0;

		row_clues=new string[_rows];
		col_clues=new string[_cols];

		for (int r=0;r<_rows;r++)
		{
			row_clues[r]=_rowbox.get_label_text(r);
		}
		for (int r=0;r<_rows;r++)
		{
			if (row_clues[r]=="0") blank_top_edge++;
			else break;
		}
		for (int r=_rows-1;r>=0;r--)
		{
			if (row_clues[r]=="0") blank_bottom_edge++;
			else break;
		}

		for (int c=0;c<_cols;c++)
		{
			col_clues[c]=_colbox.get_label_text(c);
		}
		for (int c=0;c<_cols;c++)
		{
			if (col_clues[c]=="0") blank_left_edge++;
			else break;
		}
		for (int c=_cols-1;c>=0;c--)
		{
			if (col_clues[c]=="0") blank_right_edge++;
			else break;
		}

		if (blank_left_edge+blank_right_edge+blank_top_edge+blank_bottom_edge>0)
		{
			if (blank_top_edge+blank_bottom_edge>=_rows||blank_left_edge+blank_right_edge>=_cols) return; //mustnt remove everything!
			if(Utils.show_confirm_dialog(_("Trim blank edges?\nWARNING - only use on a computer soluble puzzle")))
			{
				_model.clear();
				resize(_rows-blank_top_edge-blank_bottom_edge,_cols-blank_left_edge-blank_right_edge);
				//_rows and _cols now new values
				for(int r=0;r<_rows;r++)
				{
					_rowbox.update_label(r,row_clues[r+blank_top_edge]);
				}
				for(int c=0;c<_cols;c++)
				{
					_colbox.update_label(c,col_clues[c+blank_left_edge]);
				}
				validate_game();
				initialize_view();
			}
		}
	}

	private void update_labels_from_model()
	{	//stdout.printf("update labels from model\n");
		for (int r=0; r<_rows; r++)	{
			_rowbox.update_label(r,_model.get_label_text(r,false));
		}
		for (int c=0; c<_cols; c++)	{
			_colbox.update_label(c,_model.get_label_text(c,true));
		}
	}

	private void blank_labels()
	{	//stdout.printf("blank labels");
		for (int r=0; r<_rows; r++)	{
			_rowbox.update_label(r,"---");
		}
		for (int c=0; c<_cols; c++)	{
			_colbox.update_label(c,"---");
		}
	}

	public void quit_game()
	{
		//stdout.printf("In quit game\n");
		save_config();
		if (_solution_changed)
		{
			if (Utils.show_confirm_dialog(_("Save changed puzzle?"))) save_game();
		}
		Gtk.main_quit();
	}

	private void save_config()
	{
		//stdout.printf("Start save config\n");
		var config_instance=Config.get_instance();
		config_instance.set_difficulty(_grade);
		config_instance.set_dimensions(_rows, _cols);
		config_instance.set_colors();
		config_instance.set_save_game_dir(Resource.save_game_dir);
		config_instance.set_load_game_dir(Resource.load_game_dir);
		config_instance.set_font(Resource.font_desc);
		config_instance.set_use_advanced_solver(_advanced);
		config_instance.set_generate_advanced_puzzles(_difficult);
		config_instance.set_incur_time_penalty(_penalty);
		config_instance.set_toolbar_visible(_gnonogram_view.get_toolbar_visible());
		config_instance.set_show_grid(_gridlinesvisible);
		config_instance.set_patterntype(_patterntype);
	}

	private void load_config()
	{
		//stdout.printf("Start save config\n");
		Config config_instance=Config.get_instance();
		Resource.load_config(config_instance);
		config_instance.get_dimensions(out _rows, out _cols); //defaults to 10x10
		_grade=(int)config_instance.get_difficulty(); //defaults to 5
		_difficult=config_instance.get_generate_advanced_puzzles(); //defaults to false
		_advanced=config_instance.get_use_advanced_solver();//defaults to false
		_penalty=config_instance.get_incur_time_penalty();//defaults to true
		_difficult=config_instance.get_generate_advanced_puzzles();
		_gridlinesvisible=config_instance.get_show_grid();
		_toolbarvisible=config_instance.get_toolbar_visible();
		_patterntype=config_instance.get_patterntype();
		//_patterntype=CellPatternType.NONE; //TODO add to config file
	}

	private void change_state(GameState gs)
	{
		//stdout.printf("Change state\n");
		//ensure view is all in correct state (e.g. undo redo buttons)
		_gnonogram_view.state_has_changed(gs);
		_history.initialise_pointers();
		unset_guess_cell();
		initialize_cursor();
		_state=gs;
		if (gs==GameState.SETTING){
			_timer.stop();
			 _model.use_solution();
		}
		else{
			_timer.start();
			_model.use_working();
		}
	}
}
