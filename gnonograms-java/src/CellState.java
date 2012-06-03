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

	static public CellState fromInteger(int i){
		switch (i){
			case 0: return UNKNOWN;
			case 1: return EMPTY;
			case 2: return FILLED;
			case 3: return ERROR;
			case 4: return COMPLETED;
			case 5: return ERROR_EMPTY;
			case 6: return ERROR_FILLED;
			default: return UNDEFINED;
		}
	}
}
