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

//class Gnonogram_label : Gtk.Frame {
class Gnonogram_label : Gtk.EventBox {
//	private Gtk.EventBox e; //this allows the label to be highlighted
	private Gtk.Label l;

	public Gnonogram_label(string label_text, bool is_column)
	{
//		set_shadow_type(Gtk.ShadowType.NONE);
//		e=new EventBox();
		l=new Gtk.Label(label_text);

		if (is_column)
		{
			l.set_angle(270);
			l.set_alignment((float)0.0, (float)1.0);
			l.set_padding(0,5);
		}
		else
		{
			l.set_alignment((float)1.0, (float)1.0);
			l.set_padding(5,0);
		}
//		e.add(l);
//		add(e);
		add(l);
	}

	public void highlight(bool is_highlight)
	{
		if (is_highlight) set_state(Gtk.StateType.SELECTED);
		else set_state(Gtk.StateType.NORMAL);
	}
	
	public void set_markup(string m) {l.set_markup(m);}

	public string get_text() {return l.get_text();}
}
