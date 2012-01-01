/* Resource handling functions for Gnonograms
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


using Gtk;
using Gdk;
using GLib;

// Defined by configure and make
extern const string _PREFIX;
extern const string _VERSION;
extern const string GETTEXT_PACKAGE;
extern const int _GNOME_DOC;

namespace Resource
{
	public enum IconID {
			PEEK,
			SOLVE,
			RANDOM,
			RESIZE,
			HIDE,
			REVEAL
	}
	public const string APP_GETTEXT_PACKAGE = GETTEXT_PACKAGE;
	public const string DEFAULTGAMENAME = "New puzzle";
	public const string GAMEFILEEXTENSION=".gno";
	public const string POSITIONFILENAME="currentposition";
	//Built in icon filenames
	public const string RANDOMICONFILENAME="dice.png";
	public const string PEEKICONFILENAME="errorcheck.png";
	public const string RESIZEICONFILENAME="resize.png";
	public const string SOLVEICONFILENAME="laptop.png";
	public const string HIDEICONFILENAME="eyes-open.png";
	public const string REVEALICONFILENAME="eyes-closed.png";
	public const string MISSINGICONFILENAME="";
	public const string LOGOFILENAME="gnonograms.svg";
	//Icon theme names
	public const string SOLVEICONTHEMENAME="computer";
	public const string PEEKICONTHEMENAME="";
	public const string RANDOMICONTHEMENAME="";
	public const string RESIZEICONTHEMENAME="resize";
	public const string HIDEICONTHEMENAME="hide";
	public const string REVEALICONTHEMENAME="reveal";
	public const string MISSINGICONTHEMENAME="image-missing";

	public const string DEFAULT_FONT="Ariel";

//Performace/capability related parameters
	public static int MAXSIZE = 100; // max number rows or columns
	public static int MINSIZE = 5;
	public static int MAXGRADE = 12; //max grade level
	public static int MAXTRIES = 500; //max attempts to generate solvable game
	public static int MAXADVANCEDGRADE=30;
	public static int MINADVANCEDGRADE=15;

	public static int MAXUNDO = 1000; //max moves that can be undone
	public static int DEFAULT_DIFFICULTY = 5;

//Appearance related parameters
	public static double MINFONTSIZE=3.0;
	public static double MAXFONTSIZE=72.0;
	public static double MAXWINDOWHEIGHT=475.0; //TODO relate to actual screen resolution
	public static double MAXWINDOWWIDTH=700.0;  //TODO relate to actual screen resolution

	public static string font_desc;
	public static double CELLOFFSET_NOGRID=0.0;
	public static double CELLOFFSET_WITHGRID=2.0;
	public static double[] MINORGRIDDASH;
	public static int DEFAULT_ROWS=10;
	public static int DEFAULT_COLS=10;
	public static bool DEFAULT_SHOWTOOLBAR=true;
	public static bool DEFAULT_SHOWGRID=true;
	public static bool DEFAULT_ADVANCEDPUZZLES=false;
	public static bool DEFAULT_ADVANCEDSOLVER=true;
	public static bool DEFAULT_INCURTIMEPENALTY=true;
	public static double FIXED_TIMEPENALTY=30.0;
	public static double PER_CELL_TIMEPENALTY=10.0;

	public static Gdk.Color[,] colors;
	public static Gdk.Color default_filled_setting;
	public static Gdk.Color default_empty_setting;
	public static Gdk.Color default_filled_solving;
	public static Gdk.Color default_empty_solving;
	public const string BLOCKSEPARATOR=",";

//File location related parameters
	public static string exec_dir;
	public static string resource_dir;
	public static string locale_dir;
	public static string load_game_dir;
	public static string save_game_dir;
	public static string user_config_dir;
	public static string game_name;
	public static string icon_dir;
	public static string html_manual_dir;
	public static string prefix;
	public static bool installed;
	public static bool use_gnome_help;
	public static int icon_size=24;

	private IconTheme icon_theme;

	public static void init(string arg0)
	{
		prefix=_PREFIX;
		stdout.printf("Prefix is %s \n",prefix);
		stdout.printf("gettext package is %s \n",APP_GETTEXT_PACKAGE);

		File exec_file =File.new_for_path(Environment.find_program_in_path(arg0));
		exec_dir=exec_file.get_parent().get_path();
		string root_dir=exec_file.get_parent().get_parent().get_path();
		stdout.printf("Exec_dir is %s \n",exec_dir);

		installed=is_installed(exec_dir);
		stdout.printf("Is installed is %s\n",installed.to_string());

		resource_dir=installed ? root_dir+"/share/gnonograms" : exec_dir;
		stdout.printf("Resource_dir is %s \n",resource_dir);

		locale_dir=installed ? root_dir+"/share/locale" : resource_dir+"/locale";
		stdout.printf("Locale_dir is %s \n",locale_dir);

		icon_dir=resource_dir+"/icons";

		use_gnome_help=(_GNOME_DOC==1);
		html_manual_dir=resource_dir+"/html";
		string gnome_manual_dir=installed ? root_dir+"/share/gnome/help/gnonograms/C" : resource_dir+"/help/C";
		var dir=File.new_for_path(gnome_manual_dir);
		if (dir.query_file_type(FileQueryInfoFlags.NONE,null)!=FileType.DIRECTORY)
		{
			//fall back to html help if cannot locate gnome help directory
			use_gnome_help=false;
		}

		user_config_dir=Environment.get_user_config_dir();

		var config_instance=Config.get_instance();
		save_game_dir=config_instance.get_save_game_dir(Environment.get_home_dir());
		game_name=config_instance.get_game_name(DEFAULTGAMENAME);

		colors = new Gdk.Color[2,4];
		set_default_colors();

		MINORGRIDDASH={0.5, 3.0};
	}

	public static void load_config(Config config_instance)
	{
		Resource.get_colors(config_instance);
		Resource.get_game_dir(config_instance);
		Resource.get_font(config_instance);
	}

	private static bool is_installed (string exec_dir)
	{
		return exec_dir.has_prefix(prefix) ? true : false;
	}

	public static string get_langpack_dir()
	{
		return locale_dir;
	}

	public void reset_all()
	{
		set_default_colors();
		set_default_font();
		set_default_game_dir();
	}

	private static void set_default_colors()
	{
		//Default colors - may be replaced from config file.
		int setting =(int)GameState.SETTING;
		Gdk.Color.parse("GREY",out colors[setting,(int)CellState.UNKNOWN]);
		Gdk.Color.parse("WHITE", out colors[setting,(int)CellState.EMPTY]);
		default_empty_setting=colors[setting,(int)CellState.EMPTY];
		Gdk.Color.parse("BLACK", out colors[setting,(int)CellState.FILLED]);
		default_filled_setting=colors[setting,(int)CellState.FILLED];
		Gdk.Color.parse("RED", out colors[setting,(int)CellState.ERROR]);

		int solving =(int)GameState.SOLVING;
		Gdk.Color.parse("GREY",out colors[solving,(int)CellState.UNKNOWN]);
		Gdk.Color.parse("YELLOW", out colors[solving,(int)CellState.EMPTY]);
		default_empty_solving=colors[solving,(int)CellState.EMPTY];
		Gdk.Color.parse("BLUE", out colors[solving,(int)CellState.FILLED]);
		default_filled_solving=colors[solving,(int)CellState.FILLED];
		Gdk.Color.parse("RED", out colors[solving,(int)CellState.ERROR]);
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


		var reset_filled_setting=new Gtk.ToolButton.from_stock(Gtk.Stock.CLEAR);
		reset_filled_setting.tooltip_text=_("Reset to default color");
		reset_filled_setting.clicked.connect(()=>{filled_setting.set_color(default_filled_setting);});
		var reset_empty_setting=new Gtk.ToolButton.from_stock(Gtk.Stock.CLEAR);
		reset_empty_setting.tooltip_text=_("Reset to default color");
		reset_empty_setting.clicked.connect(()=>{empty_setting.set_color(default_empty_setting);});
		var reset_filled_solving=new Gtk.ToolButton.from_stock(Gtk.Stock.CLEAR);
		reset_filled_solving.tooltip_text=_("Reset to default color");
		reset_filled_solving.clicked.connect(()=>{filled_solving.set_color(default_filled_solving);});
		var reset_empty_solving=new Gtk.ToolButton.from_stock(Gtk.Stock.CLEAR);
		reset_empty_solving.tooltip_text=_("Reset to default color");
		reset_empty_solving.clicked.connect(()=>{empty_solving.set_color(default_empty_solving);});

		var reset_button_box=new VBox(false,5);
		reset_button_box.add(reset_filled_setting);
		reset_button_box.add(reset_empty_setting);
		reset_button_box.add(reset_filled_solving);
		reset_button_box.add(reset_empty_solving);

		var hbox=new HBox(false,5);
		hbox.add(label_box);
		hbox.add(button_box);
		hbox.add(reset_button_box);

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

	public static void get_colors(Config config_instance)
	{
		string [] config_colors=config_instance.get_colors();
		int setting =(int)GameState.SETTING;
		int solving =(int)GameState.SOLVING;
		Gdk.Color.parse(config_colors[0], out colors[setting,(int)CellState.EMPTY]);
		Gdk.Color.parse(config_colors[1], out colors[setting,(int)CellState.FILLED]);
		Gdk.Color.parse(config_colors[2], out colors[solving,(int)CellState.EMPTY]);
		Gdk.Color.parse(config_colors[3], out colors[solving,(int)CellState.FILLED]);
	}

	public static void set_custom_font()
	{
		var dialog = new FontSelectionDialog("Select font used for the clues");
		if (dialog.run()!=ResponseType.CANCEL)	font_desc=dialog.get_font_name();
		dialog.destroy();
	}
	public static void set_default_font()
	{
		font_desc=DEFAULT_FONT;
	}
	public static void get_font(Config config_instance)
	{
		font_desc=config_instance.get_font();;
	}
	public static void set_custom_game_dir()
	{
		string new_dir=Utils.get_filename(FileChooserAction.SELECT_FOLDER,"Choose folder for saving and loading puzzles",null,null,Resource.save_game_dir);
		if (new_dir!="")
		{
			Resource.save_game_dir=new_dir;
			Resource.load_game_dir=new_dir;
		}
	}
	public static void set_default_game_dir()
	{
		Resource.load_game_dir=resource_dir+"/games";
		Resource.save_game_dir=Environment.get_home_dir();
	}
	public static void get_game_dir(Config config_instance)
	{
		Resource.load_game_dir=config_instance.get_load_game_dir(resource_dir+"/games");
		Resource.save_game_dir=config_instance.get_save_game_dir(Environment.get_home_dir());
	}

	public static void get_icon_theme()
	{
		icon_theme=Gtk.IconTheme.get_default();
		if (icon_theme==null) stdout.printf("Default Icon theme not found\n");
	}

	public static Gdk.Pixbuf? get_theme_icon(string icon_name)
	{
		Gdk.Pixbuf icon = null;
		try
		{
			icon=icon_theme.load_icon(icon_name,icon_size,Gtk.IconLookupFlags.NO_SVG|Gtk.IconLookupFlags.FORCE_SIZE);
		}
		catch (GLib.Error e){}
		return icon;
	}

	public static Gdk.Pixbuf? get_app_icon(string icon_filename)
	{
		Gdk.Pixbuf icon = null;
		try
		{
			icon=new Pixbuf.from_file(Resource.icon_dir+"/"+icon_filename);
		}
		catch (GLib.Error e)
		{
			//stdout.printf("Failed to load app icon %s\n",icon_filename);
		}
		return icon;
	}

	public static Gdk.Pixbuf? get_icon(Resource.IconID id)
	{
		Gdk.Pixbuf icon=null;
		string icon_filename, icon_themename;
		switch (id)
		{
			case IconID.PEEK:
				icon_filename=PEEKICONFILENAME;
				icon_themename=PEEKICONTHEMENAME;
				break;
			case IconID.SOLVE:
				icon_filename=SOLVEICONFILENAME;
				icon_themename=SOLVEICONTHEMENAME;
				break;
			case IconID.RANDOM:
				icon_filename=RANDOMICONFILENAME;
				icon_themename=RANDOMICONTHEMENAME;
				break;
			case IconID.RESIZE:
				icon_filename=RESIZEICONFILENAME;
				icon_themename=RESIZEICONTHEMENAME;
				break;
			case IconID.HIDE:
				icon_filename=HIDEICONFILENAME;
				icon_themename=HIDEICONTHEMENAME;
				break;
			case IconID.REVEAL:
				icon_filename=REVEALICONFILENAME;
				icon_themename=REVEALICONTHEMENAME;
				break;
			default:
				icon_filename=MISSINGICONFILENAME;
				icon_themename=MISSINGICONTHEMENAME;
				break;

		}
		icon=get_theme_icon(icon_themename);
		if (icon==null)
		{
			icon=get_app_icon(icon_filename);
			if (icon==null)
			{
				icon=get_theme_icon(MISSINGICONTHEMENAME);
			}
		}
		return icon;
	}
}
