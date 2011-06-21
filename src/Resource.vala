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
using Gdk;

// Defined by configure and make
extern const string _PREFIX;
extern const string _VERSION;
extern const string GETTEXT_PACKAGE;

namespace Resource
{
	public const string APP_GETTEXT_PACKAGE = GETTEXT_PACKAGE;
	public const string DEFAULTGAMENAME = "New game";
	public const string GAMEFILEEXTENSION=".gno";
	public const string POSITIONFILENAME="currentposition";

//Performace/capability related parameters
	public static int MAXROWSIZE = 100; // max number rows
	public static int MAXCOLSIZE = 100; //max number of cols
	public static int MAXGRADE = 10; //max grade level
	public static int MAXTRIES = 30; //max attempts to generate solvable game

//Appearance related parameters
	public static int MINFONTSIZE=6;
	public static int MAXFONTSIZE=16;
	public static string font_desc;
	public static double CELLOFFSET_NOGRID=0.0;
	public static double CELLOFFSET_WITHGRID=2.0;
	public static double[] MINORGRIDDASH;
	public static Gdk.Color[,] colors;
	public const string BLOCKSEPARATOR=",";

//File location related parameters
	public static string exec_dir;
	public static string resource_dir;
	public static string locale_dir;
	public static string game_dir;
	public static string game_name;
	public static string icon_dir;
	public static string manual_dir;
	public static string prefix;
	public static bool installed;

	public static void init(string arg0)
	{
		prefix=_PREFIX;
		stdout.printf("Prefix is %s \n",prefix);
		stdout.printf("gettext package is %s \n",APP_GETTEXT_PACKAGE);

		File exec_file =File.new_for_path(Environment.find_program_in_path(arg0));
		exec_dir=exec_file.get_parent().get_path();
		stdout.printf("Exec_dir is %s \n",exec_dir);

		installed=is_installed(exec_dir);
		stdout.printf("Is installed is %s\n",installed.to_string());

		resource_dir=installed ? exec_file.get_parent().get_parent().get_path()+"/share/gnonograms" : exec_dir;
		stdout.printf("Resource_dir is %s \n",resource_dir);

		locale_dir=installed ? exec_file.get_parent().get_parent().get_path()+"/share/locale" : resource_dir+"/locale";
		stdout.printf("Locale_dir is %s \n",locale_dir);

		icon_dir=resource_dir+"/icons";
		manual_dir=resource_dir+"/Manual";

		game_dir=(Config.get_instance()).get_game_dir(resource_dir+"/games");

		game_name=(Config.get_instance()).get_game_name(DEFAULTGAMENAME);

		colors = new Gdk.Color[2,4];

		int setting =(int)GameState.SETTING;
		Gdk.Color.parse("GREY",out colors[setting,(int)CellState.UNKNOWN]);
		Gdk.Color.parse("WHITE", out colors[setting,(int)CellState.EMPTY]);
		Gdk.Color.parse("BLACK", out colors[setting,(int)CellState.FILLED]);
		Gdk.Color.parse("RED", out colors[setting,(int)CellState.ERROR]);

		int solving =(int)GameState.SOLVING;
		Gdk.Color.parse("GREY",out colors[solving,(int)CellState.UNKNOWN]);
		Gdk.Color.parse("YELLOW", out colors[solving,(int)CellState.EMPTY]);
		Gdk.Color.parse("BLUE", out colors[solving,(int)CellState.FILLED]);
		Gdk.Color.parse("RED", out colors[solving,(int)CellState.ERROR]);

		string [] config_colors=Config.get_instance().get_colors();
		Gdk.Color.parse(config_colors[0], out colors[setting,(int)CellState.EMPTY]);
		Gdk.Color.parse(config_colors[1], out colors[setting,(int)CellState.FILLED]);
		Gdk.Color.parse(config_colors[2], out colors[solving,(int)CellState.EMPTY]);
		Gdk.Color.parse(config_colors[3], out colors[solving,(int)CellState.FILLED]);

		font_desc="Ariel";
		MINORGRIDDASH={0.5, 3.0};

	}

	private static bool is_installed (string exec_dir)
	{
		return exec_dir.has_prefix(prefix) ? true : false;
	}

	public static string get_langpack_dir()
	{
		return locale_dir;
	}

	public static void set_colors()
	{
		var dialog = new Gtk.Dialog.with_buttons (
			null,
			null,
			Gtk.DialogFlags.MODAL|Gtk.DialogFlags.DESTROY_WITH_PARENT,
			_("Ok"), Gtk.ResponseType.OK,
			_("Cancel"), Gtk.ResponseType.CANCEL
			);

		var fset_label=new Gtk.Label(_("Color of filled cell when setting"));
		var eset_label=new Gtk.Label(_("Color of empty cell when setting"));
		var fsolve_label=new Gtk.Label(_("Color of filled cell when solving"));
		var esolve_label=new Gtk.Label(_("Color of empty cell when solving"));

		var label_box=new VBox(false,5);
		label_box.add(fset_label);
		label_box.add(eset_label);
		label_box.add(fsolve_label);
		label_box.add(esolve_label);

		var filled_setting=new Gtk.ColorButton.with_color(colors[(int)GameState.SETTING, (int)CellState.FILLED]);
		filled_setting.title=_("Color of filled cell when setting");
		var empty_setting=new Gtk.ColorButton.with_color(colors[(int)GameState.SETTING, (int)CellState.EMPTY]);
		empty_setting.title=_("Color of empty cell when setting");
		var filled_solving=new Gtk.ColorButton.with_color(colors[(int)GameState.SOLVING, (int)CellState.FILLED]);
		filled_solving.title=_("Color of filled cell when solving");
		var empty_solving=new Gtk.ColorButton.with_color(colors[(int)GameState.SOLVING, (int)CellState.EMPTY]);
		empty_solving.title=_("Color of empty cell when solving");

		var button_box=new VBox(false,5);
		button_box.add(filled_setting);
		button_box.add(empty_setting);
		button_box.add(filled_solving);
		button_box.add(empty_solving);

		var hbox=new HBox(false,5);
		hbox.add(label_box);
		hbox.add(button_box);

		dialog.vbox.add(hbox);
		dialog.show_all();
		if (dialog.run()==ResponseType.OK)
		{
			filled_setting.get_color(out colors[(int) GameState.SETTING, (int) CellState.FILLED]);
			empty_setting.get_color(out colors[(int) GameState.SETTING, (int) CellState.EMPTY]);
			filled_solving.get_color(out colors[(int) GameState.SOLVING, (int) CellState.FILLED]);
			empty_solving.get_color(out colors[(int) GameState.SOLVING, (int) CellState.EMPTY]);
		}
		dialog.destroy();
	}

	public void set_font()
	{
		var dialog = new FontSelectionDialog("Select font used for the clues");
		if (dialog.run()!=ResponseType.CANCEL)	font_desc=dialog.get_font_name();
		dialog.destroy();
	}

}
