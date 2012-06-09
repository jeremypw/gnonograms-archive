import static java.lang.System.out;

public class Model {
	private int rows;
	private int cols;
	private My2DCellArray displayData;  //points to grid being displayed
	private My2DCellArray solutionData; //display when setting
	private My2DCellArray workingData; //display when solving
  private RandomPatternGenerator generator;
	private int[] temp;

  public Model(){
		rows = 10; cols = 10; //Must call set dimensions before use
		solutionData=new My2DCellArray(Resource.MAXIMUM_GRID_SIZE,Resource.MAXIMUM_GRID_SIZE,Resource.CELLSTATE_EMPTY);
		workingData=new My2DCellArray(Resource.MAXIMUM_GRID_SIZE,Resource.MAXIMUM_GRID_SIZE,Resource.CELLSTATE_UNKNOWN);
		//arr = new int[Resource.MAXIMUM_GRID_SIZE];
		displayData = solutionData;
  }

	public void clear(){
		blankSolution();	blankWorking();
	}

	public void blankSolution() {
    solutionData.setAll(Resource.CELLSTATE_EMPTY);
	}

	public void blankWorking(){
		workingData.setAll(Resource.CELLSTATE_UNKNOWN);
	}

	public void setDimensions(int r, int c){
		this.rows=r;this.cols=c;
    solutionData.resize(r,c); workingData.resize(r,c);
    generator=new RandomPatternGenerator(r,c);
	}

	public void useWorking(){displayData=workingData;}
	public void useSolution()	{displayData=solutionData;}

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

  public int getDataFromRC(int r, int c){return displayData.getDataFromRC(r,c);}

  public Cell getCell(int r, int c){return displayData.getCell(r,c);}

  public void setDataFromCell(Cell c){displayData.setDataFromCell(c);}

  public void setRowDataFromString(int r, String s){solutionData.setRowDataFromString(r,s);}

  public int countUnknownCells(){return displayData.countState(Resource.CELLSTATE_UNKNOWN);}

  public int countErrors(){return workingData.countDifferences(solutionData);}

  public void setGrade(double grade){
    generator.setGrade(grade);
  }

	public void generateRandomPattern(){
    solutionData.setAll(Resource.CELLSTATE_EMPTY);
    generator.generateBasicPattern();
    generator.adjustPattern();
  }

  private class RandomPatternGenerator {
    int[] temp;
    double rows2D, cols2D, middleOfColumn, middleOfRow;
		int maximumColumnBlockSize, maximumRowBlockSize;//, baselineOffset;
    int minimumRowFreedom, minimumColumnFreedom;

    public RandomPatternGenerator(int r, int c){
      rows2D=(double)(r);
      cols2D=(double)(c);
      middleOfColumn = rows2D/2.0;
      middleOfRow = cols2D/2.0;
    }

    private int calculatemaximumBlockSize(double lengthOfRegion, double grade){
      double max=1+(int)((lengthOfRegion-1)*(1.0-(grade/Resource.MAXIMUM_GRADE)));
      if (max>lengthOfRegion)max=lengthOfRegion;
      return (int)max;
    }

    protected void setMaximumBlockSizes(double grade){
      maximumColumnBlockSize=calculatemaximumBlockSize(rows2D,grade);
      //out.println("Max Col Block "+maximumColumnBlockSize);
      maximumRowBlockSize=calculatemaximumBlockSize(cols2D,grade);
      //out.println("Max Col Block "+maximumColumnBlockSize);
    }

    protected void setGrade(double grade){
      //out.println("Grade set to "+grade);
      setMaximumBlockSizes(grade);
      //baselineOffset=(int)(Resource.MAXIMUM_GRADE-grade)-10;
      minimumColumnFreedom = 2+(int)((rows*grade)/(Resource.MAXIMUM_GRADE*4));
      //out.println("min col freedom: "+minimumColumnFreedom);
      minimumRowFreedom = 2+(int)((cols*grade)/(Resource.MAXIMUM_GRADE*4));
      //out.println("min row freedom = "+minimumRowFreedom);
    }

    protected void generateBasicPattern(){
      for (int c=0;c<cols;c++){
        temp =solutionData.getColumn(c);
        temp=fillRegion(rows, temp, (int)(Math.abs((c-middleOfRow))), maximumColumnBlockSize);
        solutionData.setColumn (c, temp);
      }
      for (int r=0;r<rows;r++){
        temp=solutionData.getRow(r);
        temp=fillRegion(cols, temp, (int)(Math.abs((r-middleOfColumn))), maximumRowBlockSize);
        solutionData.setRow(r, temp);
      }
    }

    private int[] fillRegion (int sizeOfRegion, int[] region, int distanceFromCenter, int maximumBlockSize){
      int p=0, blockSize, max;
      //int baseline = Math.max(0,distanceFromCenter-baselineOffset);
      int cellState;
      boolean fill;
      while (p<sizeOfRegion){
        fill=getRandomInteger(0,100)>50;
        // random length up to remaining space but not larger than
        max=fill ? maximumBlockSize : (sizeOfRegion-maximumBlockSize);
        blockSize=Math.min(getRandomInteger(1,sizeOfRegion-1-p),max);
        //out.println("Block Size "+blockSize+" max: "+max+" p "+p);
        if (fill){
          for (int i=0; i<blockSize; i++){
            region[p]=Resource.CELLSTATE_FILLED;
            p++;
          }
          //at least one space between blocks
          if (p<sizeOfRegion) p++;
        }
        else p+=blockSize;
      }
      return region;
    }

    protected void adjustPattern(){
      if (rows>4){
        for (int c=0;c<cols;c++){
          temp =solutionData.getColumn(c);
          temp=adjustRegion(rows, temp, minimumColumnFreedom);
          solutionData.setColumn (c, temp);
        }
      }
      if (cols>4){
        for (int r=0;r<rows;r++){
          temp=solutionData.getRow(r);
          temp=adjustRegion(cols, temp, minimumRowFreedom);
          solutionData.setRow(r, temp);
        }
      }
    }
    private int[] adjustRegion(int sizeOfRegion, int [] region, int mindf)	{
		// mindf = minimum degrees of freedom
		int filledCells=0, filledBlocks=0, degreesOfFreedom=0;
		for (int i=0; i<sizeOfRegion; i++){
			if (region[i]==Resource.CELLSTATE_FILLED)	{
				filledCells++;
				if (i==0 || region[i-1]==Resource.CELLSTATE_EMPTY) filledBlocks++;
			}
		}
		degreesOfFreedom=sizeOfRegion-filledCells-filledBlocks+1;

		if (degreesOfFreedom>sizeOfRegion){//completely empty - fill one cell
			region[getRandomInteger(0,sizeOfRegion-1)]=Resource.CELLSTATE_FILLED;
		}
		else{ // empty cells until reach min freedom
			int count=0;
			while (degreesOfFreedom<mindf && count<30){
				count++;
				int i=getRandomInteger(0,sizeOfRegion-1);
				if (region[i]==Resource.CELLSTATE_FILLED)	{
					region[i]=Resource.CELLSTATE_EMPTY;
					degreesOfFreedom++;
				}
			}
		}
    return region;
	}
    private int getRandomInteger(int lower, int upper){
      double rand=Math.random();
      double range=(double)(upper-lower);
      return lower + (int)(range*rand);
    }
  }

  public String displayDataToString()
	{
		//stdout.printf("model to string\n");
		StringBuilder sb= new StringBuilder();
		for (int r=0; r<rows; r++)
		{
			temp=displayData.getRow(r);
			sb.append(Utils.stringFromIntArray(temp));
			sb.append("\n");
		}
		return sb.toString();
	}

}
