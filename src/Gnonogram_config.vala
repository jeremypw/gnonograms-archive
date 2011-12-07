/* Configuration class for Gnonograms
 * Copyright (C) 2010-2011  Jeremy Wootten
 * based on the LGPL work of the Yorba Foundation 2009
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
public class Config {

	private const string PATHS_HEADER="PATHS";
	private const string UI_HEADER="UI";
	private static Config instance=null;
	private Gnonogram_conf_client client;

	public static Config get_instance()
	{
		if (instance==null) instance=new Config();
		assert(instance!=null);
		return instance;
	}
//=====================================================================
//PRIVATE METHODS - provide different mechanisms of storage
//=====================================================================
	private Config()
	{
		assert(instance==null);
		client=new Gnonogram_conf_client();
		assert(client!=null);
		if (!client.valid) stdout.printf("Client is not valid\n");
	}

	private int get_int(string header, string key, int def)
	{
            if (get_value_string(header,key) == null)
            {
				set_value_string(header,key,def.to_string());
                return def;
            }
            return int.parse(get_value_string(header, key));
	}

	private bool get_bool(string header, string key, bool def)
	{
            if (get_value_string(header,key) == null)
            {
				set_value_string(header,key,def.to_string());
                return def;
            }
            return bool.parse(get_value_string(header, key));
	}

	private string get_string(string header, string key, string def)
	{
            if (get_value_string(header,key) == null)
            {
				set_value_string(header,key,def.to_string());
                return def;
            }
            return (get_value_string(header, key)).to_string();
	}

	private bool set_int(string header, string key, int ivalue)
	{
           return set_value_string(header, key, ivalue.to_string());
	}
	private bool set_bool(string header, string key, bool bvalue)
	{
           return set_value_string(header, key, bvalue.to_string());
	}

	private bool set_string(string header, string key, string svalue)
	{
           return set_value_string(header, key, svalue);
	}

	private string? get_value_string(string header, string key)
	{
		string svalue;
		if (client.valid) svalue = client.get_value(header, key);
		else svalue=null;

		return svalue;
	}
	private bool set_value_string(string header, string key, string svalue)
	{
		if (client.valid){
			client.set_value(header, key, svalue);
			client.write_config_file();
			return true;
		}
		else return false;
	}
	private bool set_dir(string key, string path)
	{
		File dir=File.new_for_path(path);
		if (dir.query_exists(null) && dir.query_file_type(0,null)==FileType.DIRECTORY)	{
			return set_string(PATHS_HEADER, key, path);
		}
		else {
			Utils.show_warning_dialog(_("Path %s does not exist or is not a directory").printf(path));
			return false;
		}
	}
	private string get_dir(string key,string defaultdir)
	{
		string data_path=get_string(PATHS_HEADER,key,defaultdir);
		File dir = File.new_for_path(data_path);
		if (dir.query_exists(null) && dir.query_file_type(0,null)==FileType.DIRECTORY){
			return data_path;
		}
		else{
			return defaultdir;
		}
	}
//====================================================================
//PUBLIC METHODS - maintain for compatability with the GConf version
//=====================================================================

	public bool set_save_game_dir(string path)
	{
		return set_dir("save_game_dir",path);
	}
	public bool set_load_game_dir(string path)
	{
		return set_dir("load_game_dir",path);
	}


	public string get_save_game_dir(string defaultdir)
	{
		return get_dir("save_game_dir", defaultdir);
	}
	public string get_load_game_dir(string defaultdir)
	{
		return get_dir("load_game_dir", defaultdir);
	}

 	public bool set_game_name(string name)
 	{
		return set_string(PATHS_HEADER, "game_name", name);
	}

	public string get_game_name(string defaultname)
	{
		return get_string(PATHS_HEADER, "game_name", defaultname);
	}

	public double get_difficulty()
	{
		return (double)get_int(UI_HEADER, "difficulty",Resource.DEFAULT_DIFFICULTY);
	}

	public void set_difficulty(double difficulty)
	{
		set_int(UI_HEADER, "difficulty",(int)difficulty);
	}

	public void set_dimensions(int r, int c)
	{
		set_int(UI_HEADER, "rows",r);
		set_int (UI_HEADER, "cols",c);
	}

	public void get_dimensions(out int r, out int c)
	{
		r=get_int(UI_HEADER, "rows",Resource.DEFAULT_ROWS);
		c=get_int(UI_HEADER, "cols",Resource.DEFAULT_COLS);
	}

	public void set_colors()
	{	//stdout.printf("Config set colors\n");
		set_string(UI_HEADER, "setting_empty",Resource.colors[(int) GameState.SETTING, (int) CellState.EMPTY].to_string());
		set_string(UI_HEADER, "setting_filled",Resource.colors[(int) GameState.SETTING, (int) CellState.FILLED].to_string());
		set_string(UI_HEADER, "solving_empty",Resource.colors[(int) GameState.SOLVING, (int) CellState.EMPTY].to_string());
		set_string(UI_HEADER, "solving_filled",Resource.colors[(int) GameState.SOLVING, (int) CellState.FILLED].to_string());

	}

		public string[] get_colors()
	{	//stdout.printf("Config get colors\n");
		string set_empty=get_string(UI_HEADER, "setting_empty",Resource.colors[(int) GameState.SETTING, (int) CellState.EMPTY].to_string());
		string set_filled=get_string(UI_HEADER, "setting_filled",Resource.colors[(int) GameState.SETTING, (int) CellState.FILLED].to_string());
		string solve_empty=get_string(UI_HEADER, "solving_empty",Resource.colors[(int) GameState.SOLVING, (int) CellState.EMPTY].to_string());
		string solve_filled=get_string(UI_HEADER, "solving_filled",Resource.colors[(int) GameState.SOLVING, (int) CellState.FILLED].to_string());

		return {set_empty,set_filled,solve_empty,solve_filled};

	}

	public void set_font(string font_desc)
	{
		set_string(UI_HEADER,"font description",font_desc);
	}
	public string get_font()
	{
		return get_string(UI_HEADER,"font description",Resource.DEFAULT_FONT);
	}

	public void set_use_advanced_solver(bool use)
	{
		set_bool(UI_HEADER,"use advanced solver",use);
	}
	public bool get_use_advanced_solver()
	{
		return get_bool(UI_HEADER,"use advanced solver",Resource.DEFAULT_ADVANCEDSOLVER);
	}
	public void set_generate_advanced_puzzles(bool generate)
	{
		set_bool(UI_HEADER,"generate advanced puzzles",generate);
	}
	public bool get_generate_advanced_puzzles()
	{
		return get_bool(UI_HEADER,"generate advanced puzzles",Resource.DEFAULT_ADVANCEDPUZZLES);
	}
	public void set_show_grid(bool show)
	{
		set_bool(UI_HEADER,"show grid",show);
	}
	public bool get_show_grid()
	{
		return get_bool(UI_HEADER,"show grid",Resource.DEFAULT_SHOWGRID);
	}
	public void set_toolbar_visible(bool visible)
	{
		set_bool(UI_HEADER,"toolbar visible",visible);
	}
	public bool get_toolbar_visible()
	{
		return get_bool(UI_HEADER,"toolbar visible",Resource.DEFAULT_SHOWTOOLBAR);
	}
	public void set_incur_time_penalty(bool incur)
	{
		set_bool(UI_HEADER,"time penalty incurred",incur);
	}
	public bool get_incur_time_penalty()
	{
		return get_bool(UI_HEADER,"time penalty incurred",Resource.DEFAULT_INCURTIMEPENALTY);
	}
}
