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

//*****************************************************************************
namespace Utils
{
	public static string get_stripped_basename(string path, string? ext)
	{
			string bn=Path.get_basename(path);
			if ((ext!=null) && bn.has_suffix(ext))
				bn=bn[0:-ext.length];
			return bn;
	}
//**********************************************************************
	public static string get_string_response(string prompt)
	{
		var dialog = new Gtk.Dialog.with_buttons (
			null,
			null,
			Gtk.DialogFlags.MODAL|Gtk.DialogFlags.DESTROY_WITH_PARENT,
			_("Ok"), Gtk.ResponseType.OK,
			_("Cancel"), Gtk.ResponseType.CANCEL);
		var label=new Gtk.Label(prompt);
		var entry=new Gtk.Entry();
		dialog.vbox.add(label);
		dialog.vbox.add(entry);
		dialog.show_all();
		dialog.run();
		string fn=entry.text;
		dialog.destroy();
		return fn;
	}
//**********************************************************************

	public static string get_filename(FileChooserAction action, string dialogname, string[] filternames, string[] filters, string? start_path=null)
	{
		assert(filternames.length==filters.length);
		string button="Error";
		switch (action)
		{
			case FileChooserAction.OPEN:
				button=Stock.OPEN;
				break;

			case FileChooserAction.SAVE:
				button=Stock.SAVE;
				break;
			default :
				break;
		}
		var dialog=new Gtk.FileChooserDialog(
			dialogname,
			null,
			action,
			Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
			button, Gtk.ResponseType.ACCEPT,
			null);

		for (int i=0; i<filternames.length; i++)
		{
			var fc=new Gtk.FileFilter();
			fc.set_name(filternames[i]);
			fc.add_pattern(filters[i]);
			dialog.add_filter(fc);
		}
//		var all=new Gtk.FileFilter();
//		all.set_name(_("All files"));
//		all.add_pattern("*.*");
//		dialog.add_filter(all);
//		dialog.set_show_hidden(false);
		string temp_working_dir=null;
		
		if (start_path!=null)
		{
			var start=File.new_for_path(start_path);
			if (start.query_file_type(FileQueryInfoFlags.NONE,null)==FileType.DIRECTORY)
			{
				temp_working_dir=Environment.get_current_dir();
				Environment.set_current_dir(start_path);
			}
		}
		
		var response = dialog.run();
		string fn="";
		if (response!=ResponseType.CANCEL){
			fn=dialog.get_filename();
		}
		dialog.destroy();
		
		if (temp_working_dir!=null) {
			temp_working_dir=Environment.get_current_dir();
			Environment.set_current_dir(temp_working_dir);
		}
		
		return fn;
	}
	//*****************************************************************************
	public bool get_dimensions(out int r, out int c, int currentr=5, int currentc=5)
	{
		var dialog=new Gtk.Dialog.with_buttons(_("Adjust Size"),
			null,
			Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
			Stock.OK,
			Gtk.ResponseType.OK,
			Stock.CANCEL,
			Gtk.ResponseType.CANCEL
			);
		var hbox=new Gtk.HBox(true,6);
		
		var row_label=new Gtk.Label(_("Rows"));
		var row_spin=new Gtk.SpinButton.with_range(5,Resource.MAXROWSIZE,5);
		row_spin.set_value((double)currentr);
		
		var col_label=new Gtk.Label(_("Columns"));
		var col_spin=new Gtk.SpinButton.with_range(5,Resource.MAXCOLSIZE,5);
		col_spin.set_value((double)currentc);
		
		hbox.add(row_label); hbox.add(row_spin);	
		hbox.add(col_label); hbox.add(col_spin);
		
		dialog.vbox.add(hbox);
		dialog.set_default_response(Gtk.ResponseType.OK);
		dialog.show_all();

		bool success=false;
		var response=dialog.run();
		
		if (response==Gtk.ResponseType.OK) {
			r=int.max(5,row_spin.get_value_as_int());
			c=int.max(5,col_spin.get_value_as_int());
			success=true;
		}
		dialog.destroy();
		return success;
	}
	//*****************************************************************************
	public static  int show_dlg(string msg, Gtk.MessageType type, Gtk.ButtonsType buttons)
	{
		var dialog=new Gtk.MessageDialog(
			null,
			Gtk.DialogFlags.MODAL,
			type,
			buttons,
			"%s",msg);

		int response=dialog.run();
		dialog.destroy();
		return response;
	}
	//*****************************************************************************
	public static void show_info_dialog(string msg)
	{
		show_dlg(msg,Gtk.MessageType.INFO,Gtk.ButtonsType.CLOSE);
	}
	//*****************************************************************************
	public static void show_warning_dialog(string msg)
	{	
		show_dlg(msg,Gtk.MessageType.WARNING,Gtk.ButtonsType.CLOSE);
	}
	//*****************************************************************************
	public static bool show_confirm_dialog(string msg)
	{
		return show_dlg(msg,Gtk.MessageType.WARNING,Gtk.ButtonsType.YES_NO)==Gtk.ResponseType.YES;
	}
	//*****************************************************************************

	public static string[] remove_blank_lines(string[] sa)
	{
		string[] result = {};
		for (int i=0; i<sa.length; i++)
		{
			string s=sa[i].strip();
			if (s=="") continue;
			result+=s;
		}
		return result;
	}
	//*****************************************************************************
	public DataInputStream? open_datainputstream(string filename)
	{stdout.printf(@"opening $filename\n");

		DataInputStream stream;
		var file = File.new_for_path (filename);
	   if (!file.query_exists ())
	   {
		   stderr.printf ("File '%s' doesn't exist.\n", file.get_path ());
		   return null;
	   }

		try
		{
			stream= new DataInputStream(file.read());
		}
		catch (Error e) {Utils.show_warning_dialog(e.message); return null;}
		return stream;
	}
	//*****************************************************************************
	public CellState[] cellstate_array_from_string(string s)
	{
		CellState[] cs ={};
		string[] data=remove_blank_lines(s.split_set(", "));
		for (int i=0; i<data.length; i++) cs+=(CellState)(int.parse(data[i]));
		return cs;
	}
	//*****************************************************************************
	public string gnonogram_string_from_hex_string(string s, int pad_to_length=0)
	{
		
		StringBuilder sb= new StringBuilder(""); int count=0;
		for (int i=0; i<s.length; i++)
		{
			switch (s[i].toupper())
			{
				case '0':
					sb.append("1,1,1,1,");count+=4;break;
				case '1':
					sb.append("1,1,1,2,");count+=4;break;;
				case '2':
					sb.append("1,1,2,1,");count+=4;break;;
				case '3':
					sb.append("1,1,2,2,");count+=4;break;;
				case '4':
					sb.append("1,2,1,1,");count+=4;break;;
				case '5':
					sb.append("1,2,1,2,");count+=4;break;;
				case '6':
					sb.append("1,2,2,1,");count+=4;break;;
				case '7':
					sb.append("1,2,2,2,");count+=4;break;;
				case '8':
					sb.append("2,1,1,1,");count+=4;break;;
				case '9':
					sb.append("2,1,1,2,");count+=4;break;;
				case 'A':
					sb.append("2,1,2,1,");count+=4;break;;
				case 'B':
					sb.append("2,1,2,2,");count+=4;break;;
				case 'C':
					sb.append("2,2,1,1,");count+=4;break;;
				case 'D':
					sb.append("2,2,1,2,");count+=4;break;;
				case 'E':
					sb.append("2,2,2,1,");count+=4;break;;
				case 'F':
					sb.append("2,2,2,2,");count+=4;break;;
			}
		}

		if (pad_to_length>0)
		{
			if (count<pad_to_length)
			{
				for (int i=count; i<pad_to_length; i++)
				{
					sb.prepend("1,");
				}
			}
			else if (count>pad_to_length)
			{
				sb.erase(0,(count-pad_to_length)*2);
			}
		}

		return sb.str;
	}
	//*****************************************************************************
	public string string_from_cellstate_array(CellState[] cs)
	{//stdout.printf("string from cell_state_array\n");
		if (cs==null) return "";
		StringBuilder sb= new StringBuilder();
		for (int i=0; i<cs.length; i++)
		{
			sb.append(((int)cs[i]).to_string());
			sb.append(" ");
		}
		return sb.str;
	}
	//*****************************************************************************
	public string block_string_from_cellstate_array(CellState[] cs)
	{//stdout.printf("block string from cell_state_array\n");
		StringBuilder sb= new StringBuilder("");
		int count=0, blocks=0;
		bool counting=false;
		
		for (int i=0; i<cs.length; i++)
		{
			if (cs[i]==CellState.EMPTY)
			{
				if (counting)
				{
					sb.append(count.to_string()+Resource.BLOCKSEPARATOR);
					counting=false;
					count=0;
					blocks++;
				}
			}
			else
			{
				counting=true;
				count++;
			}
		}
		if (counting)
		{
			sb.append(count.to_string()+Resource.BLOCKSEPARATOR);
			blocks++;
		}
		if (blocks==0) sb.append("0"+Resource.BLOCKSEPARATOR);
		//stdout.printf("block string length %d\n", sb.str.length);
		return sb.str;
	}
	//*****************************************************************************
	public int[] block_array_from_clue(string s)
	{
		int[] blocks = {};
		string[] clues=remove_blank_lines(s.split_set(", "));
		for (int i=0;i<clues.length;i++)
		{
			blocks+=int.parse(clues[i]);
		}
		return blocks;
	}
}
