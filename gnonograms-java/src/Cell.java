public class Cell
{
	public int row=-1;
	public int col=-1;
	//public CellState state=Resource.CELLSTATE_UNDEFINED;
	public int state=Resource.CELLSTATE_UNDEFINED;

	public Cell(int row, int col, int state)
	{
		this.row=row;
		this.col=col;
		this.state=state;
	}


	public boolean same_coords(Cell c)
	{
		return (this.row==c.row && this.col==c.col);
	}

	public void clear()
	{
		this.row=-1;
		this.col=-1;
		this.state=Resource.CELLSTATE_UNDEFINED;
	}

	public void set(int r, int c, int state)
	{
		this.row=r;
		this.col=c;
		this.state=state;
	}

	public int getRow(){
		return this.row;
	}

	public int getColumn(){
		return this.col;
	}

	public int getState(){
		return this.state;
	}

	public void copy(Cell b){
		this.row=b.row;
		this.col=b.col;
		this.state=b.state;
	}

	public Cell invert(){
		int newstate;
		if(this.state==Resource.CELLSTATE_EMPTY) newstate=Resource.CELLSTATE_FILLED;
		else newstate=Resource.CELLSTATE_EMPTY;
		return new Cell(this.row,this.col,newstate);
	}

}
