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
using GLib;

	public class Gnonogram_conf_client {
	private string[] headings;
	private string[] bodies;
	private string[] keys;
	private string[] values;
	private File conf_file;

	public bool valid;

	public Gnonogram_conf_client()
	{	//stdout.printf("Gnonogram_conf_client\n");
		//Open config file in conf_dir
		valid=false;
		try
		{
			string conf_dir_filename=Path.build_filename(Environment.get_user_config_dir(),"gnonograms",null);
			var conf_dir=File.new_for_path(conf_dir_filename);
			if (!conf_dir.query_exists(null)||!(conf_dir.query_file_type(FileQueryInfoFlags.NONE,null)==FileType.DIRECTORY))
			{
				conf_dir.make_directory(null);
				if (conf_dir.query_exists(null))
				{stdout.printf("Created gnonograms directory %s\n", conf_dir_filename);
				}
				else
				{
					stdout.printf("Failed to create gnonograms directory\n");
					return;
				}
			}
			conf_file=conf_dir.get_child("gnonograms.conf");
			if (!conf_file.query_exists(null))
			{
				conf_file.create(FileCreateFlags.NONE, null);
				if (!conf_file.query_exists(null))
				{
					stdout.printf("Failed to create gnonograms config file\n");
					return;
				}
			}
			var stream=new DataInputStream(conf_file.read());
			if (stream==null)
			{
				stdout.printf("Failed to open config file for reading\n");
				return;
			}
			else
			{
				if (!parse_gnonogram_config_file(stream)) return;
			}
		}
		catch (Error e)
		{
			stdout.printf("GLib Error %s\n",e.message);
			valid=false;
			return;
		}
		valid=true;
	}

	public string? get_value(string header, string key)
	{	//stdout.printf("get_value header %s  key %s\n",header,key);
		if (this.valid)
		{
			string k=header.strip()+"."+key.strip();

			for (int i=0;i<keys.length;i++)
			{
				if (keys[i]==k)
				{
					return values[i];
				}
			}
		}
		return null;
	}

	public void set_value(string header, string key, string svalue)
	{	//stdout.printf("set_value header %s  key %s value %s\n",header,key,svalue);
		if (this.valid)
		{
			string k=header.strip()+"."+key.strip();
			for (int i=0;i<keys.length;i++)
			{
				if (keys[i]==k)
				{
					values[i]=svalue.strip();
					return;
				}
			}
			keys+=k;
			values+=svalue.strip();
			bool found=false;
			for (int i=0; i<headings.length;i++)
			{
				if (headings[i]==header)
				{
					found=true;break;
				}
			}
			if (!found)
			{
				headings+=header;
			}
		}
	}

	private bool parse_gnonogram_config_file(DataInputStream stream)
	{	//stdout.printf("parse config file \n");
		size_t headerlength, bodylength;
		string h;
		string b;
		int count=-1;
		try
		{
			stream.read_until("[", out headerlength, null);
			while (true)
			{
				h= stream.read_until("]", out headerlength, null);
				b= stream.read_until("[", out bodylength, null);
				if (headerlength==0) break;
				headings+=h; bodies+=b;
				count++;
			}
		}
		catch (Error e) {stdout.printf("GLib error"+e.message+"\n");return false;}

		return parse_gnonogram_config_headings_and_bodies();
	}

	private bool parse_gnonogram_config_headings_and_bodies()
	{	//stdout.printf("parse config file headings and bodies \n");
		int n=headings.length;
		for (int i=0;i<n;i++)
		{
			string heading=headings[i];
			if (heading==null) continue;
			extract_key_values(heading,bodies[i]);
		}
		return true;
	}

	private void extract_key_values(string heading, string body)
	{	//stdout.printf("extract key values \n");
		string[] key_values=Utils.remove_blank_lines(body.split("\n"));
		for (int i=0;i<key_values.length;i++)
		{
			string[] kv = key_values[i].split("=");
			keys+=heading+"."+kv[0].strip().replace(" ","_"); //correct old keys
			values+=kv[1].strip();
		}
	}

	public void write_config_file()
	{	//stdout.printf("write config file \n");
		try
		{
			conf_file.delete(null);
			var dos=new DataOutputStream(conf_file.create (FileCreateFlags.REPLACE_DESTINATION, null));
			for (int i=0;i<headings.length;i++)
			{
				string h=headings[i];
				dos.put_string("["+h+"]\n");
				for (int j=0;j<keys.length;j++)
				{
					string[] k= keys[j].split(".");
					if (k[0]==h)
					{
						dos.put_string(k[1]+"="+values[j]+"\n");
					}
				}
			}

		}
		catch (Error e) {stdout.printf("Glib Error %s\n",e.message);}
	}
}
