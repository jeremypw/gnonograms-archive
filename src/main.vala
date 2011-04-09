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
 
 public enum GameState {
	SETTING,
	SOLVING
}

public enum CellState {
	UNKNOWN,
	EMPTY,
	FILLED,
	ERROR,
	COMPLETED
	}
	
public enum Gnonogram_FileType {
	GAME,
	POSITION
}
	
public struct Cell {
		public int row;
		public int col;
		public CellState state;
		public bool changed (int r, int c) {
			if (r!=row || c!=col) {
				row=r; col=c;
				return true; }
			else {
				return false;
			}
		}
	
		public void copy(Cell b) {
			this.row=b.row;
			this.col=b.col;
			this.state=b.state;
		}

		public Cell invert() {
			if (state==CellState.EMPTY) state=CellState.FILLED;
			else state=CellState.EMPTY;
			return this;
		}
	}

public enum ButtonPress {
	LEFT_SINGLE,
	LEFT_DOUBLE,
	MIDDLE_SINGLE,
	MIDDLE_DOUBLE,
	RIGHT_SINGLE,
	RIGHT_DOUBLE,
	UNDEFINED
}

//======================================================================

public static int main(string[] args)  {
	bool testing=false;
	bool debug=false;
	bool test_column=false;
	int test_idx=-1;
	int _start_rows=-1;
	int _start_cols=-1;
	
	for (int i=1;i<args.length;i++) {
		if (args[i]=="--test") {testing=true; _start_rows=1; _start_cols=10; debug=true; continue;}
		if (args[i]=="--rows") {_start_rows=int.parse(args[i+1]);i++;continue;}
		if (args[i]=="--cols") {_start_cols=int.parse(args[i+1]);i++;continue;}
		if (args[i]=="--debug") {
			if (args.length-i>=2) {
				debug=false;
				test_column=(args[i+1]=="column");
				test_idx=int.parse(args[i+2]);
			}
			else {debug=true;}
			continue;
		}
	}

	Resource.init(args[0]);
	Gtk.init(ref args);
	
	string package_name=Resource.APP_GETTEXT_PACKAGE;
	string langpackdir=Resource.get_langpack_dir();
	Intl.bindtextdomain(package_name, langpackdir);
	Intl.bind_textdomain_codeset(package_name, "UTF-8");
	Intl.textdomain(package_name);
	
	new Gnonogram_controller(_start_rows,_start_cols);//, testing, debug, test_column, test_idx);
	
	Gtk.main();
	return 0;
}


