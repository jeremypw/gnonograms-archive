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
	private Timer _timer;
	private GameState _state;

	private bool _is_button_down;
	private bool _have_solution=true;
	private bool _gridlinesvisible;
	private bool _debug=false;
	private bool _advanced=true;
	private bool _difficult=false;

	private int _grade;
	private int _rows;
	private int _cols;

//======================================================================
	public Gnonogram_controller(string game_filename)
	{

		_model=new Gnonogram_model();
		_solver=new Gnonogram_solver();
		_timer=new Timer();

		Config.get_instance().get_dimensions(out _rows, out _cols); //defaults to 10x10
		_grade=(int)(Config.get_instance().get_difficulty()); //defaults to 5

		create_view();
		initialize_view();

		_solver.showsolvergrid.connect(show_solver_grid);
		_solver.showprogress.connect((guesses)=>{_gnonogram_view.set_score_label(guesses.to_string());_gnonogram_view.show_all();});

		_model.set_dimensions(_rows,_cols);
		_solver.set_dimensions(_rows,_cols);

		_gnonogram_view.show_all();
		change_state(GameState.SETTING);

		if(game_filename.length>4)
		{
			load_game(game_filename);
		}

	}
//======================================================================

	private void create_view()
	{
		_rowbox = new Gnonogram_LabelBox(_rows, _cols, false);
		_colbox = new Gnonogram_LabelBox(_cols, _rows, true);

		_cellgrid = new Gnonogram_CellGrid(_rows,_cols);
		_gridlinesvisible=false;

		_gnonogram_view = new Gnonogram_view(_rowbox, _colbox, _cellgrid, this);
		_gnonogram_view.title = _("Gnonograms");
		_gnonogram_view.position = WindowPosition.CENTER;
		_gnonogram_view.resizable=false;
		try
		{
			_gnonogram_view.set_icon_from_file(Resource.icon_dir+"/gnonograms.svg");
		}
		catch (GLib.Error e) {stdout.printf("Icon file not loaded\n");}

		_gnonogram_view.solvegame.connect(this.viewer_solve_game);
		_gnonogram_view.savegame.connect(this.save_game);
		_gnonogram_view.savepictogame.connect(this.save_pictogame);
		_gnonogram_view.loadgame.connect(this.load_game);
		_gnonogram_view.saveposition.connect(this.save_position);
		_gnonogram_view.loadposition.connect(()=>{this.load_position(); change_state(_state);});
		_gnonogram_view.quitgamesignal.connect(()=>{quit_game();});
		_gnonogram_view.newgame.connect(this.new_game);
		_gnonogram_view.hidegame.connect(this.start_solving);
		_gnonogram_view.revealgame.connect(this.reveal_solution);
		_gnonogram_view.checkerrors.connect(this.peek_game);
		_gnonogram_view.restartgame.connect(this.restart_game);
		_gnonogram_view.randomgame.connect(this.random_game);
		_gnonogram_view.setcolors.connect(()=>{Resource.set_colors(); redraw_all();});
		_gnonogram_view.setfont.connect(()=>{Resource.set_font(); _rowbox.change_font_height(false);_colbox.change_font_height(false);});
		_gnonogram_view.resizegame.connect(this.change_size);
		_gnonogram_view.key_press_event.connect(this.key_pressed);
		_gnonogram_view.key_release_event.connect(this.key_released);
		_gnonogram_view.setdifficulty.connect(this.set_difficulty);
		_gnonogram_view.togglegrid.connect(this.gridlines_toggled);
		_gnonogram_view.changefont.connect(this.change_font_size);
//		_gnonogram_view.debugmode.connect((debug)=>{_debug=debug;});
		_gnonogram_view.advancedmode.connect((advanced)=>{_advanced=advanced;});
		_gnonogram_view.difficultmode.connect((difficult)=>{_difficult=difficult;});
		_gnonogram_view.set_grade_spin_value((double)_grade);

		_cellgrid.cursor_moved.connect(this.grid_cursor_moved);
		_cellgrid.button_press_event.connect(this.button_pressed);
		_cellgrid.button_release_event.connect(()=>{this._is_button_down=false; return true;});
		_cellgrid.expose_event.connect(()=>{redraw_all();return false;});
	}
//======================================================================
	private void initialize_view()
	{ //stdout.printf("Initialise view\n");
		initialize_cursor();
		if (_have_solution) update_labels_from_model(); //causes problem if solution not complete
		_gnonogram_view.set_size(_rows,_cols);
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
//======================================================================
	private void change_size()
	{
		int r,c;
		if (Utils.get_dimensions(out r,out c,_rows,_cols))
		{
			new_game();
			resize(r,c);
			change_state(GameState.SETTING);
			initialize_view();
			_gnonogram_view.show_all();
		}
	}
//======================================================================
	private void resize(int r, int c)
	{ //stdout.printf("Resize\n");
		if (r>Resource.MAXROWSIZE||c>Resource.MAXCOLSIZE) return;
		if (r==_rows && c==_cols) return;
		resize_view(r,c);
		_solver.set_dimensions(r,c);
		_model.set_dimensions(r,c);
		_rows=r; _cols=c;
	}

	private void resize_view(int r, int c)
	{
		_rowbox.resize(r, c);
		_colbox.resize(c, r);
		_cellgrid.resize(r,c);
	}
//======================================================================
	private void gridlines_toggled(bool active)
	{	//stdout.printf("Gridlines toggled\n");
		if (_gridlinesvisible!=active)
		{
			_gridlinesvisible=active;
			redraw_all();
		}
	}
//======================================================================
	private bool button_pressed(Gdk.EventButton e)
	{//stdout.printf("Button pressed\n");
		ButtonPress b=ButtonPress.UNDEFINED;
		if (e.type!=EventType.@2BUTTON_PRESS)
		{
			switch (e.button)
			{
				case 1: b = ButtonPress.LEFT_SINGLE; break;
				case 3: b = ButtonPress.RIGHT_SINGLE; break;
				default: break;
			}
		}
		else b=ButtonPress.LEFT_DOUBLE;

		if (b!=ButtonPress.UNDEFINED)
		{
			switch (b)
			{
				case ButtonPress.LEFT_SINGLE:
					_current_cell.state=CellState.FILLED;
					break;
				case ButtonPress.RIGHT_SINGLE:
					_current_cell.state=CellState.EMPTY;
					break;
				default:
					if (_state==GameState.SOLVING)
					{
					_current_cell.state=CellState.UNKNOWN;
					}
					break;
			}
			_is_button_down=true;
			update_cell(_current_cell,true);
		}
		return true;
	}
//======================================================================
	private bool key_pressed(Gdk.EventKey e)
	{stdout.printf("Key pressed\n");
		string name=(Gdk.keyval_name(e.keyval)).up();
		int currentrow=_current_cell.row;
		int currentcol=_current_cell.col;
		if (currentrow<0||currentcol<0||currentrow>_rows-1||currentcol>_cols-1) return false;

		switch (name)
		{
			case "UP":
					if (currentrow>0)
					{	currentrow-=1;
						grid_cursor_moved(currentrow,currentcol);
					}
					break;
			case "DOWN":
					if (currentrow<_rows-1)
					{	currentrow+=1;
						grid_cursor_moved(currentrow,currentcol);
					}
					break;
			case	"LEFT":
					if (currentcol>0)
					{	currentcol-=1;
						grid_cursor_moved(currentrow,currentcol);
					}
					break;
			case "RIGHT":
					if (currentcol<_cols-1)
					{	currentcol+=1;
						grid_cursor_moved(currentrow,currentcol);
					}
					break;
			case "F":
			case "f":
					_current_cell.state=CellState.FILLED;
					update_cell(_current_cell,true);
					_is_button_down=true;
					break;
			case "E":
			case "e":
					_current_cell.state=CellState.EMPTY;
					update_cell(_current_cell,true);
					_is_button_down=true;
					break;
			case "X":
			case "x":
					if (_state==GameState.SOLVING)
					{
						_current_cell.state=CellState.UNKNOWN;
					}
					else
					{
						_current_cell.state=CellState.EMPTY;
					}
					update_cell(_current_cell,true);
					_is_button_down=true;
					break;
			case "P":
			case "p":
					_timer.stop();
					Utils.show_info_dialog(_("Timer paused"));
					_timer.continue();
					_is_button_down=false;
					break;
			case "EQUAL":
					change_font_size(true);
					break;
			case "MINUS":
					change_font_size(false);
					break;
			default:
					break;
		}

		return true;
	}
//======================================================================
	private bool key_released(Gdk.EventKey e){
		string name=(Gdk.keyval_name(e.keyval)).up();
		if (name=="UP"||name=="DOWN"||name=="LEFT"||name=="RIGHT") {}
		else _is_button_down=false;
		return true;
	}
//======================================================================
	private void change_font_size(bool increase)
	{
		_rowbox.change_font_height(increase);
		_colbox.change_font_height(increase);
		if (!increase) _gnonogram_view.resize(100,150);//force to minimum window size
	}
//======================================================================
	public void grid_cursor_moved(int r, int c)
	{
		if (r<0||r>=_rows||c<0||c>=_cols)
		{
			highlight_labels(_previous_cell, false);
			_cellgrid.draw_cell(_previous_cell,_state, false);
			return;
		}

		_previous_cell.copy(_current_cell);
		if (!_current_cell.changed(r,c)) return;

		highlight_labels(_previous_cell, false);
		_cellgrid.draw_cell(_previous_cell,_state, false);

		if (_is_button_down) update_cell(_current_cell,true);
		else
		{
			_current_cell=_model.get_cell(r,c);
			_cellgrid.draw_cell(_current_cell, _state, true);
		}

		highlight_labels(_current_cell, true);
		_previous_cell.copy(_current_cell);
	}
//======================================================================
	private void highlight_labels(Cell c, bool is_highlight)
	{
		_rowbox.highlight(c.row, is_highlight);
		_colbox.highlight(c.col, is_highlight);
	}
//======================================================================
	public void update_cell(Cell c, bool highlight=true)
	{//stdout.printf("update_cell\n");
		_model.set_data_from_cell(c);
		_cellgrid.draw_cell(c,_state, highlight);

		if (_state==GameState.SETTING)
		{
			_rowbox.update_label(c.row, _model.get_label_text(c.row,false));
			_colbox.update_label(c.col, _model.get_label_text(c.col,true));
		}
		else	check_solved();
	}

	private void check_solved()
	{
		if (_model.count_unsolved()==0) //puzzle has been completed (possible wrongly)
		{
			_timer.stop(); //timer started when switched to SOLVING state
			peek_game(); //checks whether solution is correct
			_is_button_down=false;
		}
	}
//======================================================================
	private void redraw_all()
	{ //stdout.printf("Redraw all\n");
		_cellgrid.prepare_to_redraw_cells(_gridlinesvisible);
		for (int r=0; r<_rows; r++)
			{for (int c=0; c<_cols; c++)
				{
					_cellgrid.draw_cell(_model.get_cell(r,c), _state);
				}
			}
	}
//======================================================================
	public void new_game()
	{
		_model.clear();
		_have_solution=true;
		update_labels_from_model();
		_gnonogram_view.set_name(_("New game"));
		_gnonogram_view.set_author(" ");
		_gnonogram_view.set_date(" ");
		_gnonogram_view.set_score_label("  ");
		initialize_view();
		change_state(GameState.SETTING);
		redraw_all();
	}

	public void restart_game()
	{//stdout.printf("Restart game\n");
			_model.blank_working();
			initialize_view();
			redraw_all();
			_timer.start();
	}
//======================================================================
	public void save_game()
	{
		string filename;
		filename=Utils.get_filename(
			Gtk.FileChooserAction.SAVE,
			_("Name and save this game"),
			{_("Gnonogram games")},
			{"*"+Resource.GAMEFILEEXTENSION},
			Resource.game_dir
			);

		if (filename==null) return; //message?
		if (filename.length>3 && filename[-4:filename.length]!=Resource.GAMEFILEEXTENSION) filename = filename+Resource.GAMEFILEEXTENSION;

		var f=FileStream.open(filename,"w");
		if (write_game_file(f))
		{
			Utils.show_info_dialog((_("Saved as '%s'")).printf(Path.get_basename(filename)));
		}
	}
	public void save_pictogame()
	{
		string filename;
		filename=Utils.get_filename(
			Gtk.FileChooserAction.SAVE,
			_("Name and save as  pictogame"),
			{_("Picto games")},
			{"*.pattern"},
			Resource.game_dir
			);

		if (filename==null) return; //message?
		if (filename.length<9||filename[-8:filename.length]!=".pattern") filename = filename+".pattern";

		var f=FileStream.open(filename,"w");
		if (write_pictogame_file(f))
		{
			Utils.show_info_dialog((_("Saved as '%s'")).printf(Path.get_basename(filename)));
		}
	}
//======================================================================
	private bool write_game_file(FileStream f)
	{//stdout.printf("In write game file\n");
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
		_model.use_solution();
		f.printf("[Solution]\n");
		f.printf(_model.to_string());
		if (_state==GameState.SOLVING) _model.use_working();
		f.flush();
		return true;
	}
	private bool write_pictogame_file(FileStream f)
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
		return true;
	}
//=========================================================================
	private void save_position()
	{//stdout.printf("In save position\n");
		string filename=Resource.game_dir+"/"+Resource.POSITIONFILENAME;
		var f=FileStream.open(filename,"w");
		if (f==null || !write_position_file(f))
		{
			Utils.show_warning_dialog(_("An error occured creating the position file"));
			return;
		}
	}
//=========================================================================
	private bool write_position_file(FileStream f)
	{//stdout.printf("In write position file\n");
		write_game_file(f);

//		stdout.printf("about to write working file\n");
		_model.use_working();
		f.printf("[Working grid]\n");
		f.printf(_model.to_string());
		f.printf("[State]\n");
		f.printf(_state.to_string()+"\n");
		f.flush();
		return true;
	}
//=========================================================================
	public void load_game(string fname="")
	{
		var reader = new Gnonogram_filereader(Gnonogram_FileType.GAME, fname);
		if (reader.filename=="") return;
		new_game();
		if (load_common(reader))
		{
			initialize_view();
			start_solving();
		}
	}
//=========================================================================
	public void load_position()
	{
		new_game();
		var reader = new Gnonogram_filereader(Gnonogram_FileType.POSITION);
		if (load_common(reader) && load_position_extra(reader)){	}
		else Utils.show_warning_dialog(_("Failed to load saved position"));
	}
//=========================================================================
	private bool load_position_extra(Gnonogram_filereader reader)
	{
		if (reader.has_working)
		{
			_model.use_working();
			for (int i=0; i<_rows; i++)
			{
				_model.set_row_data_from_string(i,reader.working[i]);
			}
		}
		else
		{
			Utils.show_warning_dialog(_("Working data missing"));
			return false;
		}
		if (reader.has_state)
		{
			if (reader.state==(GameState.SETTING).to_string())
			{
				change_state(GameState.SETTING);
				redraw_all();
			}
			else
			{
				change_state(GameState.SOLVING);
			}
		}
		else
		{
			Utils.show_warning_dialog(_("State data missing"));
			return false;
		}
		return true;
	}
//=========================================================================
	private bool load_common(Gnonogram_filereader reader)
	{
		_have_solution=false;
		if (!reader.open_datainputstream())
		{
			Utils.show_warning_dialog(_("Could not open game file"));
			return false;
		}
		if (!reader.parse_game_file())
		{
			Utils.show_warning_dialog(_("File format incorrect"));
			return false;
		}
		//stdout.printf("File parsed\n");
		if (reader.has_dimensions)
		{
			int rows=reader.rows;
			int cols=reader.cols;
			if (rows>Resource.MAXROWSIZE||cols>Resource.MAXCOLSIZE)
			{
				Utils.show_warning_dialog(_("Dimensions too large"));
				return false;
			}
			else resize(rows,cols);
			_gnonogram_view.set_size(_rows,_cols);
			//stdout.printf("Dimensions set\n");
		}
		else
		{
			Utils.show_warning_dialog(_("Dimensions data missing"));
			return false;
		}

		if (reader.has_solution)
		{//stdout.printf("loading solution\n");
			_model.use_solution();
			for (int i=0; i<_rows; i++)  _model.set_row_data_from_string(i,reader.solution[i]);
			update_labels_from_model();
			_have_solution=true;
		}
		else if (reader.has_row_clues && reader.has_col_clues)
		{
			for (int i=0; i<_rows; i++) _rowbox.update_label(i,reader.row_clues[i]);
			for (int i=0; i<_cols; i++) _colbox.update_label(i,reader.col_clues[i]);
			int passes=solve_game(false,true,false); //no start grid, use advanced if necessary but not ultimate - too slow

			if (passes>0)
			{
				_have_solution=true;
				set_solution_from_solver();
			}
			else if (passes<0)
			{
				Utils.show_warning_dialog(_("Clues contradictory"));
				return false;
			}
			else
			{
				Utils.show_info_dialog(_("Game not soluble by computer"));
			}
		}
		else
		{
			Utils.show_warning_dialog(_("Clues and solution both missing"));
			return false;
		}

		if (reader.name.length>1) _gnonogram_view.set_name(reader.name);
		else	_gnonogram_view.set_name(Path.get_basename(reader.filename));
		_gnonogram_view.set_author(reader.author);
		_gnonogram_view.set_date(reader.date);
		_gnonogram_view.set_score_label(reader.score);
		return true;
	}
//======================================================================
	public void start_solving()
	{//stdout.printf("Start solving\n");
		change_state(GameState.SOLVING);
	}
//======================================================================
	public void reveal_solution()
	{//stdout.printf("Reveal solution\n");
		change_state(GameState.SETTING);
	}
//======================================================================
	public void peek_game()
	{//stdout.printf("Peek game\n");

		double seconds=_timer.elapsed();
		int hours= ((int)seconds)/3600;
		seconds-=((double)hours)*3600.000;
		int minutes=((int)seconds)/60;
		seconds-=(double)(minutes)*60.000;
		string time_taken=("\n\n"+_("Time taken is %d hours, %d minutes, %8.3f seconds")).printf(hours, minutes, seconds);
		if (_have_solution)
		{
			int count=_model.count_errors();
			if (count==0)
			{
				Utils.show_info_dialog(_("No errors")+time_taken);
			}
			else
			{
				Utils.show_info_dialog((_("There are %d incorrect cells"+time_taken)).printf(count));
			}
			redraw_all();
		}
		else
		{
			Utils.show_info_dialog(_("No solution available"+time_taken));
		}
	}
//======================================================================
	private void viewer_solve_game()
	{
		restart_game(); //clears any erroneous entries and also re-starts timer
		int passes = solve_game(true, _advanced,_advanced);
		_timer.stop();
		double time_taken=_timer.elapsed();
		show_solver_grid();
		switch (passes)
		{
			case -2:
				break;  //debug mode
			case -1:
				Utils.show_warning_dialog(_("Invalid - no solution"));

				break;
			case 0:
				Utils.show_info_dialog(_("Failed to solve or no unique solution"));
				break;
			default:
				_gnonogram_view.set_score_label(passes.to_string());
				Utils.show_info_dialog((_("Solved in %8.3f seconds").printf(time_taken)));
				break;
		}
		change_state(GameState.SOLVING);
	}

//======================================================================
	private void show_solver_grid()
	{		set_working_from_solver();
			redraw_all();
	}
//======================================================================
	private int solve_clues(string[] row_clues, string[] col_clues, My2DCellArray? startgrid, bool use_advanced, bool use_ultimate)
	{
		int passes=0;
		_solver.initialize(row_clues, col_clues,startgrid);
		passes=_solver.solve_it(_debug, use_advanced, use_ultimate);
		return passes;
	}
//======================================================================
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
//======================================================================
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
		for (int r=0; r<_rows; r++)
		{
			for(int c=0; c<=_cols; c++)
			{
				_model.set_data_from_cell(_solver.get_cell(r,c));
			}
		}
	}
//======================================================================
	public void set_difficulty(double d){_grade=(int)d;}
//======================================================================
	public void random_game()
	{
		new_game();
		int passes=0, count=0;
		int grade = _grade; //grade may be reduced but _grade always matches spin setting
		if (_difficult)
		{
			while (count<100)
			{
				count++;
				passes=generate_difficult_game(grade);
				if(passes>0)
				{
					if(grade<10)grade++;;
					continue;
				}
				passes=solve_game(false,true,false); //exclude simple games//solve using advanced solver (not ultimate) if possible
				stdout.printf(@"Passes:  $passes\n");
				if(passes<3*_grade) continue;
				if(passes>1000 & grade>1)grade--;
				if(passes<1000)break;
			}
		}
		else
		{
			while (count<10)
			{
				count++;
				passes=generate_simple_game(grade); //tries max tries times
				//stdout.printf(" Grade %d Passes - %d\n",grade, passes);
				if (passes>_grade||passes<0) break;
				if (passes==0 && grade>1)grade--;
				//no simple game generated with this setting -
				//reduce complexity setting (relationship between complexity setting
				//and ease of solution not simple - depends also on grid size)
			}
		}
		_have_solution=true;
		if (passes>=0)
		{
			string name= (passes>15) ? _("Difficult random") : _("Simple random");
			_gnonogram_view.set_name(name);
			_gnonogram_view.set_author(_("Computer"));
			_gnonogram_view.set_date(Utils.get_todays_date_string());
			_gnonogram_view.set_score_label(passes.to_string());
			_have_solution=true;
			_model.use_working();
			start_solving();
		}
		else
		{
			Utils.show_warning_dialog(_("Error occurred in solver"));
			stdout.printf(_solver.get_error()+"\n");
			_gnonogram_view.set_name(_("Error in solver"));
			_gnonogram_view.set_author("");
			_gnonogram_view.set_date("");
			_model.use_solution();
			reveal_solution();
		}
	}
//======================================================================
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
//======================================================================
	private int generate_difficult_game(int grade)
	{
		int tries=0, passes=1;
		while (passes>0 && tries<=Resource.MAXTRIES)
		{
			tries++;
			passes=generate_game(grade);
		}
		return passes;
	}
//======================================================================
	private int generate_game(int grade)
	{
		_model.fill_random(grade); //fills solution grid
		update_labels_from_model();
		return solve_game(false,false,false); // no start grid, no advanced
	}
//======================================================================
	private void update_labels_from_model()
	{	//stdout.printf("Update labels\n");
		for (int r=0; r<_rows; r++)
		{
			_rowbox.update_label(r,_model.get_label_text(r,false));
		}

		for (int c=0; c<_cols; c++)
		{
			_colbox.update_label(c,_model.get_label_text(c,true));
		}
		_rowbox.show_all(); _colbox.show_all();
	}
//======================================================================
	public void quit_game()
	{	//stdout.printf("In quit game\n");
		save_config();
		Gtk.main_quit();
	}
//======================================================================
	private void save_config()
	{
		var config_instance=Config.get_instance();
		config_instance.set_difficulty(_gnonogram_view.get_grade_spin_value());
		config_instance.set_dimensions(_rows, _cols);
		config_instance.set_colors();
//		Decided to remove this to prevent overwriting a manually saved position without warning. Perhaps make a settings option?
//		save_position();
	}
//======================================================================
	private void change_state(GameState gs)
	{
		initialize_cursor();
		_state=gs;
		if (gs==GameState.SETTING)	{_timer.stop(); _model.use_solution();}
		else	{_timer.start();_model.use_working();}
		_gnonogram_view.state_has_changed(gs);
	}
}
