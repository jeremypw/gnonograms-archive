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

public class Gnonogram_view : Gtk.Window
{
	public signal void solvegame();
	public signal void savegame();
	public signal void loadgame();
	public signal void saveposition();
	public signal void loadposition();
	public signal void quitgamesignal();
	public signal void newgame();
	public signal void hidegame();
	public signal void revealgame();
	public signal void peekgame();
	public signal void restartgame();
	public signal void randomgame();
	public signal void setcolors();
	public signal void setdifficulty(double grade);
	public signal void resizegame();
	public signal void togglegrid(bool active);
	public signal void changefont(bool increase);
	
	private Gnonogram_controller _controller;
	private Gtk.SpinButton _grade_spin;
	private Gtk.VBox _image_vbox;
	private Gtk.Statusbar _statusbar;
	private uint _setting_context;
	private Gtk.ToggleToolButton _hide_tool;
	private Gtk.ToolButton _peek_tool;
	private Gtk.Toolbar _toolbar;
	private Gtk.CheckMenuItem _gridmenuitem;
	private Gtk.MenuItem _peeksolutionmenuitem;
	private Gtk.MenuItem _showsolutionmenuitem;
	private Gtk.MenuItem _showworkingmenuitem;
	private Gtk.MenuItem grademenuitem;
	private string _name="New File";
	
	private Gtk.Image _logo;
	
	public Gnonogram_view(Gnonogram_LabelBox rb, Gnonogram_LabelBox cb, Gnonogram_CellGrid dg, Gnonogram_controller controller)
	{	_controller=controller; //seems to be necessary to get signals to work.  Not sure why.
		
		this.title = _("Gnonograms");
		this.position = WindowPosition.CENTER;
		delete_event.connect (()=>{quitgamesignal();return true;});		
				
		_image_vbox = new VBox(false,4);
		var table = new Table(2,2,false);
		_logo = new Gtk.Image.from_file(Resource.icon_dir+"/gnonograms.png");
		_image_vbox.add(_logo);
		
		var ao = AttachOptions.FILL|AttachOptions.EXPAND;
		table.attach(_image_vbox,0,1,0,1,AttachOptions.SHRINK,AttachOptions.SHRINK,0,0);
		table.attach(rb,0,1,1,2,ao,ao,0,0);
		table.attach(cb,1,2,0,1,ao,ao,0,0);
		table.attach(dg,1,2,1,2,ao,ao,0,0);
		
		_statusbar = new Statusbar();
		_statusbar.set_has_resize_grip(false);
		_setting_context=_statusbar.get_context_id("Setting");

		create_viewer_toolbar();
		
		var vbox = new VBox(false,0);
		vbox.pack_start(create_viewer_menubar(),false,false,0);
		vbox.pack_start(_toolbar,false,false,0);
		vbox.pack_start(table,true,true,0);
		vbox.pack_start(_statusbar,false,false,0);
		
		add(vbox);
	}
//======================================================================
	private MenuBar create_viewer_menubar()
	{
		var menubar = new MenuBar();
		var filemenuitem = new MenuItem.with_mnemonic(_("_File"));
		var gamemenuitem = new MenuItem.with_mnemonic(_("_Game"));
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
			var newmenuitem = new MenuItem.with_mnemonic(_("_New"));
			filesubmenu.add(newmenuitem);
			var sep1 = new SeparatorMenuItem();
			filesubmenu.add(sep1);
			var loadmenuitem = new MenuItem.with_mnemonic(_("_Load"));
			filesubmenu.add(loadmenuitem);
			var savemenuitem = new MenuItem.with_mnemonic(_("_Save"));
			filesubmenu.add(savemenuitem);
			var sep2 = new SeparatorMenuItem();
			filesubmenu.add(sep2);
			var quitmenuitem=new MenuItem.with_mnemonic(_("_Quit"));
			filesubmenu.add(quitmenuitem);

			var loadsubmenu = new Menu();
			loadmenuitem.set_submenu(loadsubmenu);
				var loadpuzzlemenuitem=new MenuItem.with_mnemonic(_("_Puzzle"));
				loadsubmenu.add(loadpuzzlemenuitem);
				var loadpositionmenuitem=new MenuItem.with_mnemonic(_("_Unfinished"));
				loadsubmenu.add(loadpositionmenuitem);
					
			var savesubmenu = new Menu();
			savemenuitem.set_submenu(savesubmenu);
				var savepuzzlemenuitem=new MenuItem.with_mnemonic(_("_Puzzle"));
				savesubmenu.add(savepuzzlemenuitem);
				var savepositionmenuitem=new MenuItem.with_mnemonic(_("_Unfinished"));
				savesubmenu.add(savepositionmenuitem);
					
		var gamesubmenu=new Menu();
		gamemenuitem.set_submenu(gamesubmenu);
			_showsolutionmenuitem=new MenuItem.with_mnemonic(_("_Show solution"));
			gamesubmenu.add(_showsolutionmenuitem);
			_showworkingmenuitem=new MenuItem.with_mnemonic(_("Show _Working"));
			gamesubmenu.add(_showworkingmenuitem);
			_peeksolutionmenuitem=new MenuItem.with_mnemonic(_("_Quick peek at solution"));
			gamesubmenu.add(_peeksolutionmenuitem);
			var restartmenuitem=new MenuItem.with_mnemonic(_("_Restart"));
			gamesubmenu.add(restartmenuitem);
			var sep3 = new SeparatorMenuItem();
			gamesubmenu.add(sep3);
			var computersolvemenuitem=new MenuItem.with_mnemonic(_("_Let computer solve it"));
			gamesubmenu.add(computersolvemenuitem);
			var computergeneratemenuitem=new MenuItem.with_mnemonic(_("_Computer generated puzzle"));
			gamesubmenu.add(computergeneratemenuitem);

							
		var settingssubmenu=new Menu();
		settingsmenuitem.set_submenu(settingssubmenu);
			var colormenuitem=new MenuItem.with_mnemonic(_("_Colors"));
			settingssubmenu.add(colormenuitem);	
			var resizemenuitem=new MenuItem.with_mnemonic(_("_Resize"));
			settingssubmenu.add(resizemenuitem);
			grademenuitem=new MenuItem.with_mnemonic(_("_Difficulty"));
			settingssubmenu.add(grademenuitem);				
		var viewsubmenu=new Menu();
		viewmenuitem.set_submenu(viewsubmenu);
			var fullscreenmenuitem=new CheckMenuItem.with_mnemonic(_("_Fullscreen"));
			viewsubmenu.add(fullscreenmenuitem);
			fullscreenmenuitem.set_active(false);
			var toolbarmenuitem=new CheckMenuItem.with_mnemonic(_("_Toolbar"));
			viewsubmenu.add(toolbarmenuitem);
			toolbarmenuitem.set_active(true);
			_gridmenuitem=new CheckMenuItem.with_mnemonic(_("_Grid"));
			viewsubmenu.add(_gridmenuitem);
			_gridmenuitem.set_active(false);
			
		var helpsubmenu=new Menu();
		helpmenuitem.set_submenu(helpsubmenu);
			var aboutmenuitem=new MenuItem.with_mnemonic(_("About"));
			helpsubmenu.add(aboutmenuitem);
			
		newmenuitem.activate.connect(()=>{newgame();});
		loadpuzzlemenuitem.activate.connect(()=>{loadgame();});
		savepuzzlemenuitem.activate.connect(()=>{savegame();});
		loadpositionmenuitem.activate.connect(()=>{loadposition();});
		savepositionmenuitem.activate.connect(()=>{saveposition();});
		quitmenuitem.activate.connect(()=>{quitgamesignal();});
		
		_showsolutionmenuitem.activate.connect(()=>{revealgame();});
		_showworkingmenuitem.activate.connect(()=>{hidegame();});
		_peeksolutionmenuitem.activate.connect(()=>{peekgame();});
		restartmenuitem.activate.connect(()=>{restartgame();});
		computersolvemenuitem.activate.connect(()=>{solvegame();});
		computergeneratemenuitem.activate.connect(()=>{randomgame();});
		
		colormenuitem.activate.connect(()=>{setcolors();});
		resizemenuitem.activate.connect(()=>{resizegame();});
		grademenuitem.activate.connect(getdifficulty);
		
		fullscreenmenuitem.activate.connect(toggle_fullscreen);
		toolbarmenuitem.activate.connect(toggle_toolbar);
		_gridmenuitem.activate.connect(()=>{togglegrid(_gridmenuitem.active);});

		aboutmenuitem.activate.connect(show_about);
		
		return menubar;
	}
//======================================================================
	private void create_viewer_toolbar()
	{
		_toolbar = new Toolbar();
		_toolbar.set_style(Gtk.ToolbarStyle.ICONS);
		
		var new_tool=new ToolButton.from_stock(Stock.CLEAR);
		new_tool.set_tooltip_text(_("New game"));
		_toolbar.add(new_tool);

		var load_tool=new ToolButton.from_stock(Stock.OPEN);
		load_tool.set_tooltip_text(_("Load game"));
		_toolbar.add(load_tool);

		var save_as_tool=new ToolButton.from_stock(Stock.SAVE_AS);
		save_as_tool.set_tooltip_text(_("Save game"));
		_toolbar.add(save_as_tool);

		var sep=new SeparatorToolItem();
		_toolbar.add(sep);

		_hide_tool=new ToggleToolButton.from_stock(Stock.EXECUTE);
		_hide_tool.set_tooltip_text(_("Hide the solution and start solving"));
		_hide_tool.active=false;
		_toolbar.add(_hide_tool);
		
		var peek_icon=new Gtk.Image.from_file(Resource.icon_dir+"/eyeballs.png");
		_peek_tool=new ToolButton(peek_icon,_("Peek"));
		_peek_tool.set_tooltip_text(_("Show solution"));
		_toolbar.add(_peek_tool);
		
		var restart_tool=new ToolButton.from_stock(Stock.REFRESH);
		restart_tool.set_tooltip_text(_("Start this puzzle again"));
		_toolbar.add(restart_tool);
		
		var sep2=new SeparatorToolItem();
		_toolbar.add(sep2);
				
		var solve_icon=new Gtk.Image.from_file(Resource.icon_dir+"/laptop.png");
		var solve_tool=new ToolButton(solve_icon,_("Solve"));
		solve_tool.set_tooltip_text(_("Solve by computer"));
		_toolbar.add(solve_tool);
		
		var random_icon=new Gtk.Image.from_file(Resource.icon_dir+"/Dices.png");
		var random_tool=new ToolButton(random_icon,_("Random"));
		random_tool.set_tooltip_text(_("Generate a random game"));
		_toolbar.add(random_tool);

		var sep3=new SeparatorToolItem();
		_toolbar.add(sep3);
		
		var grade_tool=new ToolItem();
		_grade_spin=new SpinButton.with_range(1,Resource.MAXGRADE,1);
		_grade_spin.set_tooltip_text(_("Set the difficulty of generated games"));
		_grade_spin.set_can_focus(false);
		grade_tool.add(_grade_spin);
		_toolbar.add(grade_tool);
		
		var resize_icon=new Gtk.Image.from_file(Resource.icon_dir+"/newsheet.png");
		var resize_tool=new ToolButton(resize_icon,_("Resize"));
		resize_tool.set_tooltip_text(_("Change dimensions of the game grid")); 
		_toolbar.add(resize_tool);

		var zoom_in_tool=new ToolButton.from_stock(Stock.ZOOM_IN);
		zoom_in_tool.set_tooltip_text(_("Increase font size"));
		_toolbar.add(zoom_in_tool);
		
		var zoom_out_tool=new ToolButton.from_stock(Stock.ZOOM_OUT);
		zoom_out_tool.set_tooltip_text(_("Decrease font size"));
		_toolbar.add(zoom_out_tool);

		
		new_tool.clicked.connect(()=>{newgame();});
		save_as_tool.clicked.connect(()=>{savegame();});
		load_tool.clicked.connect(()=>{loadgame();});
		_hide_tool.toggled.connect(toggle_execute);
		_peek_tool.clicked.connect(()=>{peekgame();});
		restart_tool.clicked.connect(()=>{restartgame();});
		solve_tool.clicked.connect(()=>{solvegame();});
		random_tool.clicked.connect(()=>{randomgame();});
		_grade_spin.value_changed.connect((sb)=>{setdifficulty(sb.get_value());});
		grade_tool.create_menu_proxy.connect(()=>{
			var grademenuitem2=new MenuItem.with_mnemonic(_("_Difficulty"));
			grademenuitem2.activate.connect(getdifficulty);
			grade_tool.set_proxy_menu_item("Difficulty", grademenuitem2);
			return true;
			}
		);
		resize_tool.clicked.connect(()=>{resizegame();});
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
	private void toggle_fullscreen(Gtk.MenuItem cmi)
	{	
		if (((Gtk.CheckMenuItem)cmi).active)
		{
			this.window.fullscreen();
		}
		else
		{
			this.window.unfullscreen();
		}
	}
//======================================================================
	private void toggle_toolbar(Gtk.MenuItem cmi)
	{	
		_toolbar.visible=((Gtk.CheckMenuItem)cmi).active;
	}
//======================================================================
	private void getdifficulty()
	{	
		var win=new Window(WindowType.TOPLEVEL);
		win.set_decorated(false);
		var grade_spin2=new SpinButton.with_range(1,10,1);
		grade_spin2.set_tooltip_text(_("Set the difficulty of generated games"));
		grade_spin2.set_can_focus(false);
		grade_spin2.set_value(_grade_spin.get_value());
		win.add(grade_spin2);
		win.leave_notify_event.connect(()=>{
			set_grade_spin_value(grade_spin2.get_value());
			win.destroy();
			return true;
			}
		);
		win.set_position(WindowPosition.MOUSE);
		win.show_all();
	}
//======================================================================
	private void show_about()
	{
		string[] authors={"Jeremy Wootten <jeremywootten@gmail.com>",null};
		show_about_dialog (null,
                       "program-name", "Gnonograms",
                       "version", "0.1.1",
                       "comments", "Set and solve gnonogram puzzles",
                       "license","Gnonograms is free software; you can redistribute it and/or modify it under the terms of the GNU General Public Licence as published by the Free Software Foundation; either version 2 of the Licence, or (at your option) any later version.\n\nGnonogram is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public Licence for more details.\n\nYou should have received a copy of the GNU General Public Licence along with Nautilus; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA",
                       "wrap_license",true,
                       "logo", _logo.get_pixbuf(),
                       "title", _("About Gnonogram Game"),
                       "authors", authors,
                       null);
	}
//======================================================================
	public void set_name(string name)
	{
		_statusbar.pop(_setting_context);
		_statusbar.push(_setting_context,name);
		_name=name;
	}

	public string get_name()
	{
		return _name;
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
	public void resize_image_box(int width, int height){
		_image_vbox.height_request=height;
		_image_vbox.width_request=width;
		_image_vbox.show();
	}
//======================================================================
	public void state_has_changed(GameState gs)
	{
		_peek_tool.sensitive=(gs==GameState.SOLVING);
		_peeksolutionmenuitem.sensitive=_peek_tool.sensitive;
		_showsolutionmenuitem.sensitive=_peek_tool.sensitive;
		_showworkingmenuitem.sensitive=!_peek_tool.sensitive;
		
		if (gs==GameState.SETTING)
		{
			_hide_tool.set_tooltip_text(_("Hide the solution and start solving"));
			_hide_tool.set_active(false);
			_gridmenuitem.set_active(false);
		}else
		{
			_hide_tool.set_tooltip_text(_("Reveal the solution"));
			_hide_tool.set_active(true);
			_gridmenuitem.set_active(true);
		}
	}
}
