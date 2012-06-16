/* GameLoader class for gnonograms-java
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
import javax.swing.JFileChooser;
import javax.swing.filechooser.FileNameExtensionFilter;

import java.awt.Component;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;

import java.util.Scanner;
import java.util.NoSuchElementException;
import static java.lang.System.out;


public class GameLoader extends JFileChooser {
  private static final long serialVersionUID = 1;
	//public String game_path="";
	public int rows=0;
	public int cols=0;
	public String[] rowClues;
	public String[] colClues;
	public String state;
	public String name="";
	public String author="";
	public String date="";
	public String score="";
	public String license="";
	public boolean validGame=false;
	public boolean hasDimensions=false;
	public boolean hasRowClues=false;
	public boolean hasColumnClues=false;
	public boolean hasSolution=false;
	public boolean has_working=false;
	public boolean has_state=false;
	public String[] solution;
	public String[] working;

	private Scanner dataStream;
	private String[] headings;
	private String[] bodies;


  private int result, headingCount;

	public GameLoader(Component parent)	{
    super();
    this.setFileSelectionMode(FILES_ONLY);
    this.setFileFilter(new FileNameExtensionFilter("Gnonogram Puzzles","gno"));
    this.setDialogTitle("Choose a puzzle");
    result=this.showOpenDialog(parent);
 	}

  public int getResult(){
    return this.result;
  }
  public String getFileName(){
    return getName(getSelectedFile());
  }

	public void openDataInputStream() throws FileNotFoundException{
    dataStream= new Scanner(new FileReader(getSelectedFile()));
	}

  public void close(){dataStream.close();}

	public void parseGameFile() throws IOException, NoSuchElementException, Exception {
		headingCount=-1;
    String nextToken="";
    headings=new String[10];
    bodies=new String[10];

    //int len = nextLine.length();
    dataStream.useDelimiter("\\]");
    //out.println("Starting");
    while (nextToken!=null){
      try {nextToken=dataStream.next();}
      catch (Exception e){break;}
      //out.println("Next Token:\n"+nextToken);
      if(nextToken.startsWith("[")){
        headingCount++;
        headings[headingCount]=nextToken.substring(1);
        dataStream.useDelimiter("\\[");
      } else {
        bodies[headingCount]=nextToken.substring(2);
        dataStream.useDelimiter("\\]");
      }
    }
		parseGnonogramHeadingsAndBodies();
    validGame=true;
	}

	private boolean parseGnonogramHeadingsAndBodies() throws Exception
	{
    int headingID;
		for (int i=0;i<=headingCount;i++){
			headingID=headingToInt(headings[i]);
      //out.println(headingID);
			switch (headingID)	{
				case 1:
					getGnonogramDimensions(bodies[i]); break;
				case 2 :
					getGnonogramClues(bodies[i],false); break;
				case 3 :
					getGnonogramClues(bodies[i],true); break;
				case 4 :
					getGnonogramCellstateArray(bodies[i],true); break;
				case 5:
					getGnonogramCellstateArray(bodies[i],false); break;
				case 6:
					getGnonogramState(bodies[i]); break;
				case 7:
					getGameDescription(bodies[i]); break;
				case 8:
					get_game_license(bodies[i]); break;
				default :
          out.println("Unrecognised heading");
					break;
			}
		}
		return false;
	}

  private int headingToInt(String heading){
      if (heading==null||heading.length()<3) return -1;
			if (heading.length()>3) heading=heading.substring(0,3).toUpperCase();
      //out.println("heading :"+heading+":");
      if (heading.compareTo("DIM")==0) return 1;
      if (heading.compareTo("ROW")==0) return 2;
      if (heading.compareTo("COL")==0) return 3;
      if (heading.compareTo("SOL")==0) return 4;
      if (heading.compareTo("WOR")==0) return 5;
      if (heading.compareTo("STA")==0) return 6;
      if (heading.compareTo("DES")==0) return 7;
      if (heading.compareTo("LIC")==0) return 8;
      return 0;
  }

	private void getGnonogramDimensions(String body) throws NumberFormatException, Exception{
		//out.println("In get_dimensions\n");
    String[] s=splitString(body,"\n",2,3);
		rows=new Integer(s[0]);
		cols=new Integer(s[1]);

    if (rows<1 || cols<1 || rows>Resource.MAXIMUM_GRID_SIZE || cols> Resource.MAXIMUM_GRID_SIZE) throw new Exception("Dimensions out of range:"+rows+","+cols);
    else hasDimensions=true;
	}

	private void getGnonogramClues(String body, boolean isColumn) throws Exception{
		//out.println("In get_clues\n");
    String[] s=splitString(body,"\n",isColumn?cols:rows,isColumn?cols:rows);
    String[] arr=new String[s.length];
		for (int i=0; i< s.length; i++){
			arr[i]=parseGnonogramClue(s[i],isColumn);
		}
		if (isColumn){
        colClues=arr;
        hasColumnClues=true;
		}
		else{
        rowClues=arr;
        hasRowClues=true;
		}
	}
	private String parseGnonogramClue(String line, boolean isColumn) throws NumberFormatException, Exception {
    //out.println("Clue line :"+line+":");
		String[] sa=splitString(line,"[\\D\\n]",1,isColumn?rows:cols); //split on non-digit or EOL
		int b, zero_count=0;
		int maxblock=isColumn?rows:cols;
    //out.println("Clue line had "+sa.length+" tokens");
		StringBuilder sb=new StringBuilder(200);
		for (int i=0; i<sa.length; i++){
			// ignore extraneous non-digits (allow one zero)
      //out.println("Token "+i+" is "+ sa[i]);
      try{b=new Integer(sa[i]);}
      catch (NumberFormatException e){out.println("Not a number:"+sa[i]); continue;}
      if (b<0||b>maxblock) throw new Exception("Invalid block size in clue");
      if (b==0 && zero_count>0) continue;
      else zero_count++;
      if(i>0)sb.append(Resource.BLOCKSEPARATOR);
			sb.append(sa[i]);
		}
		return sb.toString();
	}

	private void getGnonogramCellstateArray(String body, boolean is_solution) throws Exception{
		//out.println("In getintArray\n");
    String[] s=splitString(body,"\n",rows,110);
		if (s.length!=rows) throw new Exception("Wrong number of rows in solution or working grid");
		for (int i=0; i<s.length;i++){
			int[] arr = Utils.cellStateArrayFromString(s[i]);
			if (arr.length!=cols) throw new Exception("Too few columns in grid");
			if (is_solution){
				for (int c=0;c<cols;c++){
					if(arr[c]!=Resource.CELLSTATE_EMPTY && arr[c]!=Resource.CELLSTATE_FILLED) throw new Exception("Invalid cell state"+arr[c]);
				}
			}
		}
		if (is_solution){	solution=s;	hasSolution=true;}
		else{working=s;has_working=true;}
	}

	private void getGnonogramState(String body) throws Exception{
		//out.println("In get_state\n");
    String[] s = splitString(body,"\n",1,3);
		state=s[0];
		if (state.contains("SETTING") || state.contains("SOLVING")) has_state=true;
    else throw new Exception("Invalid Game State"+state+"Options: 'SETTING' or 'SOLVING'");
	}

	private void getGameDescription(String body) throws Exception{
		//out.println("In get_description\n");
		String[] s = splitString(body,"\n",1,10);
		if (s.length>=1) name=convertHtml(s[0]);
		if (s.length>=2) author=convertHtml(s[1]);
		if (s.length>=3) date=s[2];
		if (s.length>=4) score=s[3];
	}
  private String convertHtml(String s){return s;}

	private void get_game_license(String body) throws Exception{
		//out.println("In get_license\n");
		String[] s = splitString(body,"\n",1,2);
			if (s[0].length()>50)license=s[0].substring(0,50);
			else license=s[0];
	}

  private String[] splitString(String body, String delimiter, int minTokens, int maxTokens) throws Exception {
		if (body==null) throw new Exception("Null string to split");
    String[] s = Utils.removeBlankLines(body.split(delimiter,maxTokens));
    if (s.length<minTokens) throw new Exception("Too few tokens");
    return s;
  }

}

