public class Model {
	private int rows;
	private int cols;
	private My2DCellArray displayData;  //points to grid being displayed
	private My2DCellArray solutionData; //display when setting
	private My2DCellArray workingData; //display when solving
	public int[] arr;

  public Model(){
		rows = 10; cols = 10; //Must call set dimensions before use
		solutionData=new My2DCellArray(Resource.MAXIMUM_GRID_SIZE,Resource.MAXIMUM_GRID_SIZE,Resource.CELLSTATE_EMPTY);
		workingData=new My2DCellArray(Resource.MAXIMUM_GRID_SIZE,Resource.MAXIMUM_GRID_SIZE,Resource.CELLSTATE_UNKNOWN);
		arr = new int[Resource.MAXIMUM_GRID_SIZE];
		displayData = solutionData;
  }

	public void clear(){
		blankSolution();	blankWorking();
	}

	public void blankSolution(){
		solutionData.setAll(Resource.CELLSTATE_EMPTY);
	}

	public void blankWorking(){
		workingData.setAll(Resource.CELLSTATE_UNKNOWN);
	}

	public void setDimensions(int r, int c){
		this.rows=r;this.cols=c;
    solutionData.resize(r,c);
    workingData.resize(r,c);
	}

	public void useWorking(){
		displayData=workingData;
	}

	public void useSolution()	{
		displayData=solutionData;
	}

  public int[] getRow(int idx){return displayData.getRow(idx);}
  public int[] getRow(int idx, boolean fromSolution){
    if (fromSolution) return solutionData.getRow(idx);
    else return workingData.getRow(idx);
  }
  public int[] getColumn(int idx){return displayData.getColumn(idx);}
  public int[] getColumn(int idx, boolean fromSolution){
    if (fromSolution) return solutionData.getColumn(idx);
    else return workingData.getColumn(idx);
  }

  public int getDataFromRC(int r, int c)
	{
		return displayData.getDataFromRC(r,c);
  }

  public Cell getCell(int r, int c){
    return displayData.getCell(r,c);
  }

  public void setDataFromCell(Cell c){displayData.setDataFromCell(c);}

  public void setRowDataFromString(int r, String s){solutionData.setRowDataFromString(r,s);}

  public int countUnknownCells(){
    return displayData.countState(Resource.CELLSTATE_UNKNOWN);
  }

  public int countErrors(){
    return workingData.countDifferences(solutionData);
  }

	public void fillRandom(double grade){
		int[] temp;
		solutionData.setAll(Resource.CELLSTATE_UNKNOWN);
		int midcol = rows/2;
		int midrow = cols/2;
		int mincdf = 2+(int)((rows*grade)/(Resource.MAXIMUM_GRADE*4));
		int minrdf = 2+(int)((cols*grade)/(Resource.MAXIMUM_GRADE*4));

		int maxb=(int)(cols*(1.0-grade/Resource.MAXIMUM_GRADE));
		for (int r=0;r<rows;r++){
			temp=solutionData.getRow(r);
			temp=fillRegion(cols, temp, grade, Math.abs((r-midcol)), maxb);
			solutionData.setRow(r, temp);
		}
		maxb=1+(int)(rows*(1.0-grade/Resource.MAXIMUM_GRADE));
		for (int c=0;c<cols;c++){
			temp =solutionData.getColumn(c);
			temp=fillRegion(rows, temp, grade, Math.abs((c-midrow)), maxb);
			solutionData.setColumn (c, temp);
		}

		for (int r=0;r<rows;r++){
			temp=this.getRow(r);
			adjustRegion(cols, temp,minrdf);
			solutionData.setRow(r, temp);
		}

		for (int c=0;c<cols;c++){
			temp=this.getColumn(c);
			adjustRegion(rows,temp,mincdf);
			solutionData.setColumn(c, temp);
		}
	}

	private int[] fillRegion (int size, int[] _arr, double grade, int e, int maxb)
	{
		//e is larger for rows/cols further from edge
		//do not want too many edge cells filled
		//maxb is maximum size of one random block
		//size is range of random number generator

		if (maxb<2) maxb=2;

		int p=0; //pointer
		int mid=size/2;
		int bsize; // blocksize
		int baseline = e+(int)grade-10;
		// baseline relates to the probability of a filled block before
		// adjusting for distance from edge of region.
		boolean fill;
		int max;
		int rand;
		while (p<size){
			// random choice whether to be full or empty, weighted so
			// less likely to fill squares close to edge
			fill=getRandomInteger(0,size)>(baseline+Math.abs((p-mid)));
			// random length up to remaining space but not larger than
			// maxb for filled cells or size-maxb for empty cells
			// bsize=int.min(_rand_gen.int_range(0,size-p),maxb);
			max=fill ? maxb : (size-maxb);
			rand=getRandomInteger(1,size-p);
			bsize=Math.min(rand,max);
			for (int i=0; i<bsize; i++){
				_arr[p++]=fill ? Resource.CELLSTATE_FILLED : Resource.CELLSTATE_EMPTY;
			}
			//at least one space between blocks
			if (fill && (p<size-1)) _arr[p++]=Resource.CELLSTATE_EMPTY;
		}
		return _arr;
	}

	private void adjustRegion(int s, int [] arr, int mindf)
	{
		//s is size of region
		// mindf = minimum degrees of freedom
		if (s<5) return;
		int b=0; // count of filled cells
		int bc=0; // count of filled blocks
		int df=0; // degrees of freedom
		for (int i=0; i<s; i++){
			if (arr[i]==Resource.CELLSTATE_FILLED)	{
				b++;
				if (i==0 || arr[i-1]==Resource.CELLSTATE_EMPTY) bc++;
			}
		}
		df=s-b-bc+1;

		if (df>s){//completely empty - fill one cell
			arr[getRandomInteger(0,s-1)]=Resource.CELLSTATE_FILLED;
		}
		else{ // empty cells until reach min freedom
			int count=0;
			while (df<mindf&&count<30){
				count++;
				int i=getRandomInteger(0,s-1);
				if (arr[i]==Resource.CELLSTATE_FILLED)	{
					arr[i]=Resource.CELLSTATE_EMPTY;
					df++;
				}
			}
		}
	}

	private int getRandomInteger(int lower, int upper){
		double rand=Math.random();
		double range=(double)(upper-lower);
		return lower + (int)(range*rand+0.9);
	}

}
