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

	private const string PATHS_CONF="/apps/gnonogram/preferences/paths/";
	private const string UI_CONF="/apps/gnonogram/preferences/ui/";
	private static Config instance=null;
	private Gnonogram_conf_client client;

	public static Config get_instance() {
		if (instance==null) instance=new Config();
		assert(instance!=null);
		stdout.printf("Instance created\n");
		return instance;
	}

//====================================================================
//PRIVATE METHODS - provide different mechanisms of storage
//=====================================================================
	private Config() {
		assert(instance==null);
		client=new Gnonogram_conf_client(Environment.get_user_config_dir()+"/gnonograms");
		assert(client!=null);
		stdout.printf("Client created\n");
	}

	private int get_int(string path, int def) {
            if (client.get(path) == null) {
				client.set_int(path,def);
                return def;
            }
            return client.get_int(path);
	}
	private bool set_int(string path, int value) {
           client.set_int(path,value);
           return true;
	}
	private string get_string(string path, string def) {
            if (client.get(path) == null) {
				client.set_string(path,def);
                return def;
			}
            return client.get_string(path);
	}
	private bool set_string(string path, string value) {
           client.set_string(path,value);
           return true;
	}

//====================================================================
//PUBLIC METHODS - maintain for compatability with the GConf version
//=====================================================================

	public bool set_game_dir(string path)
	{
		File game_dir=File.new_for_path(path);

		if (game_dir.query_exists(null) && game_dir.query_file_type(0,null)==FileType.DIRECTORY)
		{
			return set_string(PATHS_CONF+"game_dir", path);
		}else
		{
			Utils.show_warning_dialog(_("Path given does not exist or is not a directory"));
			return false;
		}
	}

	public string get_game_dir(string defaultdir)
	{
		string data_path=get_string(PATHS_CONF+"game_dir",defaultdir);
		File game_dir = File.new_for_path(data_path);
		if (game_dir.query_exists(null) && game_dir.query_file_type(0,null)==FileType.DIRECTORY)
		{
			return data_path;
		}else
		{
			return defaultdir;
		}
	}

 	public bool set_game_name(string name)
 	{
		return set_string(PATHS_CONF+"game_name", name);
	}

	public string get_game_name(string defaultname)
	{
		return get_string(PATHS_CONF+"game_name", defaultname);
	}

	public double get_difficulty()
	{
		return (double)get_int(UI_CONF+"difficulty",5);
	}

	public void set_difficulty(double difficulty) {
		set_int(UI_CONF+"difficulty",(int)difficulty);
	}

	public void set_dimensions(int r, int c)
	{
		set_int(UI_CONF+"rows",r);
		set_int (UI_CONF+"cols",c);
	}

	public void get_dimensions(out int r, out int c)
	{
		r=get_int(UI_CONF+"rows",10);
		c=get_int(UI_CONF+"cols",10);
	}

	public void set_colors()
	{
		set_string(UI_CONF+"setting_empty",Resource.colors[(int) GameState.SETTING, (int) CellState.EMPTY].to_string());
		set_string(UI_CONF+"setting_filled",Resource.colors[(int) GameState.SETTING, (int) CellState.FILLED].to_string());
		set_string(UI_CONF+"solving_empty",Resource.colors[(int) GameState.SOLVING, (int) CellState.EMPTY].to_string());
		set_string(UI_CONF+"solving_filled",Resource.colors[(int) GameState.SOLVING, (int) CellState.FILLED].to_string());

	}

		public string[] get_colors()
	{
		string set_empty=get_string(UI_CONF+"setting_empty",Resource.colors[(int) GameState.SETTING, (int) CellState.EMPTY].to_string());
		string set_filled=get_string(UI_CONF+"setting_filled",Resource.colors[(int) GameState.SETTING, (int) CellState.FILLED].to_string());
		string solve_empty=get_string(UI_CONF+"solving_empty",Resource.colors[(int) GameState.SOLVING, (int) CellState.EMPTY].to_string());
		string solve_filled=get_string(UI_CONF+"solving_filled",Resource.colors[(int) GameState.SOLVING, (int) CellState.FILLED].to_string());

		return {set_empty,set_filled,solve_empty,solve_filled};

	}
}
