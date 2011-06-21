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

public class Gnonogram_filereader {

	public string filename;
	public int rows=0;
	public int cols=0;
	public string[] row_clues;
	public string[] col_clues;
	public string state;
	public string name="";
	public string author="";
	public string date="";
	public string score="";
	public bool in_error=false;
	public bool has_dimensions=false;
	public bool has_row_clues=false;
	public bool has_col_clues=false;
	public bool has_solution=false;
	public bool has_working=false;
	public bool has_state=false;
	public string[] solution;
	public string[] working;

	private DataInputStream stream;
	private bool is_game;
	private bool is_picto_game;
	private string[] headings;
	private string[] bodies;
	private string[] picto_grid_data;
//=========================================================================
	public Gnonogram_filereader(Gnonogram_FileType type, string fname="")
	{
		if (type==Gnonogram_FileType.GAME)
		{
			if(fname=="")	ask_filename();
			else filename=fname;

			if (filename.has_suffix(".pattern")) is_picto_game=true;
			else is_picto_game=false;

			is_game=true;
		}
		else
		{
			filename=Resource.game_dir + "/"+Resource.POSITIONFILENAME;
			is_game=false;
		}
	}
//=========================================================================
	public void ask_filename()
	{
			filename=Utils.get_filename(
			Gtk.FileChooserAction.OPEN,
			_("Choose a game"),
			{_("Gnonogram games"), _("Picto games")},
			{"*"+Resource.GAMEFILEEXTENSION, "*.pattern"},
			Resource.game_dir
			);
	}
//=========================================================================
	public bool open_datainputstream()
	{	stream= Utils.open_datainputstream(filename);
		if (stream==null) return false;
		else return true;
	}
//=========================================================================
	public bool parse_game_file()
	{
		if (is_picto_game) return parse_picto_game_file();
		else return parse_gnonogram_game_file();
	}
//=========================================================================
	private bool parse_gnonogram_game_file()
	{
		size_t headerlength, bodylength;
		try
		{
			stream.read_until("[", out headerlength);
			while (true)
			{
				headings += stream.read_until("]", out headerlength);
				bodies += stream.read_until("[", out bodylength);
				if (headerlength==0 || bodylength==0) break;
			}
		}
		catch (Error e) {Utils.show_warning_dialog(e.message); return false;}
		return parse_gnonogram_headings_and_bodies();
	}
//=========================================================================
	private bool parse_picto_game_file()
	{ //assume format of file, e.g. number and order of lines, strictly fixed
		string line; size_t length;
		try
		{
			for (int i=0; i<5; i++) //description lines
			{
				line=stream.read_line(out length);
				string[] s = line.split(":");
				headings += s[0].strip();
				if (s[1].strip()=="") bodies+=_("Unknown");
				else 	bodies += s[1].strip();
			}

			line=stream.read_line(out length);//blank separator line

			while (line!=null) //pattern lines
			{
				line=line.chomp().strip();
				if (line!=null) picto_grid_data+=line;
				line=stream.read_line(out length);
			}
		}
		catch (Error e) {Utils.show_warning_dialog(e.message); return false;}

		return get_game_description(bodies[0]+"\n"+bodies[1]+"\n"+bodies[2]) &&
				get_picto_dimensions(bodies[3],true) &&
				get_picto_dimensions(bodies[4],false) &&
				parse_picto_grid_data();
	}
//=========================================================================
	private bool parse_gnonogram_headings_and_bodies()
	{
		int n=headings.length;

		for (int i=0;i<n;i++)
		{
			string heading=headings[i];
			if (heading==null) continue;
			if (heading.length>3) heading=heading.slice(0,3);
			switch (heading.up())
			{
				case "DIM" :
					in_error=!get_gnonogram_dimensions(bodies[i]); break;
				case "ROW" :
					in_error=!get_gnonogram_clues(bodies[i],false); break;
				case "COL" :
					in_error=!get_gnonogram_clues(bodies[i],true); break;
				case "SOL" :
					in_error=!get_gnonogram_cellstate_array(bodies[i],true); break;
				case "WOR" :
					in_error=!get_gnonogram_cellstate_array(bodies[i],false); break;
				case "STA" :
					in_error=!get_gnonogram_state(bodies[i]); break;
				case "DES" :
					in_error=!get_game_description(bodies[i]); break;
				default :
					Utils.show_warning_dialog(@"Unrecognised heading $heading ");
					in_error=true;
					break;
			}
			if (in_error) return false;
		}
		return true;
	}
//=========================================================================
	private bool get_gnonogram_dimensions(string? body)
	{	//stdout.printf("In get_dimensions\n");
		if (body==null) return false;
		string[] s = Utils.remove_blank_lines(body.split("\n"));
		if (s.length!=2)
		{
			Utils.show_warning_dialog(_("Wrong number of dimensions"));
			return false;
		}
		rows=int.parse(s[0]);
		cols=int.parse(s[1]);
		has_dimensions=true;
		return (rows>0 && cols>0);
	}
//=========================================================================
	private bool get_picto_dimensions(string? body, bool is_column)
	{	//stdout.printf("In get_dimensions\n");
		if (body==null) return false;
		int dim = int.parse(body);
		if (is_column) cols=dim;
		else rows=dim;
		has_dimensions=(rows>0 && cols>0);
		return (dim>0);
	}
//=========================================================================
	private bool get_gnonogram_clues(string? body, bool is_column)
	{//stdout.printf("In get_clues\n");
		string[] arr={};
		if (body==null) return false;
		string[] s = Utils.remove_blank_lines(body.split("\n"));

		if (s==null||s.length<1) return false;
		for (int i=0; i< s.length; i++)
		{
			arr+=parse_gnonogram_clue(s[i]);
		}
		if (is_column)
		{
			if (arr.length!=cols) return false;
			col_clues=arr;
			has_col_clues=true;
		}
		else
		{
			if (arr.length!=rows) return false;
			row_clues=arr;
			has_row_clues=true;
		}
		return true;
	}
//=========================================================================
	private bool get_gnonogram_cellstate_array(string? body, bool is_solution)
	{//stdout.printf("In get_cellstate array\n");
		if (body==null) return false;
		string[] s = Utils.remove_blank_lines(body.split("\n"));
		if (s==null||s.length!=rows) return false;

		for (int i=0; i<s.length;i++)
		{
			//stdout.printf(@"s[$i] $(s[i])\n");
			CellState[] arr = Utils.cellstate_array_from_string(s[i]);
			if (arr.length!=cols) return false;
		}
		if (is_solution)
		{
			solution=s;
			has_solution=true;
		}
		else
		{
			working=s;
			has_working=true;
		}
		return true;
	}
//=========================================================================
	private bool parse_picto_grid_data()
	{//stdout.printf("In parse grid data\n");
		if (picto_grid_data==null) return false;
		picto_grid_data=Utils.remove_blank_lines(picto_grid_data);
		if (picto_grid_data==null||picto_grid_data.length!=rows) return false;
		solution = new string[rows];
		for (int i=0; i<rows;i++)
		{
			string arr = Utils.gnonogram_string_from_hex_string(picto_grid_data[i], cols);
			solution[i]=arr;
		}
		has_solution=true;

		return true;
	}
//=========================================================================
	private bool get_gnonogram_state(string? body)
	{  //stdout.printf("In get_state\n");
		if (body==null) return false;
		string[] s = Utils.remove_blank_lines(body.split("\n"));
		if (s==null||s.length<1) return false;
		state=s[0];
		has_state=true;
		return true;
	}
//=========================================================================
	private bool get_game_description(string? body)
	{  //stdout.printf("In get_description\n");
		if (body==null) return false;
		string[] s = Utils.remove_blank_lines(body.split("\n"));

		if (s.length>=1) name=Utils.convert_html(s[0]);
		if (s.length>=2) author=Utils.convert_html(s[1]);
		if (s.length>=3) date=s[2];
		if (s.length>=4) score=s[3];

		return true;
	}
//=========================================================================
	private string parse_gnonogram_clue(string line)
	{
		string[] s=Utils.remove_blank_lines(line.split_set(", "));
		int b, zero_count=0;

		if (s==null) return "";
		StringBuilder sb=new StringBuilder();
		for (int i=0; i<s.length; i++)
		{
			// ignore extraneous non-digits (allow one zero)
			b=int.parse(s[i]);
			if (b==0 && zero_count>0) continue;
			else zero_count++;

			sb.append(s[i]+Resource.BLOCKSEPARATOR);
		}
		sb.truncate(sb.len-1);
		return sb.str;
	}
}
