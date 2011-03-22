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

public class Gnonogram_LabelBox : Frame {
	private bool _is_column; //true if contains column labels(i.e. HBox)
	private int _size; //no of labels in box
	private int _other_size; //possible length of label text (size of other box)
	private Gnonogram_label[] _labels;
	private Container _box;
	private string _attribstart;
	private string _attribend;
	private double _fontheight;
//======================================================================
	public Gnonogram_LabelBox(int size, int other_size, bool is_col)
	{
		_is_column=is_col; 
		this.set_shadow_type(Gtk.ShadowType.NONE);
	
		if (_is_column)
		{
			 _box = new HBox(true,0) as Container;
			 _labels=new Gnonogram_label[Resource.MAXCOLSIZE];
		}
		else
		{
			_box = new VBox(true,0) as Container;
			_labels=new Gnonogram_label[Resource.MAXROWSIZE];
		}

		for (var i=0;i<_labels.length;i++)
		{
			Gnonogram_label l=new Gnonogram_label("", is_col);
			_labels[i]=l;
		}
		set_all_blank();
		_size=0;
		resize(size, other_size);
		add(_box);
	}
//======================================================================
	public void resize(int new_size, int other_size)
	{
		unhighlight_all();
		if (new_size!=_size)
		{
			int diff=(new_size-_size);
			
			if (diff>0)	for (int i=_size; i<_size+diff; i++)	_box.add(_labels[i]);
			else	for (int i=0; i>diff; i--) remove_label();
			
			_size=new_size;
		}
		_other_size=other_size;
		set_default_fontheight(_size, _other_size);
		set_attribs(_fontheight);
//		set_all_zero();
	}
//======================================================================
	public void change_font_height(bool increase)
	{
		if (increase) _fontheight+=1.0;
		else _fontheight-=1.0;
		set_attribs(_fontheight);
		for (int i=0; i<_size;i++) update_label(i,get_label_text(i));
	}
//======================================================================
	public void highlight(int idx, bool is_highlight)
	{
		if (idx>=_size) return;
		_labels[idx].highlight(is_highlight);
	}
//======================================================================
	public void update_label(int idx, string txt)
	{	//stdout.printf("Label txt length %d\n",txt.length);
		_labels[idx].set_markup(_attribstart+txt+_attribend);
	}
//======================================================================
	public string get_label_text(int idx)
	{
		return _labels[idx].get_text();
	}
//======================================================================
	public string to_string()
	{
		StringBuilder sb=new StringBuilder();
		
		for (int i=0; i<_size;i++)
		{
			sb.append(get_label_text(i));
			sb.append("\n");
		}
		//stdout.printf(@"$(sb.str)\n");
		return sb.str;
	}
//======================================================================
	private void set_attribs(double fontheight)
	{
		 int fontsize=1024*(int)(fontheight);
		_attribstart=@"<span font_desc='Impact' weight='light' size='$fontsize'>";
		_attribend="</span>";
	}
//======================================================================
	private void set_default_fontheight(int size, int other_size)
	{
		_fontheight=32.0-(double)(int.max(size, other_size));
		_fontheight=_fontheight.clamp(Resource.MINFONTSIZE, Resource.MAXFONTSIZE);
	}
//======================================================================
	private void remove_label()
	{
		GLib.List<weak Gtk.Widget> l=_box.get_children();
		_box.remove(l.nth_data((uint)l.length()-1));
	}

//======================================================================
	private void unhighlight_all()
	{
		for (int i=0;i<_size;i++) {highlight(i,false);}
	}
//======================================================================
	private void set_all_blank()
	{
		for (var i=0;i<_size;i++)
		{
			_labels[i].set_markup(_attribstart+""+_attribend);
		}
	}
}
