
import static java.lang.System.out;

public class Controller {

  private Viewer view;
  private Model model;
  private Solver solver;
  private int rows, cols;
  private boolean isSolving;
  private boolean haveSolution;

	public Controller(int r, int c) {
    model=new Model();
    solver=new Solver(false,false,false,0,this);
    init(r,c);
	}

  public void init(int r, int c){
    this.rows=r;
    this.cols=c;
    model.setDimensions(r,c);
    model.useSolution();
    solver.setDimensions(r,c);
		view=new Viewer(r,c,this);
    isSolving=false;
    haveSolution=false;
  }

  private void resize(int r, int c){
    view.dispose();
    model.clear();
    init(r,c);
  }

  public void updateLabelsFromModel(int r, int c){
    if (isSolving) return;
    view.setLabelText(r, Utils.clueFromintArray(model.getRow(r)),false);
    view.setLabelText(c, Utils.clueFromintArray(model.getColumn(c)),true);
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
  }

  public void newGame(){
    model.clear();
    model.useSolution();
    isSolving=false;
    haveSolution=false;
    updateAllLabelText();
    view.redrawGrid();
  }

  public void randomGame(){
    double grade=5;
    int passes;
    model.clear();
    model.useSolution();
    while (true){
      model.fillRandom(grade);
      updateAllLabelText();
      prepareToSolve(false,false,false);
      passes=solver.solveIt(false,false,false);
      if (passes>0 && passes<9999) break;
    }
    hideSolution();
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

    resize(gl.rows,gl.cols);
    if (gl.hasSolution){
      model.useSolution();
      for (int i=0; i<this.rows; i++) model.setRowDataFromString(i,gl.solution[i]);
			updateAllLabelsFromModel(); this.haveSolution=true;
    }
    if (gl.hasRowClues && gl.hasColumnClues){
			for (int i=0; i<this.rows; i++) view.setLabelText(i,gl.rowClues[i],false);
			for (int i=0; i<this.cols; i++) view.setLabelText(i,gl.colClues[i],true);
    }
    hideSolution();
  }

  public void hideSolution(){
    model.useWorking();
    isSolving=true;
    out.println("Using working - solve mode");
    view.redrawGrid();
  }

  public void showSolution(){
    model.useSolution();
    isSolving=false;
    out.println("Using solution - design mode");
    view.redrawGrid();
  }

  public void userSolveGame(){
    hideSolution();
    prepareToSolve(false,false,false);
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
    hideSolution(); //redisplay working grid
  }

	private void prepareToSolve(boolean use_startgrid, boolean use_advanced, boolean use_ultimate)
	{out.println("Controller.prepare_to_solve\n");
		String[] rowClues= new String[this.rows];
		String[] columnClues= new String[this.cols];

		//if (use_startgrid) {
			//startgrid = new My2DCellArray(this.rows,this.cols,Resource.CELLSTATE_UNKNOWN);
			//for(int r=0; r<this.rows; r++){
				//for(int c=0;c<this.cols; c++){
					//startgrid.set_data_from_cell(model.getCell(r,c));
				//}
			//}
		//}
		//else startgrid=null;

		for (int i =0; i<this.rows; i++) rowClues[i]=view.getLabelText(i,false);
		for (int i =0; i<this.cols; i++) columnClues[i]=view.getLabelText(i, true);

		solver.initialize(rowClues, columnClues, null);
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
    for(int r=0;r<rows;r++){
      view.setLabelText(r, Utils.clueFromintArray(model.getRow(r)),false);
    }
    for(int c=0;c<cols;c++){
      view.setLabelText(c, Utils.clueFromintArray(model.getColumn(c)),true);
    }
  }
}
