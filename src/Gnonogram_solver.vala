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
 
 //experimental - optimise
 public class Gnonogram_solver {

	private int _rows;
	private int _cols;
	private int _region_count;
	public My2DCellArray _grid;
	private Gnonogram_region[] _regions;
	private int _current_region;
	private Cell _trial_cell;
	private int _rdir;
	private int _cdir;
	private int _rlim;
	private int _clim;
	private int _turn;
	private int _max_turns;

	public signal void showsolvergrid();

//=========================================================================	
	public Gnonogram_solver(int rows, int cols, bool testing=false, bool debug=false, bool test_column=false, int test_idx=-1) {

		_grid=new My2DCellArray(Resource.MAXROWSIZE, Resource.MAXCOLSIZE); 
		_regions=new Gnonogram_region[Resource.MAXROWSIZE+Resource.MAXCOLSIZE];
		
		for (int i=0;i<_regions.length;i++) _regions[i]=new Gnonogram_region(_grid);
		
		set_dimensions(rows,cols);
	}
	
//======================================================================
		public void set_dimensions(int r, int c) {
		_rows=r;
		_cols=c;
		_region_count=_rows+_cols;
	}
//======================================================================
	public bool initialize(string[] row_clues, string[] col_clues, My2DCellArray? start_grid)
	{		
		if (row_clues.length!=_rows || col_clues.length!=_cols)
		{
			stdout.printf("row/col size mismatch\n");
			return false;
		}
		
		if (start_grid==null) _grid.set_all(CellState.UNKNOWN);
		else _grid.copy(start_grid);
			
		for (int r=0; r<_rows; r++) _regions[r].initialize(r, false,_cols,row_clues[r]);
		
		for (int c=0; c<_cols; c++) _regions[c+_rows].initialize(c,true,_rows,col_clues[c]);
		
		_current_region=-1;
		return valid();
	}
//======================================================================
	public bool valid()
	{
		foreach (Gnonogram_region r in _regions)
			{ if (r._in_error) return false;}
			
		return true;
	}

	public string get_error()
	{
		for (int i=0; i<_region_count; i++)
				{	if (_regions[i]._in_error) return _regions[i].message;}
		return "No error";
	}
	
//=========================================================================	
	public int solve_it(bool debug, bool use_advanced=false)
	{
		int simple_result=simple_solver(debug,true); //log errors
		if (simple_result==0 && use_advanced)
		{
			int advanced_result=advanced_solver(debug);
			if (advanced_result>0)
			{
				return advanced_result;
			}
		}
		else return simple_result;
		
		return 0;
	}
//======================================================================
	private int simple_solver(bool debug, bool log_error=false)
	{//stdout.printf("Simple solver\n");
		bool changed=true;
		int pass=1;
//		if (!debug)
//		{
			while (changed && pass<30)
			{//keep cycling through regions while at least one of them is changing (up to 30 times)
				changed=false;		
				for (int i=0; i<_region_count; i++)
				{	
					if (_regions[i]._completed) continue;
					if (_regions[i].solve(debug)) changed=true;
					if (debug ||(log_error && _regions[i]._in_error))
					{
						stdout.printf("Error - %d: %s\n",i,_regions[i].message);
					}
					if (_regions[i]._in_error) return -1;
				}
				
				pass++;
				if (debug)
				{
					showsolvergrid();
					if (!Utils.show_confirm_dialog(@"Simple solver pass $pass ... continue?")) return 0;
				}
			}
			if (solved()) return pass;
			if (pass>30) stdout.printf("Simple solver - too many passes\n");
			return 0;
	}

//======================================================================	
	public bool solved()
	{
		for (int i=0; i<_region_count; i++)
		{
			if (!_regions[i]._completed) return false;
		}
		return true;
	}
//======================================================================
// Debugging assistants
	public bool get_current_iscolumn() {return _regions[_current_region]._is_column;}
	public int get_current_index() {return _regions[_current_region]._index;}
//======================================================================
	private int advanced_solver(bool debug)
	//single cell guesses, depth 1 (no recursion)
	// make a guess in each unknown cell in _turn
	// if leads to contradiction mark opposite to guess, continue simple solve, if still no solution start again.
	// if does not lead to solution leave unknown and choose another cell
	// if leads to solution - success!
	
	{	//stdout.printf("Advanced solver\n");
		//if (!Utils.show_confirm_dialog("Use advanced solver (experimental)?")) return 0;
	
		int simple_result=0;
		int limit=_rows*_cols; //maximum possible alternative guesses = all cells
		int guesses=0, wraps=0;
		bool changed=false;
		int initial_maxturns=3; //stay near edges until no more changes

		_rdir=0; _cdir=1; _rlim=_rows; _clim=_cols; _turn=0; _max_turns=initial_maxturns;
				
		_trial_cell= {0,-1,CellState.FILLED};
		CellState[] grid_store= new CellState[limit];

		while (true) 
		{
			guesses++;	
			this.save_position(grid_store);

			if (debug)
			{
				showsolvergrid();
				if (!Utils.show_confirm_dialog(@"Guess $guesses ... continue?")) return 0;
			}
		
			make_guess(); 
			
			if (_trial_cell.col==-1) //run out of guesses
			{
				if (changed)
				{//wrap back to start
					//use opposite guess this time?
					//_trial_cell=this.make_guess(_trial_cell.invert());
					//_trial_cell=_trial_cell.invert(); //- no advantage?
				}
				else if (_max_turns==initial_maxturns)
				{
					_max_turns=(int.min(_rows,_cols))/2+2; //ensure full coverage
				}
				else break; //cant make progress

				_rdir=0; _cdir=1; _rlim=_rows; _clim=_cols; _turn=0;
				
				//make_guess();
								
				changed=false;
				wraps++;
				stdout.printf("Wrapping ... max _turns %d\n", _max_turns);
				if (debug)
				{
					showsolvergrid();
					Utils.show_confirm_dialog(@"Trial $(_trial_cell.row), $(_trial_cell.col), $(_trial_cell.state)\n _rdir $_rdir, _cdir $_cdir\n_turn $_turn, _max_turns $_max_turns, _rlim $_rlim, _clim $_clim\nresult $simple_result\n ... continue?");
				}
				continue;
			}	
			_grid.set_data_from_cell(_trial_cell);

			if (debug)
			{
				showsolvergrid();
				if (!Utils.show_confirm_dialog("Made guess ... continue?"))
				{
					this.load_position(grid_store);
					return 0;
				}
			}

			simple_result=simple_solver(false,false); //only debug advanced part, ignore errors

			if (debug)
			{			
				showsolvergrid();
				Utils.show_confirm_dialog(@"Trial $(_trial_cell.row), $(_trial_cell.col), $(_trial_cell.state)\n _rdir $_rdir, _cdir $_cdir\n_turn $_turn, _rlim $_rlim, _clim $_clim\nresult $simple_result\n ... continue?");
			}

			if (simple_result>0) break; //solution found
			
			load_position(grid_store); //back track
			if (simple_result<0) //contradiction -  try opposite guess
			{			
				_grid.set_data_from_cell(_trial_cell.invert()); //mark opposite to guess
				changed=true; //worth trying another cycle of guesses
				//stdout.printf("Changed %d, %d\n",_trial_cell.row,_trial_cell.col);
 
				simple_result=simple_solver(false,false);//can we solve now?

				if (simple_result==0)
				{//go back to start
					continue;
				}
				else 	if (simple_result>0) break; // solution found
				else 
				{
					Utils.show_warning_dialog("ERROR in advanced solver - both alternatives lead to contradiction");
					return -1;
				}
			}
			else
			{
				continue; //guess again
			}
		}
		//return vague measure of difficulty
		stdout.printf(@"simple result $simple_result guesses $guesses wraps $wraps\n");
		if (simple_result>0) return simple_result+ 2*guesses;// + _region_count*wraps;
//		stdout.printf("returning from advanced solver\n");
		return 0;
	}				
//======================================================================
	private void save_position(CellState[] gs)
	{ //store grid in linearised form.
	//stdout.printf("Save position\n");
		for(int r=0; r<_rows; r++)
		{	for(int c=0; c<_cols; c++)
			{
				gs[r*_cols+c]=_grid.get_data_from_rc(r,c);
			}
		}
		for (int i=0; i<_region_count; i++) _regions[i].save_state();
	}
//======================================================================
	private void load_position(CellState[] gs)
	{//stdout.printf("Load position\n");
		for(int r=0; r<_rows; r++)
		{	for(int c=0; c<_cols; c++)
			{
				_grid.set_data_from_rc(r,c, gs[r*_cols+c]);
			}
		}
		for (int i=0; i<_region_count; i++) _regions[i].restore_state();
	}
//======================================================================
//	private Cell make_guess(Cell last_guess) {
	private void xmake_guess() {
		//stdout.printf("make guess \n");
		// raster scan (not optimised)
		
//		int start_row=last_guess.row;
//		int start_col=last_guess.col+1;
		int start_row=_trial_cell.row;
		int start_col=_trial_cell.col+1;
		
		if (start_col==_cols) {start_col=0; start_row++;}
		
		for (int r=start_row; r<_rows; r++)
		{	for (int c=start_col; c<_cols; c++)
			{
				start_col=0; //next loop starts at zero
				if (_grid.get_data_from_rc(r,c)==CellState.UNKNOWN)
				{
					//stdout.printf("Trying %d,%d\n",r,c);
					_trial_cell.row=r; _trial_cell.col=c;
					//return last_guess;
					return;
				}
			}
		}
//		last_guess.row=0; last_guess.col=-1;
//		return last_guess;
		return;
	}
//======================================================================	
	private void make_guess()
	{	//stdout.printf("make guess2\n");
		//scan in spiral pattern from edges.  Critical cells most likely in this region
		int r=_trial_cell.row;
		int c=_trial_cell.col;
		
		while (true)
		{
			r+=_rdir; c+=_cdir; //only one changes at any one time
			if (_cdir==1 && c>=_clim) {c--;_cdir=0;_rdir=1;r++;} //across top - rh edge reached
			else if (_rdir==1 && r>=_rlim) {r--;_rdir=0;_cdir=-1;c--;} //down rh side - bottom reached
			else if (_cdir==-1 && c<_turn) {c++; _cdir=0;_rdir=-1;r--;} //back across bottom lh edge reached
			else if (_rdir==-1 && r<=_turn) {r++;_turn++;_rlim--;_clim--;_rdir=0;_cdir=1;} //up lh side - top edge reached
			if (_turn>_max_turns) {_trial_cell.row=0;_trial_cell.col=-1;break;} //stay near edge until no more changes
			if (_grid.get_data_from_rc(r,c)==CellState.UNKNOWN)
			{
				_trial_cell.row=r; _trial_cell.col=c;
				//stdout.printf(@"row $r, col $c\n");
				return;
			}
		}	
		return;
	}
//======================================================================
	public Cell get_cell(int r, int c)
	{
		return _grid.get_cell(r,c);
	}
}

