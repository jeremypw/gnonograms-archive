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
using GLib;
using Signal;

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
	private Circular_move_buffer _history;
	private Timer _timer;
	private GameState _state;

	private bool _is_button_down;
	private bool _have_solution;
	private bool _gridlinesvisible;
	private bool _toolbarvisible;
	private bool _debug=false;
	private bool _advanced;
	private bool _difficult;
	private bool _solution_changed;

	private int _grade;
	private int _rows;
	private int _cols;

//======================================================================
	public Gnonogram_controller(string game_filename)
	{

		_history=new Circular_move_buffer(Resource.MAXUNDO);
		_timer=new Timer();
		_model=new Gnonogram_model();
		_solver=new Gnonogram_solver();

		load_config();
		create_view();
		_gnonogram_view.show_all();
		initialize_view();
		initialize_menus();

		_model.set_dimensions(_rows,_cols);
		_solver.showsolvergrid.connect(show_solver_grid);
		_solver.showprogress.connect((guesses)=>{_gnonogram_view.set_score_label(guesses.to_string());
		_gnonogram_view.show_all();});
		_solver.set_dimensions(_rows,_cols);

//		_state=GameState.SOLVING;//to make sure everything gets set to setting state.
		change_state(GameState.SETTING);

		if(game_filename.length>4){
			load_game(game_filename);
		}
	}
//======================================================================
	private void create_view()
	{
		_rowbox = new Gnonogram_LabelBox(_rows, _cols, false);
		_colbox = new Gnonogram_LabelBox(_cols, _rows, true);
		set_default_fontheight(_rows, _cols);
		_rowbox.set_all_to_zero();
		_colbox.set_all_to_zero();

		_cellgrid = new Gnonogram_CellGrid(_rows,_cols);
		_gnonogram_view = new Gnonogram_view(_rowbox, _colbox, _cellgrid, this);

		try{
			_gnonogram_view.set_icon_from_file(Resource.icon_dir+"/gnonograms.svg");
		}
		catch (GLib.Error e) {stdout.printf("Icon file not loaded\n");}


		_gnonogram_view.savegame.connect(this.save_game);
		_gnonogram_view.savepictogame.connect(this.save_pictogame);
		_gnonogram_view.loadgame.connect(this.load_game);
		_gnonogram_view.quitgamesignal.connect(()=>{quit_game();});
		_gnonogram_view.newgame.connect(this.new_game);

		_gnonogram_view.undoredo.connect(this.undoredo);
		_gnonogram_view.hidegame.connect(this.start_solving);
		_gnonogram_view.revealgame.connect(this.reveal_solution);
		_gnonogram_view.checkerrors.connect(this.peek_game);
		_gnonogram_view.pausegame.connect(this.pause_game);
		_gnonogram_view.restartgame.connect(this.restart_game);
		_gnonogram_view.randomgame.connect(this.random_game);
		_gnonogram_view.solvegame.connect(this.viewer_solve_game);
		_gnonogram_view.editgame.connect(this.edit_game);

		_gnonogram_view.setcolors.connect(()=>{Resource.set_colors(); redraw_all();});
		_gnonogram_view.setfont.connect(()=>{Resource.set_custom_font(); _rowbox.change_font_height(false);_colbox.change_font_height(false);});
		_gnonogram_view.resizegame.connect(this.change_size);
		_gnonogram_view.key_press_event.connect(this.key_pressed);
		_gnonogram_view.key_release_event.connect(this.key_released);
		_gnonogram_view.setdifficulty.connect(this.set_difficulty);
		_gnonogram_view.togglegrid.connect(this.gridlines_toggled);
		_gnonogram_view.toggletoolbar.connect(this.toolbar_toggled);
		_gnonogram_view.changefont.connect(this.change_font_size);
//		_gnonogram_view.debugmode.connect((debug)=>{_debug=debug;});
		_gnonogram_view.advancedmode.connect((advanced)=>{_advanced=advanced;});
		_gnonogram_view.difficultmode.connect((difficult)=>{_difficult=difficult;});
		_gnonogram_view.resetall.connect(this.reset_all_to_default);
		_gnonogram_view.set_grade_spin_value((double)_grade);

		_cellgrid.cursor_moved.connect(this.grid_cursor_moved);
		_cellgrid.button_press_event.connect(this.button_pressed);
		_cellgrid.button_release_event.connect(()=>{this._is_button_down=false; return true;});
		_cellgrid.expose_event.connect(()=>{redraw_all();return true;});
	}
//======================================================================
	private void initialize_view()
	{ //stdout.printf("Initialise view\n");
		initialize_cursor();
		if (_have_solution) update_labels_from_model(); //causes problem if solution not complete
		_gnonogram_view.set_size_label(_rows,_cols);
		initialize_history();
		_solution_changed=false;
	}

	private void initialize_menus()
	{
		_gnonogram_view.set_advancedmenuitem_active(_advanced);
		_gnonogram_view.set_difficultmenuitem_active(_difficult);
		_gnonogram_view.set_gridmenuitem_active(_gridlinesvisible);
		_gnonogram_view.set_toolbarmenuitem_active(_toolbarvisible);
	}

	private void initialize_cursor()
	{//stdout.printf("Initialise cursor\n");
		_current_cell.row=-1;
		_current_cell.col=-1;
		_current_cell.state=CellState.UNKNOWN;
		_previous_cell.row=-1;
		_previous_cell.col=-1;
		_previous_cell.state=CellState.UNKNOWN;
		_is_button_down=false;
	}

	private void initialize_history()
	{
		_history.initialise_pointers();
	}
//======================================================================
	private void reset_all_to_default()
	{
		Resource.reset_all();
		resize(Resource.DEFAULT_ROWS,Resource.DEFAULT_COLS);
		_gnonogram_view.set_grade_spin_value((double)Resource.DEFAULT_DIFFICULTY);
//		_gnonogram_view.set_toolbarmenuitem_active(true);
//		_gnonogram_view.set_gridmenuitem_active(true);
		_difficult=false;
		_advanced=true;
		_gridlinesvisible=true;
		_toolbarvisible=true;
		initialize_view();
		initialize_menus();

	}
//======================================================================
	private void change_size()
	{
		int r,c;
		if (Utils.get_dimensions(out r,out c,_rows,_cols)){
//			new_game();
			resize(r,c);
//			change_state(GameState.SETTING);
//			initialize_view();
//			_gnonogram_view.show_all();
			new_game();
		}
	}
//======================================================================
	private void resize(int r, int c){
		//stdout.printf("Resize\n");
		if (r>Resource.MAXSIZE||c>Resource.MAXSIZE) return;
		if (r==_rows && c==_cols) return;
		resize_view(r,c);
		set_default_fontheight(r,c);
		_solver.set_dimensions(r,c);
		_model.set_dimensions(r,c);
		_rows=r; _cols=c;
	}

	private void resize_view(int r, int c){
		_rowbox.resize(r, c);
		_colbox.resize(c, r);
		_cellgrid.resize(r,c);
	}

	private void set_default_fontheight(int r, int c)
	{
		double maxrowfontheight, maxcolfontheight, deffontheight;

		maxrowfontheight=(double)((285-c)/r);
		maxcolfontheight=(double)((550-r)/c);
		deffontheight=double.min(maxrowfontheight,maxcolfontheight);
		_rowbox.set_font_height(deffontheight);
		_colbox.set_font_height(deffontheight);

	}
//======================================================================
	private void gridlines_toggled(bool active){
		//stdout.printf("Gridlines toggled\n");
		if (_gridlinesvisible!=active){
			_gridlinesvisible=active;
			redraw_all();
		}
	}
//======================================================================
	private void toolbar_toggled(bool active){
		//stdout.printf("Toolbar visible toggled active %s \n", active.to_string());
		_toolbarvisible=active;
		_gnonogram_view.set_toolbar_visible(_toolbarvisible);
	}
//======================================================================
	private bool button_pressed(Gdk.EventButton e){
		//stdout.printf("Button pressed\n");
		ButtonPress b=ButtonPress.UNDEFINED;
		if (e.type!=EventType.@2BUTTON_PRESS){
			switch (e.button){
				case 1: b = ButtonPress.LEFT_SINGLE; break;
				case 3: b = ButtonPress.RIGHT_SINGLE; break;
				default: break;
			}
		}
		else b=ButtonPress.LEFT_DOUBLE;

		if (b!=ButtonPress.UNDEFINED){
			switch (b){
				case ButtonPress.LEFT_SINGLE:
					_current_cell.state=CellState.FILLED;
					break;
				case ButtonPress.RIGHT_SINGLE:
					_current_cell.state=CellState.EMPTY;
					break;
				default:
					if (_state==GameState.SOLVING){
						_current_cell.state=CellState.UNKNOWN;
					}
					break;
			}
			_is_button_down=true;
			make_move(_current_cell);//update_cell(_current_cell,true);
		}
		return true;
	}
//======================================================================
	private bool key_pressed(Gdk.EventKey e){
		//stdout.printf("Key pressed\n");
		string name=(Gdk.keyval_name(e.keyval)).up();
		int currentrow=_current_cell.row;
		int currentcol=_current_cell.col;
		if (currentrow<0||currentcol<0||currentrow>_rows-1||currentcol>_cols-1) return false;

		switch (name){
			case "UP":
					if (currentrow>0){
						currentrow-=1;
						grid_cursor_moved(currentrow,currentcol);
					}
					break;
			case "DOWN":
					if (currentrow<_rows-1){
						currentrow+=1;
						grid_cursor_moved(currentrow,currentcol);
					}
					break;
			case	"LEFT":
					if (currentcol>0){
						currentcol-=1;
						grid_cursor_moved(currentrow,currentcol);
					}
					break;
			case "RIGHT":
					if (currentcol<_cols-1){
						currentcol+=1;
						grid_cursor_moved(currentrow,currentcol);
					}
					break;
			case "F": //TODO make configurable
			case "f":
					_current_cell.state=CellState.FILLED;
					make_move(_current_cell);
					_is_button_down=true;
					break;
			case "E":  //TODO make configurable
			case "e":
					_current_cell.state=CellState.EMPTY;
					make_move(_current_cell);
					_is_button_down=true;
					break;
			case "X":  //TODO make configurable
			case "x":
					if (_state==GameState.SOLVING){
						_current_cell.state=CellState.UNKNOWN;
					}
					else {
						_current_cell.state=CellState.EMPTY;
					}
					make_move(_current_cell);
					_is_button_down=true;
					break;
			default:
					break;
		}

		return false;
	}
//======================================================================
	private bool key_released(Gdk.EventKey e){
		string name=(Gdk.keyval_name(e.keyval)).up();
		if (name=="UP"||name=="DOWN"||name=="LEFT"||name=="RIGHT") {}
		else _is_button_down=false;
		return true;
	}
//======================================================================
	private void change_font_size(bool increase){
		_rowbox.change_font_height(increase);
		_colbox.change_font_height(increase);
		// if making smaller, force to minimum window size for given font
		if (!increase) _gnonogram_view.resize(100,150);
	}
//======================================================================
	public void grid_cursor_moved(int r, int c){
		if (r<0||r>=_rows||c<0||c>=_cols){
			highlight_labels(_previous_cell, false);
			_cellgrid.draw_cell(_previous_cell,_state, false);
			_current_cell.row=-1;
			return;
		}

		_previous_cell.copy(_current_cell);
		if (!_current_cell.changed(r,c)) return;

		highlight_labels(_previous_cell, false);
		_cellgrid.draw_cell(_previous_cell,_state, false);

		if (_is_button_down) make_move(_current_cell);
		else {
			_current_cell=_model.get_cell(r,c);
			_cellgrid.draw_cell(_current_cell, _state, true);
		}

		highlight_labels(_current_cell, true);
	}
//======================================================================
	private void highlight_labels(Cell c, bool is_highlight){
		_rowbox.highlight(c.row, is_highlight);
		_colbox.highlight(c.col, is_highlight);
	}
//======================================================================
	private void undoredo(bool undo){
	//direction true = undo; false=redo
	//stdout.printf("Undoredo\n");
		if (undo) undo_move();
		else redo_move();
	}
//======================================================================
	private void make_move(Cell c){
		//stdout.printf("make_move\n");
		Move mv={_model.get_cell(c.row,c.col),c};
		_history.new_data(mv);
		update_cell(c,true);
		_gnonogram_view.set_redo_sensitive(false);
		_gnonogram_view.set_undo_sensitive(true);
	}
//======================================================================
	private void undo_move(){
		//stdout.printf("undo_move\n");

		Move? mv=_history.previous_data();
		if (mv==null){
			_gnonogram_view.set_undo_sensitive(false);
			return;
		}

		update_cell(mv.previous,false);
		_gnonogram_view.set_redo_sensitive(true);

		if (_previous_cell.same_coords(mv.previous)) _previous_cell.copy(mv.previous);
		if (_current_cell.same_coords(mv.previous)) _current_cell.copy(mv.previous);

		if (_history.no_more_previous_data())
		{
			_gnonogram_view.set_undo_sensitive(false);
			if (_state==GameState.SETTING) _solution_changed=false;
		}
	}
//======================================================================
	private void redo_move(){
		//stdout.printf("redo_move\n");
		Move? mv=_history.next_data();
		if (mv==null){
			_gnonogram_view.set_redo_sensitive(false);
			return;
		}

		if (_previous_cell.same_coords(mv.replacement)) _previous_cell.copy(mv.replacement);
		if (_current_cell.same_coords(mv.replacement)) _current_cell.copy(mv.replacement);

		update_cell(mv.replacement,true);
		_gnonogram_view.set_undo_sensitive(true);

		if (_history.no_more_next_data()) _gnonogram_view.set_redo_sensitive(false);
	}
//======================================================================
	public void update_cell(Cell c, bool highlight=true){
		//stdout.printf("update_cell\n");
		_model.set_data_from_cell(c);
		_cellgrid.draw_cell(c,_state, highlight);

		if (_state==GameState.SETTING)
		{
			_rowbox.update_label(c.row, _model.get_label_text(c.row,false));
			_colbox.update_label(c.col, _model.get_label_text(c.col,true));
			_solution_changed=true;
		}
		else	check_solved();
	}
//======================================================================
	private void check_solved(){
		if (_model.count_unsolved()==0){
		//puzzle has been completed (possible wrongly)
			_timer.stop(); //timer started when switched to SOLVING state
			peek_game(); //checks whether solution is correct
			_is_button_down=false;
		}
	}
//======================================================================
	private void redraw_all(){
		//stdout.printf("Redraw all\n");
		_cellgrid.prepare_to_redraw_cells(_gridlinesvisible);
		for (int r=0; r<_rows; r++){
			for (int c=0; c<_cols; c++){
					_cellgrid.draw_cell(_model.get_cell(r,c), _state);
			}
		}
	}
//======================================================================
	public void new_game(){
		//stdout.printf("New game\n");
		_model.clear();
		_have_solution=true;
		update_labels_from_model();
		_gnonogram_view.set_name(_("New puzzle"));
		_gnonogram_view.set_author(" ");
		_gnonogram_view.set_date(" ");
		_gnonogram_view.set_score_label("  ");
		initialize_view();
		change_state(GameState.SETTING);
//		redraw_all();
//		reveal_solution();
	}
//======================================================================
	public void restart_game(){
	//stdout.printf("Restart game\n");
		if (_state!=GameState.SOLVING) return;
		_model.blank_working();
		initialize_view();
		redraw_all();
		_timer.start();
	}
//======================================================================
	public void pause_game(){
	//stdout.printf("Pause game\n");
		if (_state!=GameState.SOLVING) return;
		_timer.stop();
		Utils.show_info_dialog(_("Timer paused"));
		_timer.continue();
		_is_button_down=false;
	}
//======================================================================
	public void save_game(){
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
//======================================================================
	public void save_pictogame(){
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
//======================================================================
	private void write_game_file(FileStream f){
		//stdout.printf("In write game file\n");
		f.printf("[Description]\n");
		f.printf("%s\n",_gnonogram_view.get_name());
		f.printf("%s\n",_gnonogram_view.get_author());
		f.printf("%s\n",_gnonogram_view.get_date());
		f.printf("%s\n",_gnonogram_view.get_score());

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
//======================================================================
	private void write_pictogame_file(FileStream f)
	{//stdout.printf("In write pictogame file\n");
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
//=========================================================================
	private void write_position_file(FileStream f){
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
//=========================================================================
	public void load_game(string fname=""){
		//stdout.printf("load_game fname %s\n",fname);
		var reader = new Gnonogram_filereader(fname);
		if (reader.filename=="") return;
		new_game(); //changes to setting state
		//User feedback - expect save and load to work on current state of game
		if (load_common(reader) && load_position_extra(reader))
		{
			if (reader.has_state && reader.state==(GameState.SETTING).to_string()){
					//(already in SETTING state) change_state(GameState.SETTING);
					redraw_all();
			}
			else{
				change_state(GameState.SOLVING);
			}
		}
		else Utils.show_warning_dialog(_("Failed to load puzzle"));
	}

//=========================================================================
	private bool load_position_extra(Gnonogram_filereader reader){
		if (reader.has_working){
			_model.use_working();
			for (int i=0; i<_rows; i++){
				_model.set_row_data_from_string(i,reader.working[i]);
			}
		}
		return true;
	}
//=========================================================================
	private bool load_common(Gnonogram_filereader reader){
		_have_solution=false;

		if (!reader.open_datainputstream())	{
			Utils.show_warning_dialog(_("Could not open puzzle file"));
			return false;
		}

		if (!reader.parse_game_file()){
			Utils.show_warning_dialog(_("File format incorrect: \n")+reader.err_msg);
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

		_gnonogram_view.set_author(reader.author);
		_gnonogram_view.set_date(reader.date);
		_gnonogram_view.set_score_label(reader.score);

		return true;
	}
//======================================================================
	public void start_solving(){
		//stdout.printf("Start solving\n");
//		_timer.start();
//		if(_state==GameState.SOLVING) redraw_all();
		change_state(GameState.SOLVING);
	}
//======================================================================
	public void reveal_solution() {
		//stdout.printf("Reveal solution\n");
//		_timer.stop();
//		if(_state==GameState.SETTING) redraw_all();
		change_state(GameState.SETTING);
	}
//======================================================================
	public void peek_game() {
		//stdout.printf("Peek game\n");
		double seconds=_timer.elapsed();
		int hours= ((int)seconds)/3600;
		seconds-=((double)hours)*3600.000;
		int minutes=((int)seconds)/60;
		seconds-=(double)(minutes)*60.000;
		string time_taken=("\n\n"+_("Time taken is %d hours, %d minutes, %8.3f seconds")).printf(hours, minutes, seconds);

		if (_have_solution){
			int count=_model.count_errors();
			if (count==0){
				Utils.show_info_dialog(_("No errors")+time_taken);
			}
			else{
				redraw_all();
				Utils.show_info_dialog((_("There are %d incorrect cells"+time_taken)).printf(count));
				_model.clear_errors();
			}
			redraw_all();
		}
		else{
			Utils.show_info_dialog(_("No solution available"+time_taken));
		}
	}
//======================================================================
	private void viewer_solve_game() {
		//stdout.printf("Viewer_solve_game\n");
		change_state(GameState.SOLVING);
		restart_game(); //clears any erroneous entries and also re-starts timer
		int passes = solve_game(true, _advanced,_advanced);
		_timer.stop();
		double time_taken=_timer.elapsed();
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
			default:
				_gnonogram_view.set_score_label(passes.to_string());
				Utils.show_info_dialog((_("Solved in %8.3f seconds").printf(time_taken)));

				if (!_have_solution){
					_have_solution=true;
					set_solution_from_solver();
				}
				break;
		}
//		if (_state==GameState.SOLVING) redraw_all();
//		else change_state(GameState.SOLVING);
		redraw_all();
	}

//======================================================================
	private void show_solver_grid() {
		set_working_from_solver();
//		redraw_all();
	}
//======================================================================
	private int solve_clues(string[] row_clues, string[] col_clues, My2DCellArray? startgrid, bool use_advanced, bool use_ultimate) {
		int passes=0;
		_solver.initialize(row_clues, col_clues, startgrid);
		passes=_solver.solve_it(_debug, use_advanced, use_ultimate);
		return passes;
	}
//======================================================================
	private int solve_game(bool use_startgrid, bool use_advanced, bool use_ultimate) {
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
//======================================================================
	private void set_solution_from_solver() {
		if (_have_solution)
		{
		_model.use_solution();
		set_model_from_solver();
		}
	}
//======================================================================
	private void set_working_from_solver() {
		_model.use_working();
		set_model_from_solver();
	}
//======================================================================
	private void set_model_from_solver(){
		for (int r=0; r<_rows; r++) {
			for(int c=0; c<=_cols; c++) {
				_model.set_data_from_cell(_solver.get_cell(r,c));
			}
		}
	}
//======================================================================
	public void set_difficulty(double d){_grade=(int)d;}
//======================================================================
	public void random_game() {
		//stdout.printf("Random game\n");
		_model.use_solution();
		_have_solution=true;
		int passes=0, count=0;
		int grade = _grade; //grade may be reduced but _grade always matches spin setting

		if (_difficult) { //generate difficult games
			while (count<100) {
				count++;
				passes=generate_difficult_game(grade);
				if(passes>0) {
					if(grade<10)grade++;
					continue;
				}
				passes=solve_game(false,true,false);
				if(passes<3*_grade) continue;
				if(passes>1000 & grade>1)grade--;
				if(passes<1000)break;
			}
		}
		else{ //generate simple games
			while (count<10) {
				count++;
				passes=generate_simple_game(grade); //tries max tries times
				if (passes>_grade||passes<0) break;
				if (passes==0 && grade>1)grade--;
				//no simple game generated with this setting -
				//reduce complexity setting (relationship between complexity setting
				//and ease of solution not simple - depends also on grid size)
			}
		}

		if (passes>=0) {
			string name= (passes>15) ? _("Difficult random") : _("Simple random");
			_gnonogram_view.set_name(name);
			_gnonogram_view.set_author(_("Computer"));
			_gnonogram_view.set_date(Utils.get_todays_date_string());
			_gnonogram_view.set_score_label(passes.to_string());
			_model.use_working();
			//start_solving();
			change_state(GameState.SOLVING);
		}
		else {
			Utils.show_warning_dialog(_("Error occurred in solver"));
			stdout.printf(_solver.get_error()+"\n");
			_gnonogram_view.set_name(_("Error in solver"));
			_gnonogram_view.set_author("");
			_gnonogram_view.set_date("");
			_model.use_solution();
			//reveal_solution();
			change_state(GameState.SETTING);
		}
	}
//======================================================================
	private int generate_simple_game(int grade) {
/* returns 0 - failed to generate solvable game
 * returns value>1 - generated game took value passes to solve
 * returns -1 - an error occurred in the solver
 */
		int tries=0, passes=0;
		while (passes==0 && tries<=Resource.MAXTRIES) {
			tries++;
			passes=generate_game(grade);
		}
		return passes;
	}
//======================================================================
	private int generate_difficult_game(int grade) {
		int tries=0, passes=1;
		//takes longer to generate a difficult game so try fewer times.
		while (passes>0 && tries<=Resource.MAXTRIES/10) {
			tries++;
			passes=generate_game(grade);
		}
		return passes;
	}
//======================================================================
	private int generate_game(int grade) {
		//stdout.printf("Generate game GRADE %d\n", grade);
		_model.fill_random(grade); //fills solution grid
		update_labels_from_model();
		return solve_game(false,false,false); // no start grid, no advanced
	}
//======================================================================
	private void edit_game() {
		//stdout.printf("Edit game\n");
		change_state(GameState.SETTING);

		var game_editor=new Game_Editor(_rows,_cols);
		game_editor.set_name(_gnonogram_view.get_name());
		game_editor.set_author(_gnonogram_view.get_author());
		game_editor.set_date(_gnonogram_view.get_date());

		for (int i =0; i<_rows; i++) game_editor.set_rowclue(i,_rowbox.get_label_text(i));
		for (int i =0; i<_cols; i++) game_editor.set_colclue(i,_colbox.get_label_text(i));

		game_editor.show_all();
		var response=game_editor.run();

		if (response==Gtk.ResponseType.OK) {
			_gnonogram_view.set_name(game_editor.get_name());
			_gnonogram_view.set_author(game_editor.get_author());
			_gnonogram_view.set_date(game_editor.get_date());

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

			_have_solution=false;
			int passes=solve_game(false,false,false);
			if (passes==-1) {
				invalid_clues();
			}
			else if (passes>0) 	{
				_have_solution=true;
				set_solution_from_solver();
				_gnonogram_view.set_score_label(passes.to_string());
			}
		}
		game_editor.destroy();
		redraw_all();
	}
//======================================================================
	private void update_labels_from_model() {
		for (int r=0; r<_rows; r++)	{
			_rowbox.update_label(r,_model.get_label_text(r,false));
		}
		for (int c=0; c<_cols; c++)	{
			_colbox.update_label(c,_model.get_label_text(c,true));
		}
		_rowbox.show_all(); _colbox.show_all();
	}
//======================================================================
	public void quit_game() {
		//stdout.printf("In quit game\n");
		save_config();
		if (_solution_changed)
		{
			if (Utils.show_confirm_dialog("Save changed puzzle?")) save_game();
		}
		Gtk.main_quit();
	}
//======================================================================
	private void save_config() {
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
		config_instance.set_toolbar_visible(_gnonogram_view.get_toolbar_visible());
		config_instance.set_show_grid(_gridlinesvisible);
	}
//======================================================================
	private void load_config() {
		//stdout.printf("Start save config\n");
		Config config_instance=Config.get_instance();
		Resource.load_config(config_instance);
		config_instance.get_dimensions(out _rows, out _cols); //defaults to 10x10
		_grade=(int)config_instance.get_difficulty(); //defaults to 5
		_difficult=config_instance.get_use_advanced_solver(); //defaults to true
		_advanced=config_instance.get_use_advanced_solver();
		_difficult=config_instance.get_generate_advanced_puzzles();
		_gridlinesvisible=config_instance.get_show_grid();
		_toolbarvisible=config_instance.get_toolbar_visible();
	}
//======================================================================
	private void change_state(GameState gs) {
		//stdout.printf("Change state\n");
		//ensure view is all in correct state (e.g. undo redo buttons)
		//this method inhibits signals
		_gnonogram_view.state_has_changed(gs);

		_state=gs;
		initialize_cursor();
		if (gs==GameState.SETTING){
			_timer.stop();
			 _model.use_solution();
		}
		else{
			_timer.start();
			_model.use_working();
		}
		redraw_all();
	}
//======================================================================
	private void invalid_clues(){
		_model.blank_solution();
		_have_solution=false;
		_gnonogram_view.set_score_label("invalid");
	}
}
