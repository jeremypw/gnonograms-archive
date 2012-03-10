/* Label class for Gnonograms3
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

class Gnonogram_label : Gtk.EventBox
{
	private Gtk.Label l;
	private string attrib_start;
	private string attrib_end;
	private string clue;
	private int blockextent;
	private int size;

	public Gnonogram_label(string label_text, bool is_column)
	{
		l=new Gtk.Label(label_text);
		l.has_tooltip=true;

		if (is_column)
		{
			l.set_angle(270);
			l.set_alignment((float)0.5,(float)1.0);
		}
		else
		{
			l.set_alignment((float)1.0, (float)0.5);
		}
		add(l);
	}

	public void highlight(bool is_highlight)
	{
		if (is_highlight) set_state(Gtk.StateType.SELECTED);
		else set_state(Gtk.StateType.NORMAL);
	}

	public void set_markup(string start, string text, string end)
	{
		attrib_start=start; attrib_end=end; clue=text;
		l.set_markup(attrib_start+clue+attrib_end);
		blockextent=Utils.blockextent_from_clue(clue);
	}

	public void set_size(int s)
	{
		size=s;
		l.set_tooltip_markup(attrib_start+ _("Freedom=")+(size-blockextent).to_string()+attrib_end);
	}

	public string get_text()
	{
		return l.get_text();
	}
}
