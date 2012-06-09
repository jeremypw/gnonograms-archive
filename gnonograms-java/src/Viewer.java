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
import javax.swing.BoxLayout;
import javax.swing.Box;

import javax.imageio.ImageIO;

import java.awt.Graphics;
import java.awt.Color;
import java.awt.Container;
import java.awt.GridLayout;
import java.awt.GridBagLayout;
import java.awt.BorderLayout;

import java.awt.GridBagConstraints;
import java.awt.ComponentOrientation;
import java.awt.Font;

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
  private Container contentPane;
  private GridBagConstraints c;
  private LabelBox rowbox, colbox;
  private  Controller control;
  private BufferedImage rawLogo;
  private ImageIcon scaledLogo;
  private JLabel logoLabel;
  private InfoLabel  nameLabel,authorLabel,licenseLabel,scoreLabel,sizeLabel,dateLabel;
  private JToolBar toolbar;
  private JPanel puzzlePane, toolbarPane, infoPane;
  private int rows, cols;
  private int cluePointSize;
  private JSpinner gradeSpinner;

  public Viewer(Controller control)
  {
    this.control=control;
    this.setDefaultCloseOperation(EXIT_ON_CLOSE);
    this.setTitle("Gnonograms");
    this.setResizable(false);
    cluePointSize=20;

    scaledLogo=createImageIcon("images/gnonograms3-256.png","Logo");
    if (scaledLogo==null)logoLabel=new JLabel("MISSING ICON");
    else{
      scaledLogo=new ImageIcon(scaledLogo.getImage().getScaledInstance(128,128,BufferedImage.SCALE_SMOOTH));
      logoLabel=new JLabel(scaledLogo);
    }

    puzzlePane=new JPanel();
    puzzlePane.setLayout(new GridBagLayout());
    toolbarPane=new JPanel();
    toolbarPane.setLayout(new BorderLayout());
    createToolBar();
    toolbarPane.add(toolbar,BorderLayout.CENTER);
    createInfoPane();
    contentPane=this.getContentPane();
    contentPane.setLayout(new BorderLayout());
    contentPane.add(toolbarPane,BorderLayout.PAGE_START);
    contentPane.add(puzzlePane,BorderLayout.CENTER);
    contentPane.add(infoPane,BorderLayout.PAGE_END);
    //init(rows,cols);
  }

  public String getClueText(int idx, boolean isColumn){
    if (isColumn) return colbox.getClueText(idx);
    else return rowbox.getClueText(idx);
  }
  public double getGrade(){
    Object g=gradeSpinner.getValue();
    if (g==null || !(g instanceof Double))return 5.0;
    else return ((Double)(g)).doubleValue();
  }
  public String getScore() {return scoreLabel.getText();}
  public void setScore(String score){
    scoreLabel.setInfo(score);
  }
  public String getName() {return nameLabel.getText();}
  public void setName(String name){
    nameLabel.setInfo(name);
  }
  public String getAuthor() {return authorLabel.getText();}
  public void setAuthor(String author){
    authorLabel.setInfo(author);
  }
  public String getDate() {return dateLabel.getText();}
  public void setDate(String date){
    dateLabel.setInfo(date);
  }
  public String getLicense() {return licenseLabel.getText();}
  public void setLicense(String license){
    licenseLabel.setInfo(license);
  }

  public String getClues(boolean isColumn){
    if (isColumn) return colbox.getClues();
    else return rowbox.getClues();
  }

  private void setCluePointSize(){
    rowbox.setFontSize(cluePointSize, cols);
    colbox.setFontSize(cluePointSize, rows);
  }

  public void setLabelToolTip(int idx, int freedom, boolean isColumn){
    if (isColumn) colbox.setLabelToolTip(idx, freedom);
    else rowbox.setLabelToolTip(idx, freedom);
  }

  public void setSolving(boolean isSolving){
    drawing.setSolving(isSolving);
  }

  protected void resizeGame(){
    int[] d=askDimensions(rows,cols);
    if (d==null) return;
    else control.resize(d[0],d[1]);
  }

  private int[] askDimensions(int r, int c){
    int[] dimensions;
    DimensionsDialog dialog=new DimensionsDialog(this,r,c);
    dialog.setVisible(true);
    if (dialog.wasCancelled) dimensions=null;
    else dimensions=dialog.askDimensions();
    dialog.dispose();
    return dimensions;
  }

  public void setDimensions(int rows, int cols){
    //out.println("View set dimensions to "+rows+" rows "+cols+" cols");
    this.rows=rows; this.cols=cols;
    sizeLabel.setInfo(rows+"X"+cols);
    cluePointSize=250/(Math.max(rows,cols));
    if(cluePointSize<Resource.MINIMUM_CLUE_POINTSIZE) cluePointSize=Resource.MINIMUM_CLUE_POINTSIZE;
    else if(cluePointSize>Resource.MAXIMUM_CLUE_POINTSIZE) cluePointSize=Resource.MAXIMUM_CLUE_POINTSIZE;

    rowbox=new LabelBox(rows, false, control);
    colbox=new LabelBox(cols, true, control);
    drawing=new CellGrid(rows, cols, control);

    puzzlePane.removeAll();

    c = new GridBagConstraints();
    c.gridx=1;
    c.gridy=1;
    c.gridwidth=1;
    c.gridheight=1;
    c.fill=GridBagConstraints.BOTH;
    c.weightx=1;
    c.weighty=1;
    c.anchor=GridBagConstraints.CENTER;
    puzzlePane.add(drawing,c);

    c = new GridBagConstraints();
    c.gridx=1;
    c.gridy=0;
    c.gridwidth=1;
    c.gridheight=1;
    c.fill=GridBagConstraints.BOTH;
    c.weightx=1;
    c.weighty=1;
    c.anchor=GridBagConstraints.CENTER;
    puzzlePane.add(colbox,c);

    c = new GridBagConstraints();
    c.gridx=0;
    c.gridy=1;
    c.gridwidth=1;
    c.gridheight=1;
    c.fill=GridBagConstraints.BOTH;
    c.weighty=1;
    c.weightx=1;
    c.anchor=GridBagConstraints.CENTER;
    puzzlePane.add(rowbox,c);

    c = new GridBagConstraints();
    c.gridx=0;
    c.gridy=0;
    c.gridwidth=1;
    c.gridheight=1;
    c.fill=GridBagConstraints.BOTH;
    c.weightx=1;
    c.weighty=1;
    c.anchor=GridBagConstraints.CENTER;
    puzzlePane.add(logoLabel,c);

    setCluePointSize();
    this.setVisible(true);
    this.pack();
  }

  public void setLabelText(int idx, String text, boolean isColumn){
    if (isColumn) colbox.setLabelText(idx,text);
    else rowbox.setLabelText(idx,text);
  }

  public void zoomFont(int changeInPointSize){
    //out.println("View zoom font by " +changeInPointSize);
    if (changeInPointSize>0)cluePointSize++;
    else cluePointSize--;
    if(cluePointSize<4) cluePointSize=4;
    setCluePointSize();
    this.pack();
    setVisible(true);
  }

  public void redrawGrid(){drawing.repaint();}

  private void createToolBar(){
    toolbar=new JToolBar();
    toolbar.add(new MyAction("New",createImageIcon("images/New24.gif","New icon"),"NEW_GAME"));
    toolbar.add(new MyAction("Random game",createImageIcon("images/dice.png","Random icon"),"RANDOM_GAME"));
    gradeSpinner=new JSpinner(new SpinnerNumberModel(5,1,Resource.MAXIMUM_GRADE,1));
    toolbar.add(gradeSpinner);
    toolbar.add(new MyAction("Load game",createImageIcon("images/Open24.gif","Load icon"),"LOAD_GAME"));
    toolbar.add(new MyAction("Save game",createImageIcon("images/Save24.gif","Save icon"),"SAVE_GAME"));
    toolbar.add(new MyAction("Hide game",createImageIcon("images/eyes-closed.png","Hide icon"),"HIDE_GAME"));
    toolbar.add(new MyAction("Show game",createImageIcon("images/eyes-open.png","Show icon"),"SHOW_GAME"));
    toolbar.add(new MyAction("Solve game",createImageIcon("images/computer.png","Solve icon"),"SOLVE_GAME"));
    toolbar.add(new MyAction("Set Size",createImageIcon("images/resize.png","Solve icon"),"RESIZE_GAME"));
    toolbar.add(new MyAction("Restart",createImageIcon("images/Refresh24.gif","Restart icon"),"RESTART_GAME"));
    toolbar.add(new MyAction("Smaller",createImageIcon("images/ZoomOut24.gif","Restart icon"),"ZOOM_OUT"));
    toolbar.add(new MyAction("Larger",createImageIcon("images/ZoomIn24.gif","Restart icon"),"ZOOM_IN"));
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
      if (command=="SAVE_GAME") control.saveGame();
      if (command=="RANDOM_GAME") control.randomGame(getGrade());
      if (command=="HIDE_GAME") control.setSolving(true);
      if (command=="SHOW_GAME") control.setSolving(false);
      if (command=="SOLVE_GAME") control.userSolveGame();
      if (command=="RESIZE_GAME") resizeGame();
      if (command=="RESTART_GAME") control.restartGame();
      if (command=="ZOOM_IN") control.zoomFont(2);
      if (command=="ZOOM_OUT") control.zoomFont(-2);
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

  private void createInfoPane(){
    infoPane=new JPanel();
    infoPane.setLayout(new BoxLayout(infoPane,BoxLayout.LINE_AXIS));
    nameLabel=new InfoLabel("Name");
    authorLabel=new InfoLabel("Source");
    licenseLabel=new InfoLabel("(C)");
    dateLabel=new InfoLabel("Created");
    sizeLabel=new InfoLabel("Size");
    scoreLabel=new InfoLabel("Score");
    infoPane.add(nameLabel);
    infoPane.add(authorLabel);
    infoPane.add(licenseLabel);
    infoPane.add(dateLabel);
    infoPane.add(Box.createHorizontalGlue());
    infoPane.add(sizeLabel);
    infoPane.add(scoreLabel);
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
      rowSpinner=new JSpinner(new SpinnerNumberModel(r,1,Resource.MAXIMUM_GRID_SIZE,1));
      columnSpinner=new JSpinner(new SpinnerNumberModel(c,1,Resource.MAXIMUM_GRID_SIZE,1));
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

    public int[] askDimensions(){
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

  private class InfoLabel extends JLabel {
    private String info;
    private String heading;
    private static final long serialVersionUID = 1;

    public InfoLabel(String heading){
      this.info=".....";
      this.heading=heading;
      this.setBorder(BorderFactory.createEtchedBorder());
      this.setFont(new Font("Arial",Font.PLAIN,10));
      this.setInfo(this.info);
    }


    protected String getInfo(){
      return this.info;
    }

    protected void setInfo(String info){
      if (info.length()<1) this.info=".....";
      else this.info=info;
      this.setText(this.heading+":"+this.info+" ");
    }
  }
}

