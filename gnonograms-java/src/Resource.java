/* Resource class for gnonograms-java
 * Defines various values in one place
 * Copyright 2012 Jeremy Paul Wootten <jeremywootten@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *
 */
 import java.awt.event.KeyEvent;
 import java.awt.Color;

public class Resource
{
  static final String BLOCKSEPARATOR=",";
  static final String VERSION_STRING="0.6.4";
  static final double MAXIMUM_GRADE=12;
  static final int MAXIMUM_GRID_SIZE=60;
  static final int MAXIMUM_CLUE_POINTSIZE=72;
  static final int MINIMUM_CLUE_POINTSIZE=4;
  static final int DEFAULT_ROWS=10;
  static final int DEFAULT_COLS=15;
  static final int DEFAULT_GRADE=5;

  static final int CELLSTATE_UNKNOWN=0;
  static final int CELLSTATE_EMPTY=1;
  static final int CELLSTATE_FILLED=2;
  static final int CELLSTATE_ERROR=3;
  static final int CELLSTATE_COMPLETED=4;
  static final int CELLSTATE_ERROR_EMPTY=5;
  static final int CELLSTATE_ERROR_FILLED=6;
  static final int CELLSTATE_UNDEFINED=7;
  
  static final int GAME_STATE_SETTING=0;
  static final int GAME_STATE_SOLVING=1;
  static final int GAME_STATE_LOADING=2;
  static final int DEFAULT_STARTSTATE= GAME_STATE_SOLVING;
  

  static final int KEY_FILLED=KeyEvent.VK_F;
  static final int KEY_EMPTY=KeyEvent.VK_E;
  static final int KEY_UNKNOWN=KeyEvent.VK_X;
  
  static final Color HIGHLIGHT_COLOR=Color.gray;

}
