/* CellGrid class for Gnonograms
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
using Cairo;

public class Gnonogram_CellGrid : DrawingArea
{
	public signal void cursor_moved(int r, int c);

	private int _rows;
	private int _cols;
	private double _aw;
	private double _ah;
	private double _wd;
	private double _ht;
	private double _cell_offset;
	private double _cell_body_width;
	private double _cell_body_height;
	private Gdk.Color cr_color;
//======================================================================
	public Gnonogram_CellGrid(int r, int c)
	{
		_rows=r;
		_cols=c;

		add_events(
		EventMask.BUTTON_PRESS_MASK|
		EventMask.BUTTON_RELEASE_MASK|
		EventMask.POINTER_MOTION_MASK|
		EventMask.KEY_PRESS_MASK|
		EventMask.KEY_RELEASE_MASK|
		EventMask.LEAVE_NOTIFY_MASK
		);

		motion_notify_event.connect(pointer_moved);
		leave_notify_event.connect(leave_grid);
	}
//=========================================================================
	public void resize(int r, int c) {_rows=r;_cols=c;}
//=========================================================================
	public void prepare_to_redraw_cells(bool show_grid)
	{ //stdout.printf("In prepare to redraw\n");
		if (this.window==null) return;
		_aw=(double)allocation.width;
		_ah=(double)allocation.height;
		_wd=(_aw-2)/(double)_cols;
		_ht=(_ah-2)/(double)_rows;
		window.clear();

		if (show_grid)
		{
			_cell_offset=Resource.CELLOFFSET_WITHGRID;
			draw_grid();
		}
		else _cell_offset=Resource.CELLOFFSET_NOGRID;

		//dimensions of filled part
		_cell_body_width=_wd-_cell_offset;
		_cell_body_height=_ht-_cell_offset;
	}
//=====================================================================

	public void draw_cell(Cell cell, GameState gs, bool highlight=false)
	{	//don't draw cell outside grid.
		if (cell.row<0||cell.row>=_rows||cell.col<0||cell.col>=_cols)return;

/* coords of top left corner of filled part
/* (excluding grid if present but including highlight line)
 */
		double x=cell.col*_wd +_cell_offset;
		double y= cell.row*_ht +_cell_offset;
		bool error=false;

		var _cr=Gdk.cairo_create(this.window);

		switch (cell.state)
		{
			case CellState.EMPTY:
			case CellState.FILLED:
			case CellState.ERROR:
				cr_color=Resource.colors[gs,(int) cell.state];
				break;
			case CellState.ERROR_EMPTY:
				cr_color=Resource.colors[gs,(int) CellState.EMPTY];
				error=true;
				break;
			case CellState.ERROR_FILLED:
				cr_color=Resource.colors[gs,(int) CellState.FILLED];
				error=true;
				break;
			default :
				cr_color=style.bg[Gtk.StateType.NORMAL];
				break;
		}

		Gdk.cairo_set_source_color(_cr, cr_color);
		draw_cell_body(_cr, x,y, highlight, error);
	}
//=========================================================================
	private void draw_cell_body(Cairo.Context _cr, double x, double y, bool highlight=false, bool error=false)
	{
		_cr.set_line_width(0.5);
		_cr.rectangle(x, y, _cell_body_width, _cell_body_height);
		_cr.fill();

		if (error)
		{
			_cr.set_line_width(4.0);
			Gdk.cairo_set_source_color(_cr, Resource.colors[0,(int) CellState.ERROR]);
			_cr.rectangle(x+3, y+3, _cell_body_width-6, _cell_body_height-6);
			_cr.stroke();
		}
		else if (highlight)
		{
			_cr.set_line_width(2.0);
			Gdk.cairo_set_source_color(_cr, style.bg[ Gtk.StateType.SELECTED]);
			_cr.rectangle(x+1.5, y+1.5, _cell_body_width-3, _cell_body_height-3);
			_cr.stroke();
		}
	}

//======================================================================
	private void draw_grid()
	{//stdout.printf("In draw grid\n");
		double x1, x2, y1, y2;

		var _cr=Gdk.cairo_create(this.window);
		_cr.set_dash(Resource.MINORGRIDDASH,0.0);
		_cr.set_line_width(1.0);

		//Draw minor grid (dashed lines)
		x1=0;x2=_aw-1;
		for (int r=0; r<=_rows; r++)
		{
			y1=1.0+r*_ht;
			_cr.move_to(x1,y1);
			_cr.line_to(x2,y1);
			_cr.stroke();
		}
		y1=0; y2=_ah-1;
		for (int c=0; c<=_cols; c++)
		{
			x1=1.0+c*_wd;
			_cr.move_to(x1,y1);
			_cr.line_to(x1,y2);
			_cr.stroke();
		}
		//Draw major grid (solid lines)

		_cr.set_dash(null,0.0);
		_cr.set_line_width(1.0);

		x1=0;x2=_aw-1;
		for (int r=0; r<=_rows; r+=5)
		{
			y1=1+r*_ht;
			_cr.move_to(x1,y1);
			_cr.line_to(x2,y1);
			_cr.stroke();
		}
		y1=0; y2=_ah-1;
		for (int c=0; c<=_cols; c+=5)
		{
			x1=1+c*_wd;
			_cr.move_to(x1,y1);
			_cr.line_to(x1,y2);
			_cr.stroke();
		}
	}
//======================================================================
	private bool pointer_moved(Widget w, Gdk.EventMotion e)
	{
		int r= ((int) (e.y/_ah*_rows)).clamp(0,_rows-1);
		int c= ((int) (e.x/_aw*_cols)).clamp(0,_cols-1);
		cursor_moved(r,c); //signal connected to controller
		return true;
	}

	private bool leave_grid(Gdk.EventCrossing e)
	{
		if (e.x<0||e.y<0) //ignore false leave events that sometimes occur for unknown reason
		{
			cursor_moved(-1,-1);
		}
		return true;
	}
//=========================================================================

}
