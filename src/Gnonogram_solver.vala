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

//=========================================================================	
	public Gnonogram_solver(int rows, int cols, bool testing=false, bool debug=false, bool test_column=false, int test_idx=-1) {

		_grid=new My2DCellArray(Resource.MAXROWSIZE, Resource.MAXCOLSIZE); //initialized to CellState.UNKNOWN.
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
	public bool initialize(string[] row_clues, string[] col_clues)
	{
		_grid.set_all(CellState.UNKNOWN);
		
		if (row_clues.length!=_rows || col_clues.length!=_cols)
		{
			stdout.printf("row/col size mismatch\n");
			return false;
		}
		
		for (int r=0; r<_rows; r++) _regions[r].initialize(r, false,_cols,row_clues[r]);
		
		for (int c=0; c<_cols; c++) _regions[c+_rows].initialize(c,true,_rows,col_clues[c]);

		return valid();
	}
//======================================================================
	public bool valid()
	{
		for (int i=0; i<_region_count; i++)
		{
			if (_regions[i]._in_error) return false;
		}
		return true;
	}
	
//=========================================================================	
	public int solve_it(string[] row_clues, string[] col_clues) {

		if (! initialize(row_clues, col_clues)) return -1;
		
		bool changed=true;
		int pass=0;
		
		while (changed && pass<30) {
			changed=false;
			
			for (int i=0; i<_region_count; i++)
			{	
				if (_regions[i]._completed) continue;

				if (_regions[i].solve(pass))
				{	
					if (_regions[i]._in_error)
					{
						stdout.printf("Region %d in error\n",i);
						changed=false;
						break;
					}
					else changed=true;
				}
			}
			pass++;
		}
		if (solved())	return pass;
		else return 0;
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
	public Cell get_cell(int r, int c)
	{
		return _grid.get_cell(r,c);
	}
}

