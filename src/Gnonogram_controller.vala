/*  Copyright (C) 2010-2011  Jeremy Wootten
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * As a special exception, if you use inline functions from this file, this
 * file does not by itself cause the resulting executable to be covered by
 * the GNU Lesser General Public License.
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
	private Gnonogram_view _gnonogram_view;
	private Gnonogram_LabelBox _colbox;
	private Gnonogram_LabelBox _rowbox;
	private Gnonogram_CellGrid _cellgrid;
	private Gnonogram_model _model;
	private Gnonogram_solver _solver;
	
	private int _rows;
	private int _cols;
	private Cell _current_cell;
	private Cell _previous_cell;
	private bool _is_button_down;
	private GameState _state {get; private set;}
	private bool _gridlinesvisible;
	
//======================================================================
	public Gnonogram_controller(int r, int c)
	{
		if (r<1||c<1)
		{
			Config.get_instance().get_dimensions(out _rows, out _cols);
		}
		else
		{
			_rows=r;
			_cols=c;
		}
		_model=new Gnonogram_model(_rows,_cols);
		_solver=new Gnonogram_solver(_rows, _cols);

		double grade=Config.get_instance().get_difficulty();
		_model.set_difficulty(grade);
		
		create_view();
		initialize_view();
	}
//======================================================================

	private void create_view()
	{
		_rowbox = new Gnonogram_LabelBox(_rows, _cols, false);
		_colbox = new Gnonogram_LabelBox(_cols, _rows, true);
		_cellgrid = new Gnonogram_CellGrid(_rows,_cols);
		_gridlinesvisible=false;
		_gnonogram_view = new Gnonogram_view(_rowbox, _colbox, _cellgrid, this);
		_gnonogram_view.solvegame.connect(this.viewer_solve_game);
		_gnonogram_view.savegame.connect(this.save_game);
		_gnonogram_view.loadgame.connect(this.load_game);
		_gnonogram_view.saveposition.connect(this.save_position);
		_gnonogram_view.loadposition.connect(()=>{this.load_position(); change_state(_state);});
		_gnonogram_view.quitgamesignal.connect(()=>{quit_game();});
		_gnonogram_view.newgame.connect(this.new_game);
		_gnonogram_view.hidegame.connect(this.start_solving);
		_gnonogram_view.revealgame.connect(this.reveal_solution);
		_gnonogram_view.peekgame.connect(this.peek_game);
		_gnonogram_view.restartgame.connect(this.restart_game);
		_gnonogram_view.randomgame.connect(this.random_game);
		_gnonogram_view.setcolors.connect(()=>{Resource.set_colors(); redraw_all();});
		_gnonogram_view.resizegame.connect(this.change_size);
		_gnonogram_view.key_press_event.connect(this.key_pressed);
		_gnonogram_view.key_release_event.connect(this.key_released);
		_gnonogram_view.setdifficulty.connect(this.set_difficulty);
		_gnonogram_view.togglegrid.connect(this.gridlines_toggled);
		_gnonogram_view.changefont.connect(this.change_font_size);

		_cellgrid.cursor_moved.connect(this.grid_cursor_moved);
		_cellgrid.button_press_event.connect(this.button_pressed);
		_cellgrid.button_release_event.connect(()=>{this._is_button_down=false; return true;});
		_cellgrid.expose_event.connect(()=>{redraw_all(); return false;});

		_gnonogram_view.set_grade_spin_value(_model._grade);
	}
//======================================================================
	private void initialize_view()
	{
		_current_cell.row=0;
		_current_cell.col=0;
		_previous_cell.row=0;
		_previous_cell.col=0;
		_is_button_down=false;
		update_labels_from_model();
		_gnonogram_view.show_all();
		redraw_all();
	}
//======================================================================
	private void change_size()
	{
		int r,c;
		if (Utils.get_dimensions(out r,out c,_rows,_cols)) resize(r,c);
	}
//======================================================================
	private void resize(int r, int c)
	{
		if (r>Resource.MAXROWSIZE||c>Resource.MAXCOLSIZE) return;
		_rows=r;_cols=c;
		_rowbox.resize(r, c);
		_colbox.resize(c, r);
		_cellgrid.resize(r,c);
		_solver.set_dimensions(r,c);
		_model.set_dimensions(r,c);
		initialize_view();
		change_state(GameState.SETTING);
		_gnonogram_view.reshow_with_initial_size();
	}
//======================================================================
	private void gridlines_toggled(bool active)
	{	
		if (_gridlinesvisible!=active)
		{
			_gridlinesvisible=active;
			redraw_all();
		}
	}
//======================================================================
	private bool button_pressed(Gdk.EventButton e)
	{
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
			update_cell(_current_cell);
		}
		return true;
	}
//======================================================================
	private bool key_pressed(Gdk.EventKey e)
	{
		string name=(Gdk.keyval_name(e.keyval)).up();
		int currentrow=_current_cell.row;
		int currentcol=_current_cell.col;
		
		switch (name)
		{
			case "UP":
				if (currentrow>0) currentrow-=1;
								break;
			case "DOWN":
				if (currentrow<_rows-1) currentrow+=1;
								break;
			case	"LEFT":
				if (currentcol>0) currentcol-=1;
								break;
			case "RIGHT":
				if (currentcol<_cols-1) currentcol+=1;
								break;
			case "CONTROL_L":
				_current_cell.state=CellState.FILLED;
				update_cell(_current_cell);
				_is_button_down=true;
								break;
			case "SHIFT_L":
				_current_cell.state=CellState.EMPTY;
				update_cell(_current_cell);
				_is_button_down=true;
								break;
			case "ALT_L":
				if (_state==GameState.SOLVING)
				{
				_current_cell.state=CellState.UNKNOWN;
				update_cell(_current_cell);
				_is_button_down=true;
				}
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
		grid_cursor_moved(currentrow,currentcol);
		return true;
	}
//======================================================================
	private bool key_released(Gdk.EventKey e){
		string name=(Gdk.keyval_name(e.keyval)).up();
		if (name=="CONTROL_L"||name=="ALT_L"||name=="SHIFT_L") _is_button_down=false;
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
		_cellgrid.highlight_cell(_previous_cell,false);
		if (_current_cell.changed(r,c))
		{
			if (_is_button_down) update_cell(_current_cell);
			else _current_cell=_model.get_cell(r,c);
			
			highlight_labels(_previous_cell, false);
			highlight_labels(_current_cell, true);
			_previous_cell.copy(_current_cell);
		}
		_cellgrid.highlight_cell(_current_cell,true);
	}
//======================================================================
	private void highlight_labels(Cell c, bool is_highlight)
	{
		_rowbox.highlight(c.row, is_highlight);
		_colbox.highlight(c.col, is_highlight);
	}
//======================================================================
	public void update_cell(Cell c)
	{//stdout.printf("update_cell\n");
		_model.set_data_from_cell(c);
		_cellgrid.draw_cell(c,_state);
		
		if (_state==GameState.SETTING)
		{
			_rowbox.update_label(c.row, _model.get_label_text(c.row,false));
			_colbox.update_label(c.col, _model.get_label_text(c.col,true));
		}
	}
//======================================================================
	private void redraw_all()
	{ 
		_cellgrid.prepare_to_redraw_cells(_gridlinesvisible);
		for (int r=0; r<_rows; r++)
		{
			for (int c=0; c<_cols; c++)
			{
				_cellgrid.draw_cell(_model.get_cell(r,c), _state);
			}
		}
	}
//======================================================================
	public void new_game()
	{
		_model.clear();
		update_labels_from_model();
		initialize_view();
		change_state(GameState.SETTING);
	}
	
	public void restart_game()
	{
			_model.blank_working();
			initialize_view();
	}
//======================================================================
	public void save_game()
	{
		string filename;
		filename=Utils.get_filename(
			Gtk.FileChooserAction.SAVE,
			_("Name and save this game"),
			{_("Gnonogram games")},
			{"*.tsg"},
			Resource.game_dir
			);
		
		if (filename==""||filename.length<5) return; //message?
		if (filename[-4:filename.length]!=".tsg") filename = filename+".tsg";
		
		var f=FileStream.open(filename,"w");
		if (write_game_file(f))
		{
			_gnonogram_view.set_name(Path.get_basename(filename));
		}
	}
//======================================================================
	private bool write_game_file(FileStream f)
	{//stdout.printf("In write game file\n");
		f.printf("[Dimensions]\n");
		f.printf("%d\n",_rows);
		f.printf("%d\n",_cols);
		f.printf("[Row clues]\n");
		f.printf(_rowbox.to_string());
		f.printf("[Column clues]\n");
		f.printf(_colbox.to_string());
		//stdout.printf("about to write solution\n");
		_model.use_solution();
		f.printf("[Solution]\n");
		f.printf(_model.to_string());
		f.flush();
		return true;
	}
//=========================================================================
	private void save_position()
	{//stdout.printf("In save position\n");
		string filename=Resource.game_dir+"/currentposition.tsp";
		var f=FileStream.open(filename,"w");
		if (f==null)
		{
			Utils.show_warning_dialog(_("An error occured saving the position file"));
			return;
		}
		write_position_file(f);
	}
//=========================================================================
	private bool write_position_file(FileStream f)
	{//stdout.printf("In write position file\n");
		write_game_file(f);

		//stdout.printf("about to write working file\n");
		_model.use_working();
		f.printf("[Working grid]\n");
		f.printf(_model.to_string());
		f.printf("[State]\n");
		f.printf(_state.to_string()+"\n");
		f.printf("[Name]\n");
		f.printf(_gnonogram_view.get_name()+"\n");
		f.flush();
		return true;
	}
//=========================================================================
	public void load_game()
	{
		new_game(); 
		var reader = new Gnonogram_filereader(Gnonogram_FileType.GAME);
		if (load_common(reader))
		{
			start_solving();
		}
	}
//=========================================================================
	public void load_position()
	{
		new_game(); 
		var reader = new Gnonogram_filereader(Gnonogram_FileType.POSITION);
		if (load_common(reader) && load_position_extra(reader)){	}
		else Utils.show_warning_dialog("Failed to load saved position");
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
			Utils.show_warning_dialog("Working missing");
			return false;
		}
		if (reader.has_state)
		{
			if (reader.state==GameState.SETTING.to_string())
			{
				change_state(GameState.SETTING);
			}
			else
			{
				change_state(GameState.SOLVING);
			}
		}
		else
		{
			Utils.show_warning_dialog("State missing");
			return false;			
		}
		if (reader.has_name)
		{
			_gnonogram_view.set_name(reader.name);
		}
		else
		{
			_gnonogram_view.set_name("Current position");
		}
		return true;
	}
//=========================================================================
	private bool load_common(Gnonogram_filereader reader)
	{
		if (!reader.open_datainputstream())
		{
			Utils.show_warning_dialog("Could not open game file");
			return false;
		}
		if (!reader.parse_game_file())
		{
			Utils.show_warning_dialog("Game file format incorrect");
			return false;
		}
		//stdout.printf("File parsed\n");
		if (reader.has_dimensions)
		{
			int rows=reader.rows;
			int cols=reader.cols;
			if (rows>Resource.MAXROWSIZE||cols>Resource.MAXCOLSIZE)
			{
				Utils.show_warning_dialog("Dimensions too large");
				return false;
			}
			else if (rows!=_rows || cols!=_cols) resize(rows,cols);
			//stdout.printf("Dimensions set\n");
		}
		else
		{
			Utils.show_warning_dialog("Dimensions missing");
			return false;
		}

		if (reader.has_solution)
		{
			_model.use_solution();
			for (int i=0; i<_rows; i++)  _model.set_row_data_from_string(i,reader.solution[i]);
			update_labels_from_model();
		}
		else if (reader.has_row_clues && reader.has_col_clues)
		{
			for (int i=0; i<_rows; i++) _rowbox.update_label(i,reader.row_clues[i]);
			for (int i=0; i<_cols; i++) _colbox.update_label(i,reader.col_clues[i]);
			if (solve_game()>0) 
			{
				set_solution_from_solver();
			}
			else
			{
				Utils.show_info_dialog("Game not solved by computer");
			}
		}
		else
		{
			Utils.show_warning_dialog("Clues and solution both missing");
			return false;
		}
		if (reader.has_name)
		{
			_gnonogram_view.set_name(reader.name);
		}
		else
		{
			_gnonogram_view.set_name(Path.get_basename(reader.filename));
		}
		_gnonogram_view.set_name(Path.get_basename(reader.filename));
		return true;
	}
//======================================================================
	public void start_solving()
	{
		change_state(GameState.SOLVING);
	}
//======================================================================
	public void reveal_solution()
	{
		change_state(GameState.SETTING);
	}
//======================================================================
	public void unpeek_game()
	{
		_model.check_solution();
		change_state(GameState.SOLVING);
	}
//======================================================================
	public void peek_game()
	{
		change_state(GameState.SETTING);
		var timer = new TimeoutSource.seconds(1);
		timer.set_callback(()=>{unpeek_game(); return false;});
		timer.attach(null);
	}
//======================================================================
	private void viewer_solve_game()
	{
		int passes = solve_game();
		switch (passes) 
		{
			case -1:
				_gnonogram_view.set_name(_("Invalid; no solution"));
				break;
			case 0:
				_gnonogram_view.set_name(_("No unique solution"));
				break;
			default:
				_gnonogram_view.set_name(_("Solved in %d passes").printf(passes));
				break;
		}
		
		set_working_from_solver();
		change_state(GameState.SOLVING);
	}
//======================================================================
	private int solve_clues(string[] row_clues, string[] col_clues)
	{
		int passes=0;
		passes=_solver.solve_it(row_clues, col_clues);
		return passes;
	}
//======================================================================
	private int solve_game()
	{
		var row_clues= new string[_rows];
		var col_clues= new string[_cols];
		
		for (int i =0; i<_rows; i++) row_clues[i]=_rowbox.get_label_text(i);
		for (int i =0; i<_cols; i++) col_clues[i]=_colbox.get_label_text(i);
		
		return solve_clues(row_clues,col_clues);
	}
//======================================================================
	private void set_solution_from_solver()
	{
		_model.use_solution();
		set_model_from_solver();
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
	public void set_difficulty(double d)
	{
		_model.set_difficulty(d);
	}
//======================================================================
	public void random_game()
	{
		_model.use_solution(); //so can calc labels
		
		int passes=0, count=0;
		int grade = (int)(_gnonogram_view.get_grade_spin_value());
		while (passes<1&&count<10)
		{
			passes=generate_solvable_game(); //returns 0 if fails
			if (passes<1)
			{
				_model.reduce_difficulty();
				grade--;
			}
			else if (passes<grade)
			{
				passes=0;
			}
			count++;
		}
		if (passes>0)
		{
			_gnonogram_view.set_name("%d passes".printf(passes));
			start_solving();
		}
		else
		{ 
			Utils.show_warning_dialog(_("Failed to generate puzzle - try reducing difficulty"));
			new_game();
		}
	}
//======================================================================
	private int generate_solvable_game()
	{
		int tries=0, passes=0;
		while (passes<1 && tries<=Resource.MAXTRIES)
		{
			tries++;
			_model.fill_random(); //fills solution grid
			update_labels_from_model(); 
			passes=solve_game();
		}
		return passes;
	}
//======================================================================
	private void update_labels_from_model()
	{	
		for (int r=0; r<_rows; r++)
		{
			_rowbox.update_label(r,_model.get_label_text(r,false));
		}
		
		for (int c=0; c<_cols; c++)
		{
			_colbox.update_label(c,_model.get_label_text(c,true));
		}
	}
//======================================================================
//	[CCode (instance_pos = -1)]
	public void quit_game()
	{
		//stdout.printf("In quit game\n");
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
		save_position();
	}
//======================================================================
	private void change_state(GameState gs)
	{
		_state=gs;
		
		if (gs==GameState.SETTING)
		{
			_model.use_solution();
		}
		else
		{
			_model.use_working();
		}
		_gnonogram_view.state_has_changed(gs);
		redraw_all();
	}
}
