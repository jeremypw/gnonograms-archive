/* Solver class for Gnonograms-java
 * Finds solution for a set of clues
 * Copyright (C) 2010-2011  Jeremy Wootten
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
 * 	Jeremy Wootten <jeremwootten@gmail.com>
 */

import static java.lang.System.out;

 public class Solver {

	private int rows;
	private int cols;
	private int regionCount;
  private Controller control;
	public My2DCellArray grid;
	private Region[] regions;
	private Cell trialCell;
	private int rdir;
	private int cdir;
	private int rlim;
	private int clim;
	private int turn;
	private int maxTurns;
	private int guesses=0;
	private int counter=0;
  private int maxvalue=999999;
	private boolean testing;
	private boolean debug;
	private boolean testColumn;
	private int testIdx;

	//public signal void updateWorkingGridFromSolver();
	//public signal void showprogress(int guesses);

	int GUESSESBEFOREASK=50000;


	public Solver(boolean testing, boolean debug, boolean testColumn, int testIdx, Controller control){
    this.control=control;
		grid=new My2DCellArray(Resource.MAXSIZE, Resource.MAXSIZE);
		regions=new Region[Resource.MAXSIZE+Resource.MAXSIZE];

		for (int i=0;i<regions.length;i++) regions[i]=new Region(grid);

		//For development purposes only
		this.testing=testing;
		this.debug=debug;
		this.testColumn=testColumn;
		this.testIdx=testIdx;
		//
	}

  //public Solver(){
    //Solver(false,false,false-1);
  //}

	public void setDimensions(int r, int c)	{
		rows=r; cols=c;
	}

	public boolean initialize(String[] rowclues, String[] colclues, My2DCellArray startgrid){
		if (rowclues.length!=rows || colclues.length!=cols)	{
			out.println("row/col size mismatch\n");
			return false;
		}

    grid.setAll(Resource.CELLSTATE_UNKNOWN);
		//if (startgrid==null) grid.setAll(Resource.CELLSTATE_UNKNOWN);
		//else grid.copy(startgrid);

		//Create regions
		//Dont create regions of length 1
		regionCount=0;
		if(cols>1) {
			for (int r=0; r<rows; r++){
				regions[r].initialize(r, false,cols,rowclues[r]);
				regionCount++;
			}
		}
		if(rows>1){
			for (int c=0; c<cols; c++){
				regions[c+rows].initialize(c,true,rows,colclues[c]);
				regionCount++;
			}
		}
		guesses=0; counter=0;
		return valid();
	}

	public boolean valid(){
		for (Region r : regions)	{
      if (r.inError) return false;
    }
		return true;
	}

	public String geterror(){
		for (int i=0; i<regionCount; i++){
			if (regions[i].inError) return regions[i].message;
		}
    return "No error";
	}

	public int solveIt(boolean debug, boolean useadvanced, boolean useultimate)	{
		int simpleresult=simplesolver(debug,true); //log errors
		if (simpleresult==0 && useadvanced)
		{	if (!debug || Utils.showConfirmDialog(("Use advanced solver?"))){
				int[] gridstore= new int[rows*cols];
				int advancedresult=advancedsolver(gridstore, debug);
				if (advancedresult>0){
					if(advancedresult==999999 && useultimate){
						return ultimatesolver(gridstore, debug);
					}	else 	return advancedresult;
				}
			}
		}else	return simpleresult;
		return 0;
	}

	public boolean getHint()	{
		//Solver must be initialised with current state of puzzle before calling.
		int		pass=1;
		while (pass<=30){
			//cycle through regions until one of them is changed then returns
			//that region index.
			for (int i=0; i<regionCount; i++){
				if (regions[i].isCompleted) continue;
				if (regions[i].solve(false,true)) {//run solve algorithm in hint mode
					//out.println("Changed region %d\n",i);
					control.updateWorkingGridFromSolver();
					return true;
				}
				if (regions[i].inError){
					Utils.showWarningDialog(("A logical error has already been made - cannot hint"));
					return false;
				}
			}
			pass++;
		}
		if (pass>30){
			if (solved()) Utils.showInfoDialog(("Already solved"));
      else Utils.showInfoDialog(("Simple solver could not find hint\n"));
		}
		return false;
	}

	private int simplesolver(boolean debug, boolean logerror){
		out.println("Simple solver  debug "+debug+"  region count "+regionCount+"\n");
		boolean changed=true;
		int pass=1;
		while (changed && pass<30){
			//keep cycling through regions while at least one of them is changing (up to 30 times)
			changed=false;
			for (int i=0; i<regionCount; i++){
				if (regions[i].isCompleted) continue;
				if (regions[i].solve(debug,false)) changed=true;
				if (debug ||(logerror && regions[i].inError)){
					if(regions[i].message!="") out.println("Region - "+i+": "+regions[i].message+"\n");
				}
				if (regions[i].inError) return -1;
			}

			pass++;
			if (debug){
				control.updateWorkingGridFromSolver();
				if (!Utils.showConfirmDialog("Simple solver pass "+pass+" ... continue?")) return 0;
			}
		}
		if (solved()) return pass;
		if (pass>30) Utils.showWarningDialog("Simple solver - too many passes\n");
		return 0;
	}

	public boolean solved(){
		for (int i=0; i<regionCount; i++){
			if (!regions[i].isCompleted) return false;
		}
		return true;
	}

	private int advancedsolver(int[] gridstore, boolean debug)
	{
		// out.println("Advanced solver\n");
		// single cell guesses, depth 1 (no recursion)
		// make a guess in each unknown cell in turn
		// if leads to contradiction mark opposite to guess,
		// continue simple solve, if still no solution start again.
		// if does not lead to solution leave unknown and choose another cell
		int simpleresult=0;
		int wraps=0;
		boolean changed=false;
		int initialmaxTurns=3; //stay near edges until no more changes
		int initialcellstate=Resource.CELLSTATE_FILLED;

		rdir=0; cdir=1; rlim=rows; clim=cols;
		turn=0; maxTurns=initialmaxTurns;
		trialCell= new Cell(0,-1,initialcellstate);//{0,-1,initialcellstate};

		this.saveposition(gridstore);
		while (true)
		{
			incrementcounter();
			makeguess();

			if (trialCell.col==-1) //run out of guesses
			{
				if (changed){}
				else if (maxTurns==initialmaxTurns)
				{
					maxTurns=(Math.min(rows,cols))/2+2; //ensure full coverage
				}
				else if(trialCell.state==initialcellstate)
				{
					trialCell=trialCell.invert(); //start making opposite guesses
					maxTurns=initialmaxTurns; wraps=0;
				}
				else break; //cant make progress

				rdir=0; cdir=1; rlim=rows; clim=cols; turn=0;
				changed=false;
				wraps++;
				continue;
			}
			grid.setDataFromCell(trialCell);
			simpleresult=simplesolver(false,false); //only debug advanced part, ignore errors

			if (simpleresult>0) break; //solution found

			loadposition(gridstore); //back track
			if (simpleresult<0) //contradiction -  try opposite guess
			{
				grid.setDataFromCell(trialCell.invert()); //mark opposite to guess
				changed=true; //worth trying another cycle
				simpleresult=simplesolver(false,false);//can we solve now?
				if (simpleresult==0)
				{
					this.saveposition(gridstore); //update grid store
					continue; //go back to start
				}
				else 	if (simpleresult>0) break; // solution found
				else return -1; //starting point was invalid
			}
			else	continue; //guess again
		}
		//return vague measure of difficulty
		if (simpleresult>0) return simpleresult+guesses;
		return 999999;
	}

	private void saveposition(int[] gs)
	{
		//store grid in linearised form.
		//out.println("Save position\n");
		for(int r=0; r<rows; r++)
		{	for(int c=0; c<cols; c++)
			{
				gs[r*cols+c]=grid.getDataFromRC(r,c);
			}
		}
		for (int i=0; i<regionCount; i++) regions[i].savestate();
	}

	private void loadposition(int[] gs)
	{
		//out.println("Load position\n");
		for(int r=0; r<rows; r++)
		{	for(int c=0; c<cols; c++)
			{
				grid.setDataFromRC(r,c, gs[r*cols+c]);
			}
		}
		for (int i=0; i<regionCount; i++) regions[i].restorestate();
	}

	private void makeguess()
	{
		//Scan in spiral pattern from edges.  Critical cells most likely in this region
		int r=trialCell.row;
		int c=trialCell.col;

		while (true)
		{
			r+=rdir; c+=cdir; //only one changes at any one time
			if (cdir==1 && c>=clim) {c--;cdir=0;rdir=1;r++;} //across top - rh edge reached
			else if (rdir==1 && r>=rlim) {r--;rdir=0;cdir=-1;c--;} //down rh side - bottom reached
			else if (cdir==-1 && c<turn) {c++; cdir=0;rdir=-1;r--;} //back across bottom lh edge reached
			else if (rdir==-1 && r<=turn) {r++;turn++;rlim--;clim--;rdir=0;cdir=1;} //up lh side - top edge reached
			if (turn>maxTurns) {trialCell.row=0;trialCell.col=-1;break;} //stay near edge until no more changes
			if (grid.getDataFromRC(r,c)==Resource.CELLSTATE_UNKNOWN)
			{
				trialCell.row=r; trialCell.col=c;
				return;
			}
		}
		return;
	}

	public Cell getCell(int r, int c)
	{
		return grid.getCell(r,c);
	}

	private int ultimatesolver(int[] gridstore, boolean debug)
	{
		//out.println("Ultimate solver\n");
		int permreg=-1, maxvalue=999999, advancedresult=-99, simpleresult=-99;
		int limit=GUESSESBEFOREASK;

		loadposition(gridstore); //return to last valid state
		for (int i=0; i<regionCount; i++) regions[i].initialstate();
		simplesolver(false,true); //make sure region state correct

		control.updateWorkingGridFromSolver();
		if(!Utils.showConfirmDialog(("Start Ultimate solver?\n This can take a long time and may not work"))) return 999999;

		int[] gridstore2 = new int[rows*cols];
		int[] guess={};

		while (true)
		{
			permreg=choosePermuteRegion(maxvalue);
			if (permreg<0) {out.println("No perm region found\n");break;}

			int start;
			Permutor p=regions[permreg].getPermutor();

			if (p==null|| p.valid==false){out.println("No valid permutator generated\n");break;}

      start=p.start;

			boolean iscolumn=regions[permreg].isColumn;
			int idx=regions[permreg].index;

			//try advanced solver with every possible pattern in this range.

			for (int i=0; i<regionCount; i++) regions[i].initialstate();
			saveposition(gridstore2);

			p.initialise();
			while (p.next())
			{
				incrementcounter();
				if (guesses>limit)
				{
					if(Utils.showConfirmDialog(("This is taking a long time!")+"\n"+("Keep trying?"))) limit+=GUESSESBEFOREASK;
					else return 999999;
				}
				guess=p.get();

				grid.setArray(idx,iscolumn,guess,start);
				simpleresult=simplesolver(false,false);

				if(simpleresult==0)
				{
					advancedresult=advancedsolver(gridstore, debug);
					if (advancedresult>0 && advancedresult<999999) return advancedresult; //solution found
				}
				else if (simpleresult>0) return simpleresult+guesses; //unlikely!

				loadposition(gridstore2); //back track
				for (int i=0; i<regionCount; i++) regions[i].initialstate();
			}
			loadposition(gridstore2); //back track

			for (int i=0; i<regionCount; i++) regions[i].initialstate();
			simplesolver(false,false);
		}
		return 0;
	}

	private int choosePermuteRegion(int maxvalue)	{
		int bestvalue=-1, currentvalue, permreg=-1,edg;
		for (int r=0;r<regionCount;r++)
		{
			currentvalue=regions[r].valueaspermuteregion();
			//weight towards edge regions
			if (currentvalue==0)continue;
			if (r<rows)edg=Math.min(r,rows-1-r);
			else edg=Math.min(r-rows,rows+cols-r-1);
			edg+=1;
			currentvalue=currentvalue*100/edg;
			if (currentvalue>bestvalue&&currentvalue<maxvalue)
			{
				bestvalue=currentvalue;
				permreg=r;
			}
		}
		maxvalue=bestvalue;
		return permreg;
	}

	private void incrementcounter()
	{
		////provide visual feedback
		//guesses++;	counter++;
		//if(counter==100)
		//{
			//showprogress(guesses); //signal to controller
			//Utils.processevents();
			//counter=0;
		//}
	}
}
