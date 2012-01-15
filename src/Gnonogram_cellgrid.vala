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
	private int _current_row;
	private int _current_col;
	private double _aw;
	private double _ah;
	private double _wd;
	private double _ht;
	private double _cell_offset;
	private double _cell_body_width;
	private double _cell_body_height;
	//private Gdk.Color cr_color;
	private Gdk.Color grid_color;
	private Gdk.Color _bg_color;
	private Cairo.Context _cr;
	private Cairo.Pattern _filled_cell_pattern;
	private Cairo.Pattern _empty_cell_pattern;
	private Cairo.Pattern _unknown_cell_pattern;
	private Cairo.Pattern cell_pattern;

	private Cairo.Matrix pattern_matrix;

	public Gnonogram_CellGrid(int r, int c)
	{
		_rows=r;
		_cols=c;

		_current_col=-1;
		_current_row=-1;

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

		Gdk.Color.parse("BLACK", out grid_color);

	}

	public void resize(int r, int c)
	{
		_rows=r;_cols=c;
	}

	public void prepare_to_redraw_cells(GameState gs, bool show_grid)
	{	stdout.printf(@"In prepare to redraw , game state $gs\n");
		if (this.window==null) return;
		_cr=Gdk.cairo_create(this.window);
		_cr.set_antialias(Cairo.Antialias.NONE);
		_aw=(double)allocation.width;
		_ah=(double)allocation.height;
		_wd=(_aw-2)/(double)_cols;
		_ht=(_ah-2)/(double)_rows;
//		_bg_color=style.bg[Gtk.StateType.NORMAL];
		_bg_color=Resource.colors[gs,(int) CellState.UNKNOWN];
		window.clear();
		if (show_grid)
		{
			_cell_offset=Resource.CELLOFFSET_WITHGRID;
			draw_grid();
		}
		else _cell_offset=Resource.CELLOFFSET_NOGRID;

		_cell_body_width=_wd-_cell_offset;
		_cell_body_height=_ht-_cell_offset;
		_filled_cell_pattern=new Cairo.Pattern.radial(_wd*0.25, _ht*0.25, 0.0, _wd*0.5, _ht*0.5, _wd*0.5);
		_empty_cell_pattern=new Cairo.Pattern.radial(_wd*0.75, _ht*0.75, 0.0, _wd*0.5, _ht*0.5, _wd*0.5);
		_unknown_cell_pattern=new Cairo.Pattern.rgba(0.0,0.0,0.0,0.0);
		color_cell_pattern(_filled_cell_pattern,Resource.colors[gs,(int) CellState.FILLED]);
		color_cell_pattern(_empty_cell_pattern,Resource.colors[gs,(int) CellState.EMPTY],true);

	}

	private void color_cell_pattern(Cairo.Pattern cp, Gdk.Color cc, bool invert=false)
	{
			//double end = invert ? 1.0 : 0.0;
			double start = invert ? 0.0 : 1.0;
			cp.add_color_stop_rgba(0.0,start,start,start,1.0);
			add_color_stop_gdkcolor(cp,0.9,cc,1.0);
			cp.add_color_stop_rgba(1.0,0.0,0.0,0.0,0.0);
	}

	private void add_color_stop_gdkcolor(Cairo.Pattern cp, double offset, Gdk.Color cc, double alpha=1.0)
	{
		double red = (double)cc.red/65535.0;
		double green = (double)cc.green/65535.0;
		double blue = (double)cc.blue/65535.0;
		cp.add_color_stop_rgba(offset, red,green,blue,alpha);
	}

	public void draw_cell(Cell cell, bool highlight=false, bool mark=false)
//	public void draw_cell(Cell cell, GameState gs, bool highlight=false, bool mark=false)
	{	//stdout.printf(@"draw_cell cell $cell, gamestate $gs\n");
		_cr=Gdk.cairo_create(this.window);
		//don't draw cell outside grid.
		if (cell.row<0||cell.row>=_rows||cell.col<0||cell.col>=_cols)
		{
			return;
		}

		/* coords of top left corner of filled part
		/* (excluding grid if present but including highlight line)
		 */
		double x=cell.col*_wd +_cell_offset;
		double y= cell.row*_ht +_cell_offset;
		bool error=false;

		//erase_cell_body(_cr,x,y);

		switch (cell.state)
		{
			case CellState.EMPTY:
			case CellState.ERROR_EMPTY:
				cell_pattern=_empty_cell_pattern;
				break;
			case CellState.FILLED:
			case CellState.ERROR_FILLED:
				cell_pattern=_filled_cell_pattern;
				break;
//			case CellState.ERROR:
//				cr_color=Resource.colors[gs,(int) cell.state];
//				break;
//			case CellState.ERROR_EMPTY:
//				cr_color=Resource.colors[gs,(int) CellState.EMPTY];
//				error=true;
//				break;
//			case CellState.ERROR_FILLED:
//				cr_color=Resource.colors[gs,(int) CellState.FILLED];
//				error=true;
//				break;
			default :
				cell_pattern=_unknown_cell_pattern;
				//cr_color=_bg_color;
				break;
		}

//		if (cairo_source!=null) Gdk.cairo_set_source_pixbuf(_cr, cairo_source, x,y);
//		if (cell.state!=CellState.UNKNOWN && cell_pattern!=null)
//		{
//			cell_pattern.add_color_stop_rgb(0.0, 1.0,1.0,1.0);
//			cell_pattern.add_color_stop_rgb(0.3, cr_color.red,cr_color.green,cr_color.blue);
//			cell_pattern.add_color_stop_rgb(0.9, cr_color.red,cr_color.green,cr_color.blue);
//			cell_pattern.add_color_stop_rgba(1.0, _bg_color.red,_bg_color.green,_bg_color.blue,0.5);

			pattern_matrix=Cairo.Matrix.identity();
			pattern_matrix.translate(-x,-y);
			cell_pattern.set_matrix(pattern_matrix);
//			_cr.set_source(cell_pattern);
//		}
//		else
//		{
//			Gdk.cairo_set_source_color(_cr, cr_color);
//		}
		draw_cell_body(_cr, cell_pattern, x,y, highlight, error, mark);
	}

	private void erase_cell_body(Cairo.Context _cr, double x, double y)
	{
		_cr.set_line_width(0.5);
		Gdk.cairo_set_source_color(_cr, Resource.colors[0,(int) CellState.UNKNOWN]);
		_cr.rectangle(x, y, _cell_body_width, _cell_body_height);
		_cr.fill();
	}

	private void draw_cell_body(Cairo.Context _cr, Cairo.Pattern cp, double x, double y, bool highlight, bool error, bool mark)
	{

//		_cr.set_line_width(0.5);
////		Gdk.cairo_set_source_color(_cr, Resource.colors[0,(int) CellState.UNKNOWN]);

//		_cr.rectangle(x, y, _cell_body_width, _cell_body_height);
//		_cr.set_source_rgba(0.9,0.9,0.9,1.0);
//		_cr.fill_preserve();

				this.window.clear_area((int)x,(int)y, (int)_cell_body_width, (int)_cell_body_height);
		_cr.set_line_width(0.5);
		_cr.rectangle(x, y, _cell_body_width, _cell_body_height);
			_cr.set_source(cp);
		_cr.fill();


		if (mark)
		{
			_cr.set_line_width(0.5);
			Gdk.cairo_set_source_color(_cr, Resource.colors[0,(int) CellState.UNKNOWN]);
			_cr.rectangle(x+_cell_body_width/4, y+_cell_body_height/4, _cell_body_width/2, _cell_body_height/2);
			_cr.fill();
		}

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
			_cr.rectangle(x+1.5, y+1.5, _cell_body_width-3.5, _cell_body_height-3.5);
			_cr.stroke();
		}

	}


	private void draw_grid()
	{	//stdout.printf("In draw grid\n");
		double x1, x2, y1, y2;

		if (_cr==null) return;
		Gdk.cairo_set_source_color(_cr, grid_color);
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

	private bool pointer_moved(Widget w, Gdk.EventMotion e)
	{
		int r= ((int) (e.y/_ah*_rows)).clamp(0,_rows-1);
		int c= ((int) (e.x/_aw*_cols)).clamp(0,_cols-1);
		if(c!=_current_col||r!=_current_row)//only signal when cursor changes cell
		{
			cursor_moved(r,c); //signal connected to controller
		}
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
}
