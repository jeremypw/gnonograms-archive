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
	private const string PATHS_CONF="/apps/gnonograms/preferences/paths/";
	private const string UI_CONF="/apps/gnonograms/preferences/ui/";
	private static Config instance=null;
	private GConf.Client client;

	public static Config get_instance() {
		if (instance==null) instance=new Config();
		assert(instance!=null);
		return instance;
	}

	private Config() {
		assert(instance==null);
		client=GConf.Client.get_default();
		assert(client!=null);
	}

    private void report_get_error(string path, Error err) {
        stdout.printf(_("Unable to get GConf value")+@" $path: $(err.message)");
    }
    private void report_set_error(string path, Error err) {
        stdout.printf(_("Unable to set GConf value")+@" $path: $(err.message)");
    }


/**	private bool get_bool(string path, bool def) {
       try {
            if (client.get(path) == null) {
				client.set_bool(path,def);
                return def;
			}
            return client.get_bool(path);
        } catch (Error err) {
            report_get_error(path, err);

        return def;
        }
	}
	private bool set_bool(string path, bool value) {
       try {
           client.set_bool(path,value);
           return true;
        } catch (Error err) {
            report_set_error(path, err);
            return false;
        }
	}
**/
	private int get_int(string path, int def) {
       try {
            if (client.get(path) == null) {
				client.set_int(path,def);
                return def;
            }
            return client.get_int(path);
        } catch (Error err) {
            report_get_error(path, err);

            return def;
        }
	}
	private bool set_int(string path, int value) {
       try {
           client.set_int(path,value);
           return true;
        } catch (Error err) {
            report_set_error(path, err);
            return false;
        }
	}
	private string get_string(string path, string def) {
       try {
            if (client.get(path) == null) {
				client.set_string(path,def);
                return def;
			}
            return client.get_string(path);
        } catch (Error err) {
            report_get_error(path, err);

        return def;
        }
	}
	private bool set_string(string path, string value) {
       try {
           client.set_string(path,value);
           return true;
        } catch (Error err) {
            report_set_error(path, err);
            return false;
        }
	}

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
		return (double)get_int(UI_CONF+"difficulty",Resource.DEFAULT_DIFFICULTY);
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
		r=get_int(UI_CONF+"rows",Resource.DEFAULT_ROWS);
		c=get_int(UI_CONF+"cols",Resource.DEFAULT_COLS);
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

	public void set_font(string font_descr)
	{
		set_string(UI_CONF+"font_description",font_descr);
	}

	public string get_font()
	{
		return get_string(UI_CONF+"font_description",Resource.DEFAULT_FONT);
	}
}
