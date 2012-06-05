
import static java.lang.System.out;

public class Controller {

  private Viewer view;
  private Model model;
  private Solver solver;
  private int rows, cols;
  public boolean isSolving;
  private boolean haveSolution;
  private double grade;

	public Controller(int r, int c) {
    model=new Model();
    solver=new Solver(false,false,false,0,this);
    view=new Viewer(this);
    grade=5.0;
    init(r,c);
	}

  public void init(int r, int c){
    //out.println("Controller init");
    this.rows=r;
    this.cols=c;
    model.setDimensions(r,c);
   // model.setGrade(grade); //default grade pending implementation of user choice
    solver.setDimensions(r,c);
    view.setDimensions(r,c);
    setSolving(false);
    haveSolution=false;
  }

  public void resize(int r, int c){
    init(r,c);
    model.clear();
  }

  public void zoomFont(int change){view.zoomFont(change);}

  public void updateLabelsFromModel(int r, int c){
    if (isSolving) return;
    view.setLabelText(r, Utils.clueFromIntArray(model.getRow(r)),false);
    view.setLabelText(c, Utils.clueFromIntArray(model.getColumn(c)),true);
  }
  public void updateAllLabelsFromModel(){
    if (isSolving) return;
    for (int r=0;r<rows;r++){
      for(int c=0;c<cols;c++){
        updateLabelsFromModel(r,c);
      }
    }
  }
  public void updateLabelFromString(int idx, String clue, boolean isColumn){
    view.setLabelText(idx,clue,isColumn);
  }

  public int getDataFromRC(int r, int c){
   return model.getDataFromRC(r,c);
  }

  public void setDataFromCell(Cell c){
    model.setDataFromCell(c);
    if(isSolving){
      if(model.countUnknownCells()==0){
        if(model.countErrors()==0){
          Utils.showInfoDialog("Congratulations!");
          setSolving(false);
        }
      }
    }
  }

  public void newGame(){
    model.clear();
    setSolving(false);
    haveSolution=false;
    updateAllLabelText();
    view.redrawGrid();
  }
  public void restartGame(){
    model.blankWorking();
    setSolving(true);
    view.redrawGrid();
  }

  public void randomGame(double grade){
    int passes=-1;
    newGame();
    while (grade>0) {
      int count=0;
      model.setGrade(grade);
      while (count<30){
        count++;
        model.generateRandomPattern();
        updateAllLabelText();
        prepareToSolve(false,false,false);
        passes=solver.solveIt(false,false,false);
        if (passes>grade-1 && passes<grade+3) break;
      }
      if (count==30) {out.println("Failed to generate - try reducing grade"); grade--;}
      else {out.println("Passes "+passes); setSolving(true); break;}
    }
  }

  public void loadGame(){
    GameLoader gl=new GameLoader(view);
    int result=gl.getResult();
    if (result>0) return; //User cancelled
    this.newGame();

    try {gl.openDataInputStream();} //can chosen file be opened?
    catch (java.io.FileNotFoundException e){out.println(e.getMessage()); return;}

    try{gl.parseGameFile();} //is it a valid gnonogram puzzle?
    catch (java.util.NoSuchElementException e) {out.println(e.getMessage());}
    catch (Exception e) {out.println("Exception:  "+e.getMessage());}

    this.resize(gl.rows,gl.cols);

    if (gl.hasSolution){
      model.useSolution();
      for (int i=0; i<this.rows; i++) model.setRowDataFromString(i,gl.solution[i]);
			updateAllLabelsFromModel(); this.haveSolution=true;
    }
    if (gl.hasRowClues && gl.hasColumnClues){
			for (int i=0; i<this.rows; i++) view.setLabelText(i,gl.rowClues[i],false);
			for (int i=0; i<this.cols; i++) view.setLabelText(i,gl.colClues[i],true);
    }
    setSolving(true);
  }

  public void userSolveGame(){
    setSolving(true);
    prepareToSolve(true,false,false);
    int passes=solver.solveIt(false,false,false);
    switch (passes) {
			case -2:
				break;  //debug mode
			case -1:
				//invalid_clues();
				view.setScore("999999");
				break;
			case 0:
				Utils.showInfoDialog("Failed to solve or no unique solution");
				view.setScore("999999");
				break;
			case 999999:
				Utils.showInfoDialog("Cancelled by user");
				view.setScore("999999");
				break;
			default:
				view.setScore(String.valueOf(passes));
				//Utils.showInfoDialog(String.format("Solved in %8.3f seconds",secs_taken));

				if (!haveSolution){
					haveSolution=true;
					updateSolutionGridFromSolver();
				}
				break;
		}
    updateWorkingGridFromSolver();
    setSolving(true); //redisplay working grid
  }

	private void prepareToSolve(boolean use_startgrid, boolean use_advanced, boolean use_ultimate){ //out.println("Controller.prepare_to_solve\n");
		String[] rowClues= new String[this.rows];
		String[] columnClues= new String[this.cols];
    My2DCellArray startgrid;

		if (use_startgrid) {
			startgrid = new My2DCellArray(this.rows,this.cols,Resource.CELLSTATE_UNKNOWN);
			for(int r=0; r<this.rows; r++){
				for(int c=0;c<this.cols; c++){
					startgrid.setDataFromCell(model.getCell(r,c));
				}
			}
		}
		else startgrid=null;

		for (int i =0; i<this.rows; i++) rowClues[i]=view.getLabelText(i,false);
		for (int i =0; i<this.cols; i++) columnClues[i]=view.getLabelText(i, true);

		solver.initialize(rowClues, columnClues, startgrid);
  }

  public void updateWorkingGridFromSolver(){
    model.useWorking();
    setDisplayGridFromSolver();
    }
  public void updateSolutionGridFromSolver(){
    model.useSolution();
    setDisplayGridFromSolver();
    }
  private void setDisplayGridFromSolver()	{
		for (int r=0; r<this.rows; r++) {
			for(int c=0; c<=this.cols; c++) {
				model.setDataFromCell(solver.getCell(r,c));
			}
		}
	}

  private void updateAllLabelText(){
    String clue;
    for(int r=0;r<rows;r++){
      clue=Utils.clueFromIntArray(model.getRow(r));
      view.setLabelText(r,clue,false);
      view.setLabelToolTip(r,Utils.freedomFromClue(cols,clue),false);
    }
    for(int c=0;c<cols;c++){
      clue=Utils.clueFromIntArray(model.getColumn(c));
      view.setLabelText(c,clue,true);
      view.setLabelToolTip(c,Utils.freedomFromClue(rows,clue),true);
    }
  }

  public void setSolving(boolean isSolving){
    this.isSolving=isSolving;
    if (isSolving){
      model.useWorking();
    }else{
      model.useSolution();
    }
    view.setSolving(isSolving);
    view.redrawGrid();
  }
}
