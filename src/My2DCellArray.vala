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
 
 public class My2DCellArray
{
	private int _rows;
	private int _cols;
	private CellState[,] _data;
	
	public My2DCellArray(int rows, int cols, CellState init=CellState.UNKNOWN)
	{
		_rows=rows; _cols=cols;
		_data = new CellState[_rows,_cols];
		set_all(init);		
	}
	
//	public int rows() {return _rows;}	
//	public int cols() {return _cols;}
	
	public void set_data_from_cell(Cell c) {_data[c.row,c.col]=c.state;}
	public void set_data_from_rc(int r, int c, CellState s) {_data[r,c]=s;}
	public CellState get_data_from_rc(int r, int c) {return _data[r,c];}
	public Cell get_cell(int r, int c) {return {r,c,_data[r,c]};}
	
	public void get_row(int row, ref CellState[] sa, int start=0)
	{
		for (int c=start;c<start+sa.length;c++) sa[c]=_data[row,c];
	}
	
	public void set_row(int row, CellState[] sa, int start=0)
	{
		for (int c=start;c<start+sa.length;c++) _data[row,c]=sa[c];
	}
	
	public void get_col(int col, ref CellState[] sa, int start=0)
	{
		for (int r=start;r<start+sa.length;r++) {sa[r]=_data[r,col];}
	}
	
	public void set_col(int col, CellState[] sa, int start=0)
	{
		for (int r=start;r<start+sa.length;r++) {_data[r,col]=sa[r];}
	}
	
	public void get_array(int idx, bool iscolumn, ref CellState[] sa, int start=0)
	{
		if (iscolumn) get_col(idx, ref sa, start);
		else get_row(idx, ref sa, start);
	}

	public void set_array(int idx, bool iscolumn, CellState[] sa, int start=0)
	{
		if (iscolumn) set_col(idx, sa, start);
		else set_row(idx, sa, start);
	}

// 26/03/2011 deprecated - now use get _array and use size of CellState[] sa for end - safer.	
	public void get_region(int idx, bool iscolumn, ref CellState[] sa, int start=0, int end=-1)
	{
		if (iscolumn) get_col(idx, ref sa, start);
		else 	get_row(idx, ref sa, start);
	}
// 26/03/2011 deprecated - now use set _array and use size of CellState[] sa for end - safer.		
	public void set_region(int idx, bool iscolumn, CellState[] sa, int start=0, int end=-1)
	{
		if (iscolumn) set_col(idx, sa, start);
		else set_row(idx, sa, start);
	}
	
	public void set_all(CellState s)
	{
		for (int r=0; r<_rows; r++)
		{for (int c=0;c<_cols;c++)	_data[r,c]=s;}
	}
	
	public string id2text(int idx, bool iscolumn)
	{//stdout.printf("id2text\n");
		CellState[] arr = new CellState[iscolumn ? _rows : _cols];
		this.get_array(idx, iscolumn, ref arr);
		return Utils.block_string_from_cellstate_array(arr); 
	}
}
