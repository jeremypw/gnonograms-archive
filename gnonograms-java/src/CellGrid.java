/* CellGrid class for Gnonograms-java
 * Displays the puzzle pattern and responds to mouse and keyboard
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

import java.awt.Graphics;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseMotionAdapter;
import java.awt.event.MouseEvent;
import java.awt.event.KeyAdapter;
import java.awt.event.KeyEvent;

import javax.swing.JPanel;
import javax.swing.BorderFactory;

import java.lang.Math;

import static java.lang.System.out;

public class CellGrid extends JPanel{

  private static final long serialVersionUID = 1;
  private int rows, cols, currentRow, currentCol;
  private double rowHeight, columnWidth;
  private Cell currentCell, previousCell;
  private Color[] solvingColors;
  private Color[] settingColors;
  private Color[] displayColors;
  private Graphics myGraphics;

  public Controller control;

  public CellGrid(int rows, int cols, Controller control) {
    this.control=control;
    this.rows=rows;
    this.cols=cols;
    this.addMouseListener(new GridMouseAdapter());
    this.addMouseMotionListener(new GridMouseMotionAdapter());
    this.addKeyListener(new GridKeyAdapter());
    this.setBorder(BorderFactory.createLineBorder(Color.black));

    currentCell=new Cell(-1,-1,Resource.CELLSTATE_UNDEFINED);
    previousCell=new Cell(-1,-1,Resource.CELLSTATE_UNDEFINED);
    currentRow=-1;
    currentCol=-1;
    
    solvingColors=new Color[8];
    for(Color c : solvingColors) c=Color.orange;
    solvingColors[Resource.CELLSTATE_FILLED]=Color.blue;
    solvingColors[Resource.CELLSTATE_EMPTY]=Color.yellow;
    solvingColors[Resource.CELLSTATE_UNKNOWN]=(new Color(240,240,240,255));
    settingColors=new Color[8];
    for(Color c : settingColors)c=Color.orange;
    settingColors[Resource.CELLSTATE_FILLED]=Color.black;
    settingColors[Resource.CELLSTATE_EMPTY]=Color.white;
    settingColors[Resource.CELLSTATE_UNKNOWN]=Color.red;
    displayColors=settingColors;
  }

@Override
  public void paintComponent(Graphics g) {
    int gridWidth=this.getWidth();
    int gridHeight=this.getHeight();
    rowHeight=((double)gridHeight)/((double)rows);
    columnWidth=(double)(gridWidth)/((double)cols);

    //Draw cell bodies
    for (int r=0;r<rows;r++){
     for(int c=0;c<cols;c++){
       g.setColor(displayColors[control.getDataFromRC(r,c)]);
       g.fillRect((int)(c*columnWidth+1),(int)(r*rowHeight+1),(int)(columnWidth),(int)(rowHeight));
     }
    }
    g.setColor(Color.gray);
    for (int r=0;r<rows;r++){
      int h=(int)(r*rowHeight);
      g.drawLine(0,h,gridWidth,h);
    }
    for (int c=0;c<cols;c++){
      int w=(int)(c*columnWidth);
      g.drawLine(w, 0, w, gridHeight);
    }

    // Draw major gridlines
    g.setColor(Color.black);
    for (int r=0;r<=rows;r+=5){
      int h=(int)(r*rowHeight);
      g.drawLine(0,h,gridWidth,h);
      g.drawLine(0,h+1,gridWidth,h+1);
    }
    for (int c=0;c<=cols;c+=5){
      int w=(int)(c*columnWidth);
      g.drawLine(w, 0, w, gridHeight);
      g.drawLine(w+1, 0, w+1, gridHeight);
    }

    //draw current cell outline
    highlightCell(currentRow, currentCol);
  }

  public void moveHighlightRelative(int rowchange, int colchange){
    moveHighlight(currentRow+rowchange,currentCol+colchange);
  }
  
  protected void moveHighlight(int r, int c){
      if (r== currentRow && c== currentCol) return;
      unhighlightCell(currentRow,currentCol);
      if (r<0||r>rows||c<0||c>=cols) return;
      highlightCell(r,c);
      currentRow= r; currentCol= c;
  }
  protected void highlightCell(int r, int c){
    if (r<0||r>rows||c<0||c>=cols) return;
    myGraphics=this.getGraphics();
    myGraphics.setColor(Color.red);
    myGraphics.drawRect((int)(c*columnWidth+2),(int)(r*rowHeight+2),(int)(columnWidth-3),(int)(rowHeight-3));
    myGraphics.drawRect((int)(c*columnWidth+3),(int)(r*rowHeight+3),(int)(columnWidth-5),(int)(rowHeight-5));
  }
  protected void unhighlightCell(int r, int c){
    if (r<0||r>rows||c<0||c>=cols) return;
    myGraphics=this.getGraphics();
    myGraphics.setColor(displayColors[control.getDataFromRC(r,c)]);
    myGraphics.drawRect((int)(c*columnWidth+2),(int)(r*rowHeight+2),(int)(columnWidth-3),(int)(rowHeight-3));
    myGraphics.drawRect((int)(c*columnWidth+3),(int)(r*rowHeight+3),(int)(columnWidth-5),(int)(rowHeight-5));
  }

  public void updateCurrentCell(int state){
    updateCell(currentRow,currentCol,state);
  }
  
  protected void updateCell(int r,int c,int cs){
    if (cs==Resource.CELLSTATE_UNDEFINED) return;
    currentCell.set(r,c,cs);
    control.setDataFromCell(currentCell);
    control.updateLabelsFromModel(r,c);
    repaint();
  }

  public void setSolving(boolean isSolving){
    if(isSolving) displayColors=solvingColors;
    else displayColors=settingColors;
  }

  private class GridMouseAdapter extends MouseAdapter{

    public void mousePressed(MouseEvent e) {
     int r= (int)((double)(e.getY())/rowHeight);
     int c= (int)((double)(e.getX())/columnWidth);
     int x= (int)(c*columnWidth)+1;
     int y= (int)(r*rowHeight)+1;
     int b= e.getButton();
     int cs=Resource.CELLSTATE_UNDEFINED;

     if (e.getClickCount()>1) b=MouseEvent.BUTTON2;

     switch (b){
        case MouseEvent.BUTTON1:
        cs=Resource.CELLSTATE_FILLED;
        break;
       case MouseEvent.BUTTON2:
        if(control.isSolving) cs=Resource.CELLSTATE_UNKNOWN;
        break;
       case MouseEvent.BUTTON3:
        cs=Resource.CELLSTATE_EMPTY;
        break;
       default :
        break;
     }
      updateCell(r,c,cs);
    }
    public void mouseExited(MouseEvent e) {
     currentCell.clear();
     previousCell.clear();
    }
    public void mouseEntered(MouseEvent e) {
     requestFocus();
    }
  }

  private class GridMouseMotionAdapter extends MouseMotionAdapter{

    public void mouseDragged(MouseEvent e) {
      int r= (int)((double)(e.getY())/rowHeight);
      int c= (int)((double)(e.getX())/columnWidth);
      if (r== currentRow && c== currentCol) return;
      if (r<0||r>rows||c<0||c>=cols) return;
      currentRow= r;
      currentCol= c;
      updateCell(r,c,currentCell.getState());
    }
    public void mouseMoved(MouseEvent e){
      int r= (int)((double)(e.getY())/rowHeight);
      int c= (int)((double)(e.getX())/columnWidth);
      moveHighlight(r,c);
    }
  }

  private class GridKeyAdapter extends KeyAdapter{
    public void keyPressed(KeyEvent e){
      int keyCode =e.getKeyCode();
      switch (keyCode){
        case KeyEvent.VK_MINUS:
              control.zoomFont(-2);
              break;
        case KeyEvent.VK_PLUS:
        case KeyEvent.VK_EQUALS:
              control.zoomFont(2);
              break;
        case KeyEvent.VK_KP_LEFT:
        case KeyEvent.VK_LEFT:
              if (currentCol>0) moveHighlight(currentRow,currentCol-1);
              break;
        case KeyEvent.VK_KP_RIGHT:
        case KeyEvent.VK_RIGHT:
              if (currentCol<cols-1) moveHighlight(currentRow,currentCol+1);
              break;
        case KeyEvent.VK_KP_UP:
        case KeyEvent.VK_UP:
              if (currentRow>0) moveHighlight(currentRow-1,currentCol);
              break;
        case KeyEvent.VK_KP_DOWN:
        case KeyEvent.VK_DOWN:
              if (currentRow<rows-1) moveHighlight(currentRow+1,currentCol);
              break;
        case Resource.KEY_FILLED:
              updateCell(currentRow,currentCol,Resource.CELLSTATE_FILLED);
              break;
        case Resource.KEY_EMPTY:
              updateCell(currentRow,currentCol,Resource.CELLSTATE_EMPTY);
              break;
        case Resource.KEY_UNKNOWN:
              if(control.isSolving)updateCell(currentRow,currentCol,Resource.CELLSTATE_UNKNOWN);
              break;
        case KeyEvent.VK_S:
              if (e.isControlDown()) control.saveGame();
              break;
        default:
          break;
      }
    }
  }
}
