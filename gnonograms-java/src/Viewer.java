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

import javax.swing.JDialog;
import javax.swing.JSpinner;
import javax.swing.SpinnerNumberModel;

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
import java.awt.event.ActionListener;


import java.io.File;
import java.io.IOException;

import static java.lang.System.out;



public class Viewer extends JFrame {
  private static final long serialVersionUID = 1;
  private CellGrid drawing;
  private JLabel [] rowlabels, collabels;
  private Container contentpane;
  private GridBagConstraints c;
  private LabelBox rowbox, colbox;
  private  Controller control;
  private BufferedImage rawLogo;
  private ImageIcon scaledLogo;
  private JLabel logoLabel;
  private JToolBar toolbar;
  private JPanel puzzlePane, toolbarPane;
  private int rows, cols;

  public Viewer(Controller control)
  {
    this.control=control;
    //this.setSize(500,600);
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
      scaledLogo=new ImageIcon(scaledLogo.getImage().getScaledInstance(128,128,BufferedImage.SCALE_SMOOTH));
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

    //init(rows,cols);

  }

  public void setDimensions(int rows, int cols)
  {
    out.println("View set dimensions to "+rows+" rows "+cols+" cols");
    this.rows=rows; this.cols=cols;

    rowbox=new LabelBox(rows, false, control);
    colbox=new LabelBox(cols, true, control);
    drawing=new CellGrid(rows, cols, control);

    puzzlePane.removeAll();

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

    this.setVisible(true);
    this.pack();
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
    toolbar.add(new MyAction("Set Size",createImageIcon("images/resize.png","Solve icon"),"RESIZE_GAME"));
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
      if (command=="HIDE_GAME") control.setSolving(true);
      if (command=="SHOW_GAME") control.setSolving(false);
      if (command=="SOLVE_GAME") control.userSolveGame();
      if (command=="RESIZE_GAME") resizeGame();
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

  protected void resizeGame(){
    int[] d=getDimensions(rows,cols);
    if (d==null) return;
    else control.resize(d[0],d[1]);
  }

  private int[] getDimensions(int r, int c){
    int[] dimensions;
    DimensionsDialog dialog=new DimensionsDialog(this,r,c);
    dialog.setVisible(true);
    if (dialog.wasCancelled) dimensions=null;
    else dimensions=dialog.getDimensions();
    dialog.dispose();
    return dimensions;
  }

  protected class DimensionsDialog extends JDialog implements ActionListener{
    private static final long serialVersionUID = 1;
    public boolean wasCancelled=true;
    private JLabel rowLabel,columnLabel;
    private JSpinner rowSpinner,columnSpinner;
    private JButton okButton, cancelButton;

    public DimensionsDialog(JFrame owner, int r, int c){
      super(owner, "Enter number of rows and columns", true);
      this.setLayout(new BorderLayout());
      this.setUndecorated(true);
      okButton=new JButton("OK");
      okButton.setActionCommand("DIMENSIONS_OK");
      okButton.addActionListener(this);
      cancelButton=new JButton("Cancel");
      cancelButton.setActionCommand("DIMENSIONS_CANCEL");
      cancelButton.addActionListener(this);
      rowLabel=new JLabel("Rows");
      columnLabel=new JLabel("Columns");
      rowSpinner=new JSpinner(new SpinnerNumberModel(r,1,Resource.MAXSIZE,1));
      columnSpinner=new JSpinner(new SpinnerNumberModel(c,1,Resource.MAXSIZE,1));
      JPanel buttonPanel=new JPanel();
      buttonPanel.setLayout(new BorderLayout());
      buttonPanel.add(okButton, BorderLayout.LINE_START);
      buttonPanel.add(cancelButton, BorderLayout.LINE_END);
      JPanel spinnerPanel=new JPanel();
      spinnerPanel.add(rowLabel);
      spinnerPanel.add(rowSpinner);
      spinnerPanel.add(columnLabel);
      spinnerPanel.add(columnSpinner);

      this.add(spinnerPanel,BorderLayout.PAGE_START);
      this.add(buttonPanel,BorderLayout.PAGE_END);

      this.pack();
    }

    public void actionPerformed(ActionEvent a){
      String command=a.getActionCommand();
      if (command=="DIMENSIONS_OK") wasCancelled=false;
      else wasCancelled=true;
      this.setVisible(false);
    }

    public int[] getDimensions(){
      Object r=rowSpinner.getValue();
      if (r==null || !(r instanceof Integer)) return null;
      Object c=columnSpinner.getValue();
      if (c==null || !(c instanceof Integer)) return null;
      int[] newDimensions=new int[2];
      newDimensions[0]=((Integer)r).intValue();
      newDimensions[1]=((Integer)c).intValue();

      return newDimensions;
    }
  }

  public void setSolving(boolean isSolving){
    drawing.setSolving(isSolving);
  }
}

