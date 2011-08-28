/* Configuration client for Gnonograms
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

//This class stands in for GConf client, using conventional text file in user config directory instead.
//Provides same interface so rest of program unchanged
//ONly implements parts of GConf needed for Gnonograms

public class Gnonogram_conf_client {

	public Gnonogram_conf_client(string conf_dir)
	{stdout.printf("Gnonogram_conf_client dir %s\n",conf_dir);
		//Open config file in conf_dir
		//Create new file if does not exist
		//Read in headers and bodies?
	}

	public string? @get(string path)
	{stdout.printf("Gnonogram_conf_client get path %s\n",path);
	//Takes a GConf path and extracts header and key
	//Checks whether exists, if not returns null
	// If exists returns value as string
		string header, key;
		if (parse_path(path, out header, out key))
		{
			stdout.printf("Header %s,  Key %s\n",header, key);
			//return "Value string";  TODO implement extraction of value string from config file
		}
		else
		{

		}
		return null;

	}

	public bool set_int(string path, int val)
	{stdout.printf("Gnonogram_conf_client set int path %s val %d\n",path,val);
		//Creates header and key from path if do not exist
		//associates value with key
		//return true for success else throws error
		return true;
	}
	public bool set_string(string path, string val)
	{stdout.printf("Gnonogram_conf_client set string path %s val %s\n",path,val);
		//Creates header and key from path if do not exist
		//associates value with key
		//return true for success else throws error
		return false;
	}
	public bool set_boolean(string path, bool val)
	{stdout.printf("Gnonogram_conf_client set bool path %s, val %s\n",path,val.to_string());
		//Creates header and key from path if do not exist
		//associates value with key
		//return true for success else throws error
		return true;
	}
	public int get_int(string path)
	{stdout.printf("Gnonogram_conf_client get int path %s\n",path);
		//Creates header and key from path if do not exist
		//associates value with key
		return 0;
	}
	public string get_string(string path)
	{stdout.printf("Gnonogram_conf_client get string path %s\n",path);
		//Creates header and key from path if do not exist
		//associates value with key
		return "";
	}
	public bool get_boolean(string path)
	{stdout.printf("Gnonogram_conf_client get bool path %s\n",path);
		//Creates header and key from path if do not exist
		//associates value with key
		return false;
	}

	private bool parse_path(string path, out string header, out string key)
	{stdout.printf("Gnonogram_conf_client parse path path %s\n",path);
		string [] nodes=path.split("/");
		int no_nodes=nodes.length;
		stdout.printf("number of nodes %d\n",no_nodes);

		if (no_nodes<4) return false;

		if (((nodes[no_nodes-4].up())!="GNONOGRAM") || ((nodes[no_nodes-3].up())!="PREFERENCES")) return false;
		header=nodes[no_nodes-2].up();
		key=nodes[no_nodes-1].up();
		stdout.printf("Header %s, Key %s\n",header,key);
		return true;
	}

}
