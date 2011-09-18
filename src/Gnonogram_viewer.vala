/* Viewer class for Gnonograms
 * Handles user interface
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

 using Gtk;
 using Gdk;

public class Gnonogram_view : Gtk.Window
{
	public signal void solvegame();
	public signal void savegame();
	public signal void savepictogame();
	public signal void loadgame(string fname);
	public signal void quitgamesignal();
	public signal void newgame();
	public signal void hidegame();
	public signal void revealgame();
	public signal void checkerrors();
	public signal void restartgame();
	public signal void pausegame();
	public signal void randomgame();
	public signal void setcolors();
	public signal void setfont();
	public signal void setdifficulty(double grade);
	public signal void resizegame();
	public signal void togglegrid(bool active);
	public signal void toggletoolbar(bool active);
	public signal void changefont(bool increase);
//	public signal void debugmode(bool debug);
	public signal void advancedmode(bool advanced);
	public signal void difficultmode(bool difficult);
	public signal void resetall();
	public signal void undoredo(bool direction);
	public signal void editgame();

	private Gnonogram_controller _controller;
	private Gtk.SpinButton _grade_spin;
	private Gtk.ToggleToolButton _hide_tool;
	private Gtk.ToolButton _check_tool;
	private Gtk.ToolButton _undo_tool;
	private Gtk.ToolButton _redo_tool;
	private Gtk.ToolButton _restart_tool;
	private Gtk.ToolButton _resize_tool;
	public Gtk.Toolbar _toolbar;
	private Gtk.CheckMenuItem _gridmenuitem;
	private Gtk.CheckMenuItem _toolbarmenuitem;
	private Gtk.CheckMenuItem _advancedmenuitem;
	private Gtk.CheckMenuItem _difficultmenuitem;
	private Gtk.MenuItem _checkerrorsmenuitem;
	private Gtk.MenuItem _showsolutionmenuitem;
	private Gtk.MenuItem _showworkingmenuitem;
	private Gtk.MenuItem _undomenuitem;
	private Gtk.MenuItem _redomenuitem;
	private Gtk.MenuItem _restartmenuitem;
	private Gtk.MenuItem _grademenuitem;
	private Gtk.MenuItem _resizemenuitem;
	private Gtk.MenuItem _defaultsmenuitem;
	private Gtk.MenuItem _pausemenuitem;

	private Label _name_label;
	private Label _author_label;
	private Label _date_label;
	private Label _size_label;
	private Label _score_label;
	private Gtk.Image hide_icon;
	private Gtk.Image reveal_icon;
	private Gtk.AccelGroup accel_group;

	public Gnonogram_view(Gnonogram_LabelBox rb, Gnonogram_LabelBox cb, Gnonogram_CellGrid dg, Gnonogram_controller controller)
	{	_controller=controller; //seems to be necessary to get signals to work.  Not sure why.

		delete_event.connect (()=>{quitgamesignal();return true;});

		var info_frame=new Frame(null);
		var info_box = new VBox(false,0);
		_name_label= new Label("");
		set_name(_("New puzzle"));
		_name_label.set_alignment((float)0.0,(float)0.5);
		_author_label = new Label("");
		set_author(_("Unknown"));
		_author_label.set_alignment((float)0.0,(float)0.5);
		_date_label=new Label("");
		set_date(Utils.get_todays_date_string());
		_date_label.set_alignment((float)0.0,(float)0.5);
		_size_label=new Label("        ");
		_size_label.set_alignment((float)0.0,(float)0.5);
		_score_label=new Label("       ");
		_score_label.set_alignment((float)0.0,(float)0.5);
		info_box.add(_name_label);
		info_box.add(_author_label);
		info_box.add(_date_label);
		info_box.add(_size_label);
		info_box.add(_score_label);
		info_frame.add(info_box);

		var table = new Table(2,2,false);

		var ao = AttachOptions.FILL|AttachOptions.EXPAND;
		table.attach(info_frame,0,1,0,1,AttachOptions.SHRINK,AttachOptions.SHRINK,0,0);
		table.attach(rb,0,1,1,2,ao,ao,0,0);
		table.attach(cb,1,2,0,1,ao,ao,0,0);
		table.attach(dg,1,2,1,2,ao,ao,0,0);

		Resource.get_icon_theme();
		create_viewer_toolbar();

		var vbox = new VBox(false,0);
		vbox.pack_start(create_viewer_menubar(),false,false,0);
		vbox.pack_start(_toolbar,false,false,0);
		vbox.pack_start(table,true,true,0);

		add(vbox);

		this.title = _("Gnonograms");
		this.position = WindowPosition.CENTER;
		this.resizable=false;
	}
//======================================================================
	private MenuBar create_viewer_menubar()
	{
		accel_group=new Gtk.AccelGroup();
		this.add_accel_group(accel_group);

		var menubar = new MenuBar();
		var filemenuitem = new MenuItem.with_mnemonic(_("_File"));
		var gamemenuitem = new MenuItem.with_mnemonic(_("_Puzzle"));
		var settingsmenuitem = new MenuItem.with_mnemonic(_("_Settings"));
		var viewmenuitem = new MenuItem.with_mnemonic(_("_View"));
		var helpmenuitem = new MenuItem.with_mnemonic(_("_Help"));

		menubar.append(filemenuitem);
		menubar.append(gamemenuitem);
		menubar.append(settingsmenuitem);
		menubar.append(viewmenuitem);
		menubar.append(helpmenuitem);

		var filesubmenu = new Menu();
		filemenuitem.set_submenu(filesubmenu);
			var newmenuitem = new ImageMenuItem.from_stock(Gtk.Stock.NEW,accel_group);
			filesubmenu.add(newmenuitem);
			filesubmenu.add(new SeparatorMenuItem());
			var loadmenuitem = new ImageMenuItem.from_stock(Gtk.Stock.OPEN,accel_group);
			filesubmenu.add(loadmenuitem);
			var savemenuitem = new ImageMenuItem.from_stock(Gtk.Stock.SAVE,accel_group);
			filesubmenu.add(savemenuitem);
			var savepictomenuitem = new MenuItem.with_mnemonic(_("_Save as Picto puzzle"));
			filesubmenu.add(savepictomenuitem);
			filesubmenu.add(new SeparatorMenuItem());
			var quitmenuitem=new ImageMenuItem.from_stock(Gtk.Stock.QUIT, accel_group);
			filesubmenu.add(quitmenuitem);

		var gamesubmenu=new Menu();
		gamemenuitem.set_submenu(gamesubmenu);
			_undomenuitem=new ImageMenuItem.from_stock(Gtk.Stock.UNDO,accel_group);
			_undomenuitem.sensitive=false;
			gamesubmenu.add(_undomenuitem);
			_redomenuitem=new ImageMenuItem.from_stock(Gtk.Stock.REDO,accel_group);
			_redomenuitem.sensitive=false;
			gamesubmenu.add(_redomenuitem);
			_showsolutionmenuitem=new MenuItem.with_mnemonic(_("_Show solution"));
			gamesubmenu.add(_showsolutionmenuitem);
			_showworkingmenuitem=new MenuItem.with_mnemonic(_("Show _Working"));
			gamesubmenu.add(_showworkingmenuitem);
			_checkerrorsmenuitem=new MenuItem.with_mnemonic(_("Show _Incorrect cells"));
			gamesubmenu.add(_checkerrorsmenuitem);
			_checkerrorsmenuitem.set_sensitive(false);
			gamesubmenu.add(new SeparatorMenuItem());
			_restartmenuitem=new MenuItem.with_mnemonic(_("_Restart"));
			gamesubmenu.add(_restartmenuitem);
			_pausemenuitem=new MenuItem.with_mnemonic(_("_Pause"));
			gamesubmenu.add(_pausemenuitem);

			gamesubmenu.add(new SeparatorMenuItem());
			var computersolvemenuitem=new MenuItem.with_mnemonic(_("_Let computer solve it"));
			gamesubmenu.add(computersolvemenuitem);
			var computergeneratemenuitem=new MenuItem.with_mnemonic(_("_Computer generated puzzle"));
			gamesubmenu.add(computergeneratemenuitem);
			gamesubmenu.add(new SeparatorMenuItem());
			var infomenuitem=new MenuItem.with_mnemonic(_("_Edit puzzle"));
			gamesubmenu.add(infomenuitem);

		var settingssubmenu=new Menu();
		settingsmenuitem.set_submenu(settingssubmenu);
			var colormenuitem=new MenuItem.with_mnemonic(_("_Colors ..."));
			settingssubmenu.add(colormenuitem);
			var fontmenuitem=new MenuItem.with_mnemonic(_("_Font ..."));
			settingssubmenu.add(fontmenuitem);
			_resizemenuitem=new MenuItem.with_mnemonic(_("_Resize ..."));
			settingssubmenu.add(_resizemenuitem);
			_grademenuitem=new MenuItem.with_mnemonic(_("_Difficulty ..."));
			settingssubmenu.add(_grademenuitem);
			var gamedirmenuitem=new MenuItem.with_mnemonic(_("_Puzzle folder"));
			settingssubmenu.add(gamedirmenuitem);
			var gamesdirsubmenu=new Menu();
				var defaultgamedirmenuitem=new MenuItem.with_mnemonic(_("Default"));
				var customgamedirmenuitem=new MenuItem.with_mnemonic(_("Custom ..."));
				gamesdirsubmenu.add(defaultgamedirmenuitem);
				gamesdirsubmenu.add(customgamedirmenuitem);
			gamedirmenuitem.set_submenu(gamesdirsubmenu);

			settingssubmenu.add(new SeparatorMenuItem());
//			var debugmenuitem=new CheckMenuItem.with_mnemonic("D_ebug");
//			debugmenuitem.set_active(false);
//			debugmenuitem.set_sensitive(true); //for development only
//			settingssubmenu.add(debugmenuitem);
			_advancedmenuitem=new CheckMenuItem.with_mnemonic(_("_Use advanced solver"));
			_advancedmenuitem.set_active(true);
			settingssubmenu.add(_advancedmenuitem);
			_difficultmenuitem=new CheckMenuItem.with_mnemonic(_("_Generate difficult puzzles"));
			_difficultmenuitem.set_active(false);
			settingssubmenu.add(_difficultmenuitem);

			settingssubmenu.add(new SeparatorMenuItem());

			_defaultsmenuitem=new MenuItem.with_mnemonic(_("_Reset all to default"));
			settingssubmenu.add(_defaultsmenuitem);

		var viewsubmenu=new Menu();
		viewmenuitem.set_submenu(viewsubmenu);
			_toolbarmenuitem=new CheckMenuItem.with_mnemonic(_("_Toolbar"));
			viewsubmenu.add(_toolbarmenuitem);
			_toolbarmenuitem.set_active(true); //now set by config file
			_gridmenuitem=new CheckMenuItem.with_mnemonic(_("_Grid"));
			viewsubmenu.add(_gridmenuitem);
			_gridmenuitem.set_active(false); //now set by config file
			viewsubmenu.add(new SeparatorMenuItem());
			var zoominmenuitem=new ImageMenuItem.from_stock(Gtk.Stock.ZOOM_IN,accel_group);
			viewsubmenu.add(zoominmenuitem);
			var zoomoutmenuitem=new ImageMenuItem.from_stock(Gtk.Stock.ZOOM_OUT,accel_group);
			viewsubmenu.add(zoomoutmenuitem);

		var helpsubmenu=new Menu();
		helpmenuitem.set_submenu(helpsubmenu);
			var htmlmanualmenuitem=new MenuItem.with_mnemonic(_("Contents"));
			helpsubmenu.add(htmlmanualmenuitem);
			var aboutmenuitem=new MenuItem.with_mnemonic(_("About"));
			helpsubmenu.add(aboutmenuitem);


		newmenuitem.activate.connect(()=>{newgame();});
		newmenuitem.add_accelerator("activate",accel_group,keyval_from_name("n"),Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
		loadmenuitem.activate.connect(()=>{loadgame("");});
		loadmenuitem.add_accelerator("activate",accel_group,keyval_from_name("o"),Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
		savemenuitem.activate.connect(()=>{savegame();});
		savemenuitem.add_accelerator("activate",accel_group,keyval_from_name("s"),Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		savepictomenuitem.activate.connect(()=>{savepictogame();});

		quitmenuitem.activate.connect(()=>{quitgamesignal();});
		quitmenuitem.add_accelerator("activate",accel_group,keyval_from_name("q"),Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		_undomenuitem.activate.connect(()=>{undoredo(true);});
		_undomenuitem.add_accelerator("activate",accel_group,keyval_from_name("z"),Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		_redomenuitem.activate.connect(()=>{undoredo(false);});
		_redomenuitem.add_accelerator("activate",accel_group,keyval_from_name("y"),Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		_showsolutionmenuitem.activate.connect(()=>{revealgame();});
		_showsolutionmenuitem.add_accelerator("activate",accel_group,keyval_from_name("s"),Gdk.ModifierType.SHIFT_MASK, Gtk.AccelFlags.VISIBLE);
		_showworkingmenuitem.activate.connect(()=>{hidegame();});
		_showworkingmenuitem.add_accelerator("activate",accel_group,keyval_from_name("w"),Gdk.ModifierType.SHIFT_MASK, Gtk.AccelFlags.VISIBLE);
		_checkerrorsmenuitem.activate.connect(()=>{checkerrors();});
		_checkerrorsmenuitem.add_accelerator("activate",accel_group,keyval_from_name("i"),Gdk.ModifierType.SHIFT_MASK, Gtk.AccelFlags.VISIBLE);
		_restartmenuitem.activate.connect(()=>{restartgame();});
		_restartmenuitem.add_accelerator("activate",accel_group,keyval_from_name("r"),Gdk.ModifierType.SHIFT_MASK, Gtk.AccelFlags.VISIBLE);
		_pausemenuitem.activate.connect(()=>{pausegame();});
		_pausemenuitem.add_accelerator("activate",accel_group,keyval_from_name("p"),Gdk.ModifierType.SHIFT_MASK, Gtk.AccelFlags.VISIBLE);
		computersolvemenuitem.activate.connect(()=>{solvegame();});
		computersolvemenuitem.add_accelerator("activate",accel_group,keyval_from_name("c"),Gdk.ModifierType.SHIFT_MASK, Gtk.AccelFlags.VISIBLE);
		computergeneratemenuitem.activate.connect(()=>{randomgame();});
		computergeneratemenuitem.add_accelerator("activate",accel_group,keyval_from_name("g"),Gdk.ModifierType.SHIFT_MASK, Gtk.AccelFlags.VISIBLE);

		colormenuitem.activate.connect(()=>{setcolors();});
		fontmenuitem.activate.connect(()=>{setfont();});
		_resizemenuitem.activate.connect(()=>{resizegame();});
		_grademenuitem.activate.connect(set_difficulty);
		customgamedirmenuitem.activate.connect(Resource.set_custom_game_dir);
		defaultgamedirmenuitem.activate.connect(Resource.set_default_game_dir);
		infomenuitem.activate.connect(()=>{editgame();});
		infomenuitem.add_accelerator("activate",accel_group,keyval_from_name("e"),Gdk.ModifierType.SHIFT_MASK, Gtk.AccelFlags.VISIBLE);

//		debugmenuitem.activate.connect(()=>{debugmode(debugmenuitem.active);});
		_advancedmenuitem.activate.connect(()=>{advancedmode(_advancedmenuitem.active);});
		_difficultmenuitem.activate.connect(()=>{difficultmode(_difficultmenuitem.active);});
		_defaultsmenuitem.activate.connect(()=>{_advancedmenuitem.set_active(true); _difficultmenuitem.set_active(false);resetall();});

		_toolbarmenuitem.activate.connect(()=>{toggletoolbar(_toolbarmenuitem.active);});
		_toolbarmenuitem.add_accelerator("activate",accel_group,keyval_from_name("t"),Gdk.ModifierType.MOD1_MASK, Gtk.AccelFlags.VISIBLE);

		_gridmenuitem.activate.connect(()=>{togglegrid(_gridmenuitem.active);});
		_gridmenuitem.add_accelerator("activate",accel_group,keyval_from_name("g"),Gdk.ModifierType.MOD1_MASK, Gtk.AccelFlags.VISIBLE);

		zoominmenuitem.activate.connect(()=>{changefont(true);});
		zoominmenuitem.add_accelerator("activate",accel_group,keyval_from_name("plus"),Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
		zoominmenuitem.add_accelerator("activate",accel_group,keyval_from_name("equal"),Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
		zoomoutmenuitem.activate.connect(()=>{changefont(false);});
		zoomoutmenuitem.add_accelerator("activate",accel_group,keyval_from_name("minus"),Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

		aboutmenuitem.activate.connect(show_about);
		htmlmanualmenuitem.activate.connect(show_html_manual);
		htmlmanualmenuitem.add_accelerator("activate",accel_group,keyval_from_name("F1"),(Gdk.ModifierType)0, Gtk.AccelFlags.VISIBLE);
		return menubar;
	}
//======================================================================
	private void create_viewer_toolbar()
	{
		_toolbar = new Toolbar();
		_toolbar.set_style(Gtk.ToolbarStyle.ICONS);

		var new_tool=new ToolButton.from_stock(Gtk.Stock.CLEAR);
//		var new_tool=new ToolButton.from_stock(Gtk.STOCK_CLEAR);
		new_tool.set_tooltip_text(_("New puzzle"));
		_toolbar.add(new_tool);

		var load_tool=new ToolButton.from_stock(Gtk.Stock.OPEN);
//		var load_tool=new ToolButton.from_stock(Gtk.STOCK_OPEN);
		load_tool.set_tooltip_text(_("Load puzzle"));
		_toolbar.add(load_tool);

		var save_as_tool=new ToolButton.from_stock(Gtk.Stock.SAVE_AS);
//		var save_as_tool=new ToolButton.from_stock(Gtk.STOCK_SAVE_AS);
		save_as_tool.set_tooltip_text(_("Save puzzle"));
		_toolbar.add(save_as_tool);

		_toolbar.add(new SeparatorToolItem());

//		_undo_tool=new ToolButton.from_stock(Gtk.STOCK_UNDO);
		_undo_tool=new ToolButton.from_stock(Gtk.Stock.UNDO);
		_undo_tool.set_tooltip_text(_("Undo last move"));
		_toolbar.add(_undo_tool);

//		_redo_tool=new ToolButton.from_stock(Gtk.STOCK_REDO);
		_redo_tool=new ToolButton.from_stock(Gtk.Stock.REDO);
		_redo_tool.set_tooltip_text(_("Redo last undone move"));
		_toolbar.add(_redo_tool);
		_restart_tool=new ToolButton.from_stock(Gtk.Stock.REFRESH);
//		_restart_tool=new ToolButton.from_stock(Gtk.STOCK_REFRESH);
		_restart_tool.set_tooltip_text(_("Start this puzzle again"));
		_toolbar.add(_restart_tool);
		_toolbar.add(new SeparatorToolItem());

		hide_icon=new Gtk.Image.from_pixbuf(Resource.get_icon(Resource.IconID.HIDE));
		reveal_icon=new Gtk.Image.from_pixbuf(Resource.get_icon(Resource.IconID.REVEAL));
		_hide_tool=new ToggleToolButton();
		_hide_tool.set_label("Hide/Reveal");
		_hide_tool.set_icon_widget(hide_icon);
		_hide_tool.set_tooltip_text(_("Hide the solution and start solving"));
		_toolbar.add(_hide_tool);

		var peek_icon=new Gtk.Image.from_pixbuf(Resource.get_icon(Resource.IconID.PEEK));
		_check_tool=new ToolButton(peek_icon,_("Check"));
		_check_tool.set_tooltip_text(_("Show any incorrect cells"));
		_toolbar.add(_check_tool);

		var solve_icon=new Gtk.Image.from_pixbuf(Resource.get_icon(Resource.IconID.SOLVE));
		var solve_tool=new ToolButton(solve_icon,_("Solve"));
		solve_tool.set_tooltip_text(_("Solve by computer"));
		_toolbar.add(solve_tool);

		var random_icon=new Gtk.Image.from_pixbuf(Resource.get_icon(Resource.IconID.RANDOM));

		var random_tool=new ToolButton(random_icon,_("Random"));
		random_tool.set_tooltip_text(_("Generate a random puzzle"));
		_toolbar.add(random_tool);

		_toolbar.add(new SeparatorToolItem());

		var resize_icon=new Gtk.Image.from_pixbuf(Resource.get_icon(Resource.IconID.RESIZE));
		_resize_tool=new ToolButton(resize_icon,_("Resize"));
		_resize_tool.set_tooltip_text(_("Change dimensions of the puzzle grid"));
		_toolbar.add(_resize_tool);

//		var zoom_in_tool=new ToolButton.from_stock(Gtk.STOCK_ZOOM_IN);
		var zoom_in_tool=new ToolButton.from_stock(Gtk.Stock.ZOOM_IN);
		zoom_in_tool.set_tooltip_text(_("Increase font size"));
		_toolbar.add(zoom_in_tool);

		var zoom_out_tool=new ToolButton.from_stock(Gtk.Stock.ZOOM_OUT);
//		var zoom_out_tool=new ToolButton.from_stock(Gtk.STOCK_ZOOM_OUT);
		zoom_out_tool.set_tooltip_text(_("Decrease font size"));
		_toolbar.add(zoom_out_tool);

		var grade_tool=new ToolItem();
		_grade_spin=new SpinButton.with_range(1,Resource.MAXGRADE,1);
		_grade_spin.set_tooltip_text(_("Set the difficulty of generated puzzles"));
		_grade_spin.set_can_focus(false);
		grade_tool.add(_grade_spin);
		_toolbar.add(grade_tool);

		new_tool.clicked.connect(()=>{newgame();});
		save_as_tool.clicked.connect(()=>{savegame();});
		_undo_tool.clicked.connect(()=>{undoredo(true);});
		_redo_tool.clicked.connect(()=>{undoredo(false);});
		load_tool.clicked.connect(()=>{loadgame("");});

		_hide_tool.toggled.connect(toggle_execute);
		_check_tool.clicked.connect(()=>{checkerrors();});
		_restart_tool.clicked.connect(()=>{this.restart_game();restartgame();});
		solve_tool.clicked.connect(()=>{solvegame();});
		random_tool.clicked.connect(()=>{randomgame();});
		_grade_spin.value_changed.connect((sb)=>{setdifficulty(sb.get_value());});
		grade_tool.create_menu_proxy.connect(()=>{
			var grademenuitem2=new MenuItem.with_mnemonic(_("_Difficulty"));
			grademenuitem2.activate.connect(set_difficulty);
			grade_tool.set_proxy_menu_item(_("Difficulty"), grademenuitem2);
			return true;
			}
		);

		_resize_tool.clicked.connect(()=>{resizegame();});
		zoom_in_tool.clicked.connect(()=>{changefont(true);});
		zoom_out_tool.clicked.connect(()=>{changefont(false);});

	}
//======================================================================
	private void toggle_execute()
	{
		if (_hide_tool.active) hidegame();
		else revealgame();
	}
//======================================================================
//	private void toggle_toolbar(Gtk.MenuItem cmi)
//	{
//		_toolbar.visible=((Gtk.CheckMenuItem)cmi).active;
//	}
//======================================================================
	private void set_difficulty()
	{
		var win=new Gtk.Window(Gtk.WindowType.TOPLEVEL);
		win.set_decorated(true);
		win.set_resizable(false);
		win.set_modal(true);
		var grade_spin2=new SpinButton.with_range(1,10,1);
		grade_spin2.set_tooltip_text(_("Set the difficulty of generated puzzles"));
		//grade_spin2.set_can_focus(false);
		grade_spin2.set_value(_grade_spin.get_value());
		win.add(grade_spin2);
//		win.leave_notify_event.connect(()=>{
		win.delete_event.connect(()=>{
			set_grade_spin_value(grade_spin2.get_value());
			win.destroy();
			return false;
			}
		);
		win.set_position(WindowPosition.MOUSE);
		win.show_all();
	}
//======================================================================
	private void show_about()
	{
		string[] authors={"Jeremy Wootten <jeremywootten@gmail.com>",null};
		Gtk.Image _logo = new Gtk.Image.from_file(Resource.resource_dir+"/icons/gnonograms48.png");
		show_about_dialog (null,
                       "program-name", _("Gnonograms"),
                       "version", _VERSION,
                       "comments", _("Design and solve Nonogram puzzles"),
                       "license","Gnonograms is free software; you can redistribute it and/or modify it under the terms of the GNU General Public Licence as published by the Free Software Foundation; either version 2 of the Licence, or (at your option) any later version.\n\nGnonogram is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public Licence for more details.\n\nYou should have received a copy of the GNU General Public Licence along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA\n\nAny puzzles distributed with the program are licensed under the Creative Commons Attribution Share-Alike license.  A copy of the license should have been distributed with the program, if not, see http://creativecommons.org/licenses/ \nOn Debian systems, the complete text of the GNU General Public License version 2 can be found in /usr/share/common-licenses/GPL-2",
                       "wrap_license",true,
                       "logo", _logo.get_pixbuf(),
                       "title", _("About Gnonograms"),
                       "authors", authors,
                       null);
	}

//======================================================================
	private void show_html_manual()
	{
		var manual_uri="file:///"+Resource.html_manual_dir+"/index.html";
		try	{
			show_uri(get_screen(),manual_uri,get_current_event_time());
		}
		catch (GLib.Error e) {
			Utils.show_warning_dialog(e.message);
		}
	}
//======================================================================
	public void set_name(string name){_name_label.set_text(_("Name:")+" "+name+"  ");}
	public string get_name(){return get_info_item(_name_label);	}
//======================================================================
	public void set_author(string author){_author_label.set_text(_("By:")+" "+author+"  ");}
	public string get_author(){return get_info_item(_author_label);}
//======================================================================
	public void set_date(string date){_date_label.set_text(_("Date:")+" "+date+"  ");}
	public string get_date(){return get_info_item(_date_label);	}
//======================================================================
	public void set_score_label(string score)
	{//stdout.printf("set_score_label %s\n",score);
		_score_label.set_text(_("Score:")+" "+score+"  ");
	}
	public string get_score(){return get_info_item(_score_label);	}
//======================================================================
	private string get_info_item(Label l)
	{
		string[] s=(l.get_text()).split(":",2);
		string info;
		if (s.length>1)
		{
			info=s[1].strip();
			if (info=="") info=_("Unknown");
		}
		else info=_("Unknown");
		return info;
	}
//======================================================================
	public void set_size_label(int r, int c)
	{
		_size_label.set_text(_("Size: ")+r.to_string()+"X"+c.to_string()+"  ");
	}
//======================================================================
	public void set_grade_spin_value(double d)
	{
		_grade_spin.set_value(d.clamp(1.0,10.0));
	}
//======================================================================
	public double get_grade_spin_value()
	{
		return _grade_spin.get_value();
	}
//======================================================================
	public void set_toolbar_visible(bool visible)
	{
		_toolbar.visible=visible;
	}
//======================================================================
	public bool get_toolbar_visible()
	{
		return _toolbar.visible;
	}
//======================================================================
	public void state_has_changed(GameState gs)
	{ //stdout.printf("Viewer state changed\n");
		bool solving=(gs==GameState.SOLVING);
		_showsolutionmenuitem.sensitive=solving;
		_showworkingmenuitem.sensitive=!solving;
		_restart_tool.sensitive=solving;
		_restartmenuitem.sensitive=solving;
		_hide_tool.set_active(solving);

		_defaultsmenuitem.sensitive=!solving;
		_resizemenuitem.sensitive=!solving;
		_resize_tool.sensitive=!solving;
		_check_tool.sensitive=solving;
		_checkerrorsmenuitem.sensitive=solving;
		_pausemenuitem.sensitive=solving;

		if (gs==GameState.SETTING)
		{
			_hide_tool.set_tooltip_text(_("Hide the solution and start solving"));
			_hide_tool.set_icon_widget(hide_icon);
			_hide_tool.show_all();
			set_undo_sensitive(false);
			set_redo_sensitive(false);
		}
		else
		{
			_hide_tool.set_tooltip_text(_("Reveal the solution"));
			_hide_tool.set_icon_widget(reveal_icon);
			_hide_tool.show_all();
		}
	}
//======================================================================
	public void set_undo_sensitive(bool sensitive)
	{
		_undomenuitem.sensitive=sensitive;
		_undo_tool.sensitive=sensitive;
	}
	public void set_redo_sensitive(bool sensitive)
	{
		_redomenuitem.sensitive=sensitive;
		_redo_tool.sensitive=sensitive;
	}
	public void set_advancedmenuitem_active(bool active)
	{
		_advancedmenuitem.active=active;
	}
	public void set_difficultmenuitem_active(bool active)
	{
		_difficultmenuitem.active=active;
	}
	public void set_gridmenuitem_active(bool active)
	{
		_gridmenuitem.active=active;
	}
	public void set_toolbarmenuitem_active(bool active)
	{
		_toolbarmenuitem.set_active(active);
	}

//======================================================================
	private void restart_game()
	{
		set_undo_sensitive(false);
		set_redo_sensitive(false);
	}

}
