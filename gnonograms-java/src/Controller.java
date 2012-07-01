/* Controller class for Gnonograms-java
 * Overall coordination of view, model and solver
 * Copyright (C) 2012  Jeremy Wootten
 *
  This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 *  Author:
 *  Jeremy Wootten <jeremwootten@gmail.com>
 */

import static java.lang.System.out;
import java.io.IOException;
import java.io.FileNotFoundException;
import java.util.Date;

public class Controller {

  private Viewer view;
  private Model model;
  private Solver solver;
  private MoveList history;
  private Config config;
  private int rows, cols;
  public boolean isSolving;
  private boolean validSolution;
  //private double grade;
  private boolean debug;
  private Date startDate, endDate;

  public Controller() {
    model=new Model();
    debug=false;
    solver=new Solver(false,debug,false,0,this);
    view=new Viewer(this);
    history=new MoveList();
    config=new Config();
    view.setGrade(config.getGrade());
    init(config.getRows(),config.getCols());
    view.setClueFontAndSize(config.getPointSize());
  }

  public void init(int r, int c){
    this.rows=r; this.cols=c;
    model.setDimensions(r,c);
    solver.setDimensions(r,c);
    view.setDimensions(r,c);
    newGame();
  }

  public void resize(int r, int c){
    init(r,c);
    view.setClueFontAndSize(calculateCluePointSize(r,c));
    model.clear();
  }

  private int calculateCluePointSize(int r, int c){
    return Resource.MINIMUM_CLUE_POINTSIZE+(3*Resource.MAXIMUM_CLUE_POINTSIZE)/(Math.max(r,c));
  }
  
  public void zoomFont(int change){
    view.zoomFont(change);
    config.setPointSize(view.getPointSize());
  }

  public int getDataFromRC(int r, int c){return model.getDataFromRC(r,c);}

  public My2DCellArray getCellDataArray(){return model.getCellDataArray();}

  public void setDataFromCell(Cell c){
    history.recordMove(c,model.getDataFromRC(c.getRow(),c.getColumn()));
    model.setDataFromCell(c);
    if(isSolving && model.countUnknownCells()==0 && model.countErrors()==0){
      endDate=new Date();
      setSolving(false);
      view.redrawGrid();
      Utils.showInfoDialog("Congratulations! Solved in "+Utils.calculateTimeTaken(startDate, endDate));
    }
  }
  
  public void quit(){
      //config.setRows(rows);
      //config.setCols(cols);
      //config.setGrade((int)view.getGrade());
      //config.setPointSize(view.getPointSize());
      config.saveProperties();
  }  
  
  public void editPreferences(){
      if (config.editPreferences(view)){
        int r=config.getRows(),c=config.getCols();
        view.setGrade(config.getGrade());
        view.setClueFontAndSize(config.getPointSize());
        if (rows!=r || cols!=c){
          rows=r;cols=c;
          resize(r,c);
        }
      }
  }

  public void newGame(){
    model.clear();
    history.initialize();
    setSolving(false);
    validSolution=true; //solution grid corresponds to clues
    updateAllLabelText();
    view.clearInfoBar();
    view.validate();
  }

  public void restartGame(){
    //if(isSolving) model.blankWorking();
    //else {
      //model.blankSolution();
      //this.updateAllLabelsFromModel();
    //}
    model.blankWorking();
    setSolving(true);
    startDate=new Date();  //should this be reset?
    history.initialize();
    view.redrawGrid();
  }
  
  public void checkGame(){
    if(isSolving){
      int numberOfErrors=model.countErrors()-model.countUnknownCells();
      if (numberOfErrors==0)Utils.showInfoDialog("There are no errors");
      else{
        if (Utils.showConfirmDialog("There are "+numberOfErrors+" errors\n\nGo back to last correct position?")){
          rewindGame();
        }
      }
    }
  }

  private void rewindGame(){
    while (model.countErrors()-model.countUnknownCells()>0){
      undoMove();
    }
    view.redrawGrid();
  }

  public void loadGame(){
    GameLoader gl=new GameLoader(view);
    int result=gl.getResult();
    if (result>0) return; //User cancelled
    
    newGame();
    try {gl.openDataInputStream();} //can chosen file be opened?
    catch (java.io.FileNotFoundException e){
      Utils.showErrorDialog(e.getMessage()); 
      return;
    }

    try{gl.parseGameFile();} //is it a valid gnonogram puzzle?
    catch (java.util.NoSuchElementException e) {
      Utils.showErrorDialog(e.getMessage()); 
      gl.close();
      return;
    }
    catch (Exception e) {
      Utils.showErrorDialog("Exception:  "+e.getMessage());
      gl.close();
      return;
    }

    if (!gl.validGame) {
      Utils.showErrorDialog("Not a valid game file");
      gl.close(); 
      return;
    }
    
    view.setName(gl.name);
    view.setAuthor(gl.author);
    view.setCreationDate(gl.date);
    view.setScore(gl.score);
    view.setLicense(gl.license);
    this.resize(gl.rows,gl.cols);

    if (gl.hasSolution){
      model.useSolution();
      for (int i=0; i<this.rows; i++) model.setRowDataFromString(i,gl.solution[i]);
      updateAllLabelsFromModel(); this.validSolution=true;
    }else {
      //Valid games either have Solution or Clues (or both)
      for (int i=0; i<this.rows; i++) view.setClueText(i,gl.rowClues[i],false);
      for (int i=0; i<this.cols; i++) view.setClueText(i,gl.colClues[i],true);
      if (!checkCluesValid()) {
        newGame();
        gl.close();
        return;
      }
    }
    
    if (gl.hasWorking){
      model.useWorking();
      for (int i=0; i<this.rows; i++){
        model.setRowDataFromString(i,gl.working[i]);
      }
    }
    setSolving(gl.state.contains("SOLVING"));
    view.redrawGrid();
    gl.close();
  }

  public void saveGame(){
    if (!checkCluesValid()) return; 
    GameSaver gs=new GameSaver(view);
    if (gs.getResult()>0) return;
    
    try {gs.openDataOutputStream();}
    catch (IOException e){out.println("Error while opening game file: "+e.getMessage());return;}

    try {
      gs.writeDescription(view.getName(), view.getAuthor(), view.getCreationDate(), view.getScore());
      gs.writeLicense(view.getLicense());
      gs.writeDimensions(rows,cols);
      gs.writeClues(view.getClues(false),false);
      gs.writeClues(view.getClues(true),true);
      if (validSolution) {
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
    setSolving(isSolving);
  }

  public void randomGame(double grade){
    newGame();
    model.setGrade(grade);
    //Try to generate a solvable pattern
    int passes=-1, count=0, limit=(int)(20+10*grade);
    //out.println("limit "+limit);
    while (count<limit){
      count++;
      model.generateRandomPattern();
      updateAllLabelText();
      prepareToSolve(false,false,false);
      passes=solver.solveIt(false,false,false); //only simple solver
      //out.println("COunt "+count+" passes "+passes);
      if (passes>grade-2) break;
    }
    
    if (count<limit){ //solvable pattern found
      //out.println("count < limit - passes"+passes);
      updateSolutionGridFromSolver();
      setSolving(true);
      validSolution=true;
      view.setScore(passes+" ");
      view.setName("Random");
      view.setAuthor("Computer");
      view.setLicense("GPL");
      view.setCreationDate("Today");
    }
    else { //timed out searching for solvable pattern
      //out.println("count >=limit - passes"+passes);
      view.setScore("999999");
      validSolution=false;
      Utils.showWarningDialog("Failed to generate puzzle - try reducing grade or grid size");
    }
  }

  public void userSolveGame(){
    prepareToSolve(true,false,false); //uses existing working grid as start point
    startDate=new Date();
    int result=solveGame();
    endDate=new Date();
    if (result>0&&result<99999){
      Utils.showInfoDialog("Solved in "+Utils.calculateTimeTaken(startDate,endDate)) ;
    }
    setSolving(true); //redisplay working grid
  }
  
  public int solveGame(){
    int passes=solver.solveIt(debug,false,false);
    view.setScore("999999");
    String message="";
    switch (passes) {
      case -2://debug mode
      case 999999: //user cancelled
        break;
      case -1:  //invalid clues;
        model.clear();
        validSolution=false;
        message="Invalid or inconsistent clues - no solution";
        break;
      case 0: //solver failed
        message="Failed to solve or no unique solution";
        updateWorkingGridFromSolver();
        break;
      default: //solver succeeded
        view.setScore(String.valueOf(passes));
       if (!validSolution){
          validSolution=true;
        }
        updateSolutionGridFromSolver();
        updateWorkingGridFromSolver();
        break;
    }
    if (message.length()>0) Utils.showInfoDialog(message);
    return passes;
  }

  private void prepareToSolve(boolean use_startgrid, boolean use_advanced, boolean use_ultimate){
    String[] rowClues= new String[this.rows];
    String[] columnClues= new String[this.cols];
    My2DCellArray startgrid;
    for (int i =0; i<this.rows; i++) rowClues[i]=view.getClueText(i,false);
    for (int i =0; i<this.cols; i++) columnClues[i]=view.getClueText(i, true);
    if (use_startgrid) solver.initialize(rowClues, columnClues, getCellDataArray());
    else solver.initialize(rowClues, columnClues, null);
}

  public boolean checkCluesValid(){
      boolean valid;
      model.blankWorking();
      prepareToSolve(false,false,false); //no start grid
      valid=(solveGame()>=0);
      setSolving(false);//used after editing so want to end up in setting mode
      out.println("Valid is "+valid);
      return valid;
  }
  
  public void updateWorkingGridFromSolver(){
    model.useWorking();
    setDisplayGridFromSolver();
    }
  public void updateSolutionGridFromSolver(){
    model.useSolution();
    setDisplayGridFromSolver();
    }
  private void setDisplayGridFromSolver() {
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
    }
    for(int c=0;c<cols;c++){
      clue=Utils.clueFromIntArray(model.getColumn(c));
      view.setClueText(c,clue,true);
    }
  }
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
 
  public void undoMove(){
    Move lm=history.getLastMove();
    if (lm==null) return;
    model.setDataFromCell(new Cell(lm.row,lm.col,lm.previousState));
    updateLabelsFromModel(lm.row,lm.col);
    view.redrawGrid();
  }
  public void redoMove(){
    Move lm=history.getNextMove();
    if (lm==null) return;
    model.setDataFromCell(new Cell(lm.row,lm.col,lm.replacementState));
    updateLabelsFromModel(lm.row,lm.col);
    view.redrawGrid();
  }
  
  public void setSolving(boolean isSolving){
    if (isSolving){
      model.useWorking();
      if (!this.isSolving){
         history.initialize();
         startDate=new Date();
      }
    }else{
      model.useSolution();
    }
    view.setSolving(isSolving);
    view.redrawGrid();
    this.isSolving=isSolving;
  }
}
