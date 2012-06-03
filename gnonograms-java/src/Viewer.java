/*
 * Viewer.java
 *
 * Copyright 2012 Jeremy Paul Wootten <jeremy@jeremy-laptop>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *
 */

import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JButton;
import javax.swing.BorderFactory;
import javax.swing.ImageIcon;
import javax.swing.JToolBar;
import javax.swing.AbstractAction;

import javax.imageio.ImageIO;

import java.awt.Graphics;
import java.awt.Color;
import java.awt.Container;
import java.awt.GridLayout;
import java.awt.GridBagLayout;
import java.awt.BorderLayout;
import java.awt.GridBagConstraints;
import java.awt.ComponentOrientation;
import java.awt.image.BufferedImage;
import java.awt.event.ActionEvent;

import java.io.File;
import java.io.IOException;

import static java.lang.System.out;



public class Viewer extends JFrame {
  private static final long serialVersionUID = 1;
  CellGrid drawing;
  JLabel [] rowlabels, collabels;
  Container contentpane;
  GridBagConstraints c;
  public LabelBox rowbox, colbox;
  public Controller control;
  BufferedImage rawLogo;
  ImageIcon scaledLogo;
  JLabel logoLabel;
  JToolBar toolbar;
  JPanel puzzlePane, toolbarPane;

  public Viewer(int rows, int cols, Controller control)
  {
    this.control=control;
    this.setSize(500,600);
    this.setDefaultCloseOperation(EXIT_ON_CLOSE);
    this.setTitle("Gnonograms");
    this.setResizable(true);
    scaledLogo=createImageIcon("images/gnonograms3-256.png","Logo");
    if (scaledLogo==null)
    {
      logoLabel=new JLabel("HELP!!");
    }
    else
    {
      scaledLogo=new ImageIcon(scaledLogo.getImage().getScaledInstance(100,100,BufferedImage.SCALE_SMOOTH));
      logoLabel=new JLabel(scaledLogo);
    }
    puzzlePane=new JPanel();
    puzzlePane.setLayout(new GridBagLayout());
    toolbarPane=new JPanel();
    toolbarPane.setLayout(new BorderLayout());
    toolbar=new JToolBar();
    createToolBar();
    toolbarPane.add(toolbar,BorderLayout.PAGE_START);
    contentpane=this.getContentPane();
    contentpane.setLayout(new BorderLayout());
    contentpane.add(toolbarPane,BorderLayout.PAGE_START);
    contentpane.add(puzzlePane,BorderLayout.CENTER);

    init(rows,cols);

    this.setVisible(true);
  }

  private void init(int rows, int cols)
  {
    rowbox=new LabelBox(rows, false, control);
    colbox=new LabelBox(cols, true, control);
    drawing=new CellGrid(rows, cols, control);

    c = new GridBagConstraints();
    c.gridx=1;
    c.gridy=1;
    c.gridwidth=cols;
    c.gridheight=rows;
    c.fill=GridBagConstraints.BOTH;
    c.weightx=cols;
    c.weighty=rows;
    puzzlePane.add(drawing,c);

    c = new GridBagConstraints();
    c.gridx=1;
    c.gridy=0;
    c.gridwidth=cols;
    c.gridheight=1;
    c.fill=GridBagConstraints.BOTH;
    c.weightx=1;
    c.weighty=1;
    c.anchor=GridBagConstraints.LINE_START;
    puzzlePane.add(colbox,c);

    c = new GridBagConstraints();
    c.gridx=0;
    c.gridy=1;
    c.gridwidth=1;
    c.gridheight=rows;
    c.fill=GridBagConstraints.BOTH;
    c.weighty=1;
    c.weightx=1;
    c.anchor=GridBagConstraints.PAGE_START;
    puzzlePane.add(rowbox,c);

    c = new GridBagConstraints();
    c.gridx=0;
    c.gridy=0;
    c.gridwidth=1;
    c.gridheight=1;
    c.weighty=1;
    c.fill=GridBagConstraints.NONE;
    c.anchor=GridBagConstraints.CENTER;
    puzzlePane.add(logoLabel,c);
  }

  public void setLabelText(int idx, String text, boolean isColumn){
    if (isColumn) colbox.setLabelText(idx,text);
    else rowbox.setLabelText(idx,text);
  }
  public String getLabelText(int idx, boolean isColumn){
    if (isColumn) return colbox.getLabelText(idx);
    else return rowbox.getLabelText(idx);
  }

  public void redrawGrid(){
    drawing.repaint();
  }

  public void setScore(String score){
    out.println("Score is: "+score);
  }

  private void createToolBar(){
    toolbar.add(new MyAction("New",createImageIcon("images/New24.gif","New icon"),"NEW_GAME"));
    toolbar.add(new MyAction("Random game",createImageIcon("images/dice.png","Random icon"),"RANDOM_GAME"));
    toolbar.add(new MyAction("Load game",createImageIcon("images/Open24.gif","Load icon"),"LOAD_GAME"));
    toolbar.add(new MyAction("Hide game",createImageIcon("images/eyes-closed.png","Hide icon"),"HIDE_GAME"));
    toolbar.add(new MyAction("Show game",createImageIcon("images/eyes-open.png","Show icon"),"SHOW_GAME"));
    toolbar.add(new MyAction("Solve game",createImageIcon("images/computer.png","Solve icon"),"SOLVE_GAME"));
  }

  private class MyAction extends AbstractAction{
    private static final long serialVersionUID = 1;
    public MyAction(String text, ImageIcon icon, String command){
      super(text, icon);
      putValue(ACTION_COMMAND_KEY, command);
    }
    @Override
    public void actionPerformed(ActionEvent a){
      String command=a.getActionCommand();
      if (command=="NEW_GAME") control.newGame();
      if (command=="LOAD_GAME") control.loadGame();
      if (command=="RANDOM_GAME") control.randomGame();
      if (command=="HIDE_GAME") control.hideSolution();
      if (command=="SHOW_GAME") control.showSolution();
      if (command=="SOLVE_GAME") control.userSolveGame();
    }
  }

  protected ImageIcon createImageIcon(String path,
                                           String description) {
    java.net.URL imgURL = this.getClass().getResource(path);
    if (imgURL != null) {
        return new ImageIcon(imgURL, description);
    } else {
        System.out.println("Couldn't find file: " + path);
        return null;
    }
  }

  public Dimension getDimensions(int r, int c){
    JDialog dialog=new JDialog(this,"Enter number of rows and column");
    //JButton okButton=new JButton(new MyAction("OK","images/);
    JButton cancelButton=new JButton("Cancel");
    JLabel rowLabel=new JLabel("Rows");
    JLabel columnLabel=new JLabel("Columns");
    JSpinner rowSpinner=new JSpinner(new SpinnerNumberModel(r,1,Resource.MAXSIZE,1));
    JSpinner columnSpinner=new JSpinner(new SpinnerNumberModel(1,c,Resource.MAXSIZE,1));



  }
}

