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
 
 public class Gnonogram_solver {

	private int _rows;
	private int _cols;
	private int _region_count;
	public My2DCellArray _grid;
	private Gnonogram_region[] _regions;
	private int _current_region;

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
	
//=========================================================================	
	public int solve_it(bool debug, bool use_advanced=false)
	{
		int simple_result=simple_solver(debug);
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
	private int simple_solver(bool debug)
	{
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
					if (_regions[i].solve()) changed=true;
					if (_regions[i]._in_error)
					{
						stdout.printf(_regions[i].message);
						return -1;
					}
				}
				
				pass++;
				if (debug)
				{
					showsolvergrid();
					if (!Utils.show_confirm_dialog(@"Simple solver pass $pass ... continue?")) return 0;
				}
//				stdout.printf(@"CHanged $changed  Passes $pass\n");
			}
			if (solved()) return pass;
			else return 0;
/*		}
		else //step-wise mode for debugging
		{
			var r=_current_region; r++;
//			if (r==_region_count) r=0;
			while (r<_region_count && _regions[r]._completed) r++;
			if (r==_region_count) r=0;
			_regions[r].solve(true);
			stdout.printf(_regions[r].message);
			_current_region=r;
			return -2;
		}
*/
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
	// make a guess in each unknown cell in turn
	// if leads to contradiction mark opposite to guess, continue simple solve, if still no solution start again.
	// if does not lead to solution leave unknown and choose another cell
	// if leads to solution - success!
	
	{	int simple_result=0;
		int limit=_rows*_cols; //maximum possible alternative guesses = all cells
		Cell trial_cell= {0,-1,CellState.UNKNOWN};
		CellState[] grid_store= new CellState[limit];

		int guesses=0;
//		stdout.printf("limit on guesses is %d\n",limit);
		bool changed=false;
		while (guesses<limit) //no infinite loops please
		{
			guesses++;	
			this.save_position(grid_store);

			if (debug)
			{
				showsolvergrid();
				if (!Utils.show_confirm_dialog(@"Guess $guesses ... continue?")) return 0;
			}
		
			trial_cell=this.make_guess(trial_cell); 
			
			if (trial_cell.col==-1)
			{
				if (changed)
				{
					trial_cell=this.make_guess(trial_cell); //wrap back to start
					stdout.printf("Wrapping ... \n");
					changed=false;
					guesses=0;
				}
				else break;
			}	

			_grid.set_data_from_cell(trial_cell);

			if (debug)
			{
				showsolvergrid();
				if (!Utils.show_confirm_dialog("Made guess ... continue?"))
				{
					this.load_position(grid_store);
					return -1;
				}
			}
		
			//simple_result=simple_solver(debug);
			simple_result=simple_solver(false); //only debug advanced part
			stdout.printf("Simple result %d\n",simple_result);

			if (debug)
			{			
				showsolvergrid();
				if (!Utils.show_confirm_dialog(@"Result $simple_result ... continue?"))
				{
					this.load_position(grid_store);
					return -1;
				}
			}

			if (simple_result<0) //contradiction - backtrack	
			{
				this.load_position(grid_store); //restore starting position				
				_grid.set_data_from_cell(trial_cell.invert()); //mark opposite to guess
				stdout.printf("Setting cell %d,%d empty\n",trial_cell.row,trial_cell.col);
				changed=true; //worth trying another cycle of guesses

				
				//simple_result=simple_solver(debug); //can we solve now?
				simple_result=simple_solver(false);
				
				if (simple_result>0) break; 
				else if (simple_result<0)
				{
					Utils.show_warning_dialog("ERROR in advanced solver - both alternatives lead to contradiction");
					return -1;
				}
				else
				{	//try another guess
					continue;
					//stdout.printf("Try another guess ...\n");
					// could recurse to another level here - but wont
					//trial_cell= {0,-1,CellState.UNKNOWN};
					//guesses=0;
				}
			}
			else if (simple_result>0) break;
			else //does not lead to solution or contradiction
			{
				this.load_position(grid_store);
				// leave this guess as unknown
				//stdout.printf("Trying another guess - %d\n",guesses+1);
			}
		}
		//return vague measure of difficulty
		if (simple_result>0) return simple_result+ 2*guesses;
//		stdout.printf("Returning from advanced solver\n");
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
	private Cell make_guess(Cell last_guess) {
		stdout.printf("make guess \n");
		Cell guess = {0,-1,CellState.UNKNOWN};
		
		int start_row=last_guess.row;
		int start_col=last_guess.col+1;
		if (start_col==_cols)
		{
			start_col=0; start_row++;
		}
		for (int r=start_row; r<_rows; r++)
		{	for (int c=start_col; c<_cols; c++)
			{
				start_col=0; //next loop starts at zero
				if (_grid.get_data_from_rc(r,c)==CellState.UNKNOWN)
				{
					//_grid.set_data_from_rc(r,c,CellState.FILLED);
					stdout.printf("Trying %d,%d\n",r,c);
					guess={r,c,CellState.FILLED};
					return guess;
				}
			}
		}
		return guess;
	}
//======================================================================
	public Cell get_cell(int r, int c)
	{
		return _grid.get_cell(r,c);
	}
}

