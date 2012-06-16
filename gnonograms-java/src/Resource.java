import java.awt.event.KeyEvent;

public class Resource
{
	static final String BLOCKSEPARATOR=",";
	static final double MAXIMUM_GRADE=9;
	static final int MAXIMUM_GRID_SIZE=35;
	static final int MAXIMUM_CLUE_POINTSIZE=72;
	static final int MINIMUM_CLUE_POINTSIZE=8;

	static final int CELLSTATE_UNKNOWN=0;
	static final int CELLSTATE_EMPTY=1;
	static final int CELLSTATE_FILLED=2;
	static final int CELLSTATE_ERROR=3;
	static final int CELLSTATE_COMPLETED=4;
	static final int CELLSTATE_ERROR_EMPTY=5;
	static final int CELLSTATE_ERROR_FILLED=6;
	static final int CELLSTATE_UNDEFINED=7;

  static final int KEY_FILLED=KeyEvent.VK_F;
  static final int KEY_EMPTY=KeyEvent.VK_E;
  static final int KEY_UNKNOWN=KeyEvent.VK_X;

}
