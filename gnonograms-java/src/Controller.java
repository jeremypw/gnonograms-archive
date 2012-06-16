
import static java.lang.System.out;
import java.io.IOException;
import java.io.FileNotFoundException;

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
    this.rows=r; this.cols=c;
    model.setDimensions(r,c);
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
    view.setClueText(r, Utils.clueFromIntArray(model.getRow(r)),false);
    view.setClueText(c, Utils.clueFromIntArray(model.getColumn(c)),true);
    model.blankWorking();
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
    view.setClueText(idx,clue,isColumn);
  }

  public int getDataFromRC(int r, int c){
   return model.getDataFromRC(r,c);
  }

  public void setDataFromCell(Cell c){
    model.setDataFromCell(c);
    if(isSolving){
      if(model.countUnknownCells()==0){
        if(model.countErrors()==0){
          setSolving(false);
          view.redrawGrid();
          Utils.showInfoDialog("Congratulations!");
        }
        else{
          //TODO Check for alternative solution found
        }
      }
    }
  }

  public void newGame(){
    model.clear();
    setSolving(false);
    haveSolution=false;
    updateAllLabelText();
    view.clearInfoBar();
    view.validate();
  }

  public void restartGame(){
    model.blankWorking();
    setSolving(true);
    view.redrawGrid();
  }

  public void randomGame(double grade){
    int passes=-1;
    newGame();
    int count=0;
    model.setGrade(grade);
    int limit=(int)(20+10*grade);
    while (count<limit){
      count++;
      model.generateRandomPattern();
      updateAllLabelText();
      prepareToSolve(false,false,false);
      passes=solver.solveIt(false,false,false);
      if (passes>0) break;
    }
    if (count==limit) {}
    else {
      setSolving(true);
      haveSolution=true;
    }
    if (haveSolution){
    view.setScore(passes+" ");
    view.setName("Random");
    view.setAuthor("Computer");
    view.setLicense("GPL");
    view.setCreationDate("Today");
    }
    else {
      view.setScore("999999");
      Utils.showWarningDialog("Failed to generate puzzle - try reducing grade or grid size");
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

    if (!gl.validGame) {gl.close(); return;}
    view.setName(gl.name);
    view.setAuthor(gl.author);
    view.setCreationDate(gl.date);
    view.setScore(gl.score);
    view.setLicense(gl.license);
    this.resize(gl.rows,gl.cols);

    if (gl.hasSolution){
      model.useSolution();
      for (int i=0; i<this.rows; i++) model.setRowDataFromString(i,gl.solution[i]);
			updateAllLabelsFromModel(); this.haveSolution=true;
    }
    if (gl.hasRowClues && gl.hasColumnClues){
			for (int i=0; i<this.rows; i++) view.setClueText(i,gl.rowClues[i],false);
			for (int i=0; i<this.cols; i++) view.setClueText(i,gl.colClues[i],true);
    }
    setSolving(true);
    gl.close();
  }

  public void saveGame(){
    GameSaver gs=new GameSaver(view);
    int result=gs.getResult();
    if (result>0) return;
    try {gs.openDataOutputStream();}
    catch (IOException e){out.println("Error while opening game file: "+e.getMessage());return;}

    try {
      gs.writeDescription(view.getName(), view.getAuthor(), view.getCreationDate(), view.getScore());
      gs.writeLicense(view.getLicense());
      gs.writeDimensions(rows,cols);
      gs.writeClues(view.getClues(false),false);
      gs.writeClues(view.getClues(true),true);
      if (haveSolution) {
        model.useSolution();
        gs.writeSolution(model.displayDataToString());
      }
      model.useWorking();
      gs.writeWorking(model.displayDataToString());
      gs.writeState(isSolving);
    }
    catch (IOException e) {out.println("Error while writing game file: "+e.getMessage());}
    try {gs.close();}
    catch (IOException e){out.println("Error closing file:"+e.getMessage());}
  }

  public void userSolveGame(){
    setSolving(true);
    prepareToSolve(true,false,false);
    int passes=solver.solveIt(false,false,false);
    view.setScore("999999");
    String message="";
    switch (passes) {
			case -2://debug mode
      case 999999: //user cancelled
        break;
			case -1:	//invalid clues;
        model.clear();
        haveSolution=false;
        message="Invalid or inconsistent clues - no solution";
				break;
			case 0: //solver failed
				message="Failed to solve or no unique solution";
        updateWorkingGridFromSolver();
				break;
			default: //solver succeeded
				view.setScore(String.valueOf(passes));
				//Utils.showInfoDialog(String.format("Solved in %8.3f seconds",secs_taken));
				if (!haveSolution){
					haveSolution=true;
					updateSolutionGridFromSolver();
				}
        updateWorkingGridFromSolver();
				break;
		}
    if (message.length()>0) Utils.showInfoDialog(message);
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
		for (int i =0; i<this.rows; i++) rowClues[i]=view.getClueText(i,false);
		for (int i =0; i<this.cols; i++) columnClues[i]=view.getClueText(i, true);
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
			for(int c=0; c<this.cols; c++) {
				model.setDataFromCell(solver.getCell(r,c));
			}
		}
	}

  private void updateAllLabelText(){
    String clue;
    for(int r=0;r<rows;r++){
      clue=Utils.clueFromIntArray(model.getRow(r));
      view.setClueText(r,clue,false);
      view.setLabelToolTip(r,Utils.freedomFromClue(cols,clue),false);
    }
    for(int c=0;c<cols;c++){
      clue=Utils.clueFromIntArray(model.getColumn(c));
      view.setClueText(c,clue,true);
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
