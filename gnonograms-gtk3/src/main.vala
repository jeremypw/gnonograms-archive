/* Main function for Gnonograms3
 * Initialises environment and launches game
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
public enum GameState
{
	SETTING,
	SOLVING;

	public string to_string()
	{
		switch (this)
		{
			case SETTING:
				return "GAME_STATE_SETTING";
			case SOLVING:
				return "GAME_STATE_SOLVING";
			default :
				return "";
		}
	}
}

public enum CellState
{
	UNKNOWN,
	EMPTY,
	FILLED,
	ERROR,
	COMPLETED,
	ERROR_EMPTY,
	ERROR_FILLED,
	UNDEFINED;

	public string to_string()
	{
		switch (this)
		{
			case UNKNOWN :
				return "UNKNOWN";
			case EMPTY :
				return "EMPTY";
			case FILLED :
				return "FILLED";
			case ERROR :
				return "ERROR";
			case COMPLETED :
				return "COMPLETED";
			case ERROR_EMPTY :
				return "INCORRECTLY EMPTY";
			case ERROR_FILLED :
				return "INCORRECTLY FILLED";
			default :
				return "UNDEFINED";
		}
	}
}

public enum CellPatternType
{
	NONE,
	RADIAL
}

public enum ButtonPress
{
	LEFT_SINGLE,
	LEFT_DOUBLE,
	MIDDLE_SINGLE,
	MIDDLE_DOUBLE,
	RIGHT_SINGLE,
	RIGHT_DOUBLE,
	UNDEFINED
}

public struct Cell
{
	public int row;
	public int col;
	public CellState state;

	public bool same_coords(Cell c)
	{
		return (this.row==c.row && this.col==c.col);
	}

	public void copy(Cell b)
	{
		this.row=b.row;
		this.col=b.col;
		this.state=b.state;
	}

	public Cell invert()
	{
		Cell c={this.row, this.col, CellState.UNKNOWN};
		if (this.state==CellState.EMPTY) c.state=CellState.FILLED;
		else c.state=CellState.EMPTY;
		return c;
	}

	public string to_string()
	{
		return @"Row $(this.row), Col $(this.col),  State $(this.state)";
	}
}

public struct Move
{
	public Cell previous;
	public Cell replacement;
}

Gnonogram_controller controller;

public static int main(string[] args)
{
	string game_filename="";
	string package_name=Resource.APP_GETTEXT_PACKAGE;

	if (args.length>=2) //a filename has been provided
	{
		game_filename=args[1];
		if (game_filename.has_suffix(".pattern")||game_filename.has_suffix(".gno")){}
		else game_filename="";
	}

	Gtk.init(ref args);
	Resource.init(args[0]);
	Intl.bindtextdomain(package_name, Resource.locale_dir);
	Intl.bind_textdomain_codeset(package_name, "UTF-8");
	Intl.textdomain(package_name);

	controller=new Gnonogram_controller(game_filename);

	Gtk.main();
	return 0;
}


