/* Viewer class for gnonograms-java
 * Constructs and Manages the GUI
 * Copyright 2012 Jeremy Paul Wootten <jeremywootten@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
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
import javax.swing.JComponent;
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
import java.awt.Dimension;
import java.awt.GridBagConstraints;
import java.awt.ComponentOrientation;
import java.awt.Font;
import java.awt.FontMetrics;

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
  private LabelBox rowBox, columnBox;
  private Controller control;
  private BufferedImage rawLogo;
  private ImageIcon scaledLogo;
  private JLabel logoLabel;
  private InfoLabel nameLabel,authorLabel,licenseLabel,scoreLabel,sizeLabel,dateLabel;
  private JToolBar toolbar;
  private JPanel puzzlePane, toolbarPane, infoPane;
  private int rows, cols;
  private int cluePointSize;
  private JSpinner gradeSpinner;

  public Viewer(Controller control){
    this.control=control;
    this.setDefaultCloseOperation(EXIT_ON_CLOSE);
    this.setTitle("Gnonograms");
    this.setResizable(false);
    this.setMaximumSize(new Dimension(1200,750));
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
  }

  public String getClueText(int idx, boolean isColumn){
    if (isColumn) return columnBox.getClueText(idx);
    else return rowBox.getClueText(idx);
  }
  public double getGrade(){
    Object g=gradeSpinner.getValue();
    if (g==null || !(g instanceof Double))return 5.0;
    else return ((Double)(g)).doubleValue();
  }
  public String getScore() {return scoreLabel.getInfo();}
  public void setScore(String score){scoreLabel.setInfo(score);}
  public String getName() {return nameLabel.getInfo();}
  public void setName(String name){nameLabel.setInfo(name);}
  public String getAuthor() {return authorLabel.getInfo();}
  public void setAuthor(String author){authorLabel.setInfo(author);}
  public String getCreationDate() {return dateLabel.getInfo();}
  public void setCreationDate(String date){dateLabel.setInfo(date);}
  public String getLicense() {return licenseLabel.getInfo();}
  public void setLicense(String license){licenseLabel.setInfo(license);}
  public void clearInfoBar(){
    setName("");
    setAuthor("");
    setCreationDate("");
    setLicense("");
    setScore("");
  }

  public void setSolving(boolean isSolving){
    drawing.setSolving(isSolving);
  }

  protected void resizeGame(){
    int[] d=getDimensions(rows,cols);
    if (d==null) return;
    else control.resize(d[0],d[1]);
  }

  private void editGame(){
    GameEditor ge=new GameEditor(this,rows, cols);
    ge.setGameName(getName());
    ge.setCreationDate(getCreationDate());
    ge.setAuthor(getAuthor());
    ge.setLicense(getLicense());
    for (int r=0; r<rows; r++) ge.setClue(r,rowBox.getClueText(r),false);
    for (int c=0; c<cols; c++) ge.setClue(c,columnBox.getClueText(c),true);

    ge.setVisible(true);

    if (ge.wasCancelled){}
    else{
      setName(ge.getGameName());
      setCreationDate(ge.getCreationDate());
      setAuthor(ge.getAuthor());
      setLicense(ge.getLicense());
      for (int r=0; r<rows; r++) rowBox.setClueText(r,ge.getClue(r,false));
      for (int c=0; c<cols; c++) columnBox.setClueText(c,ge.getClue(c,true));
      control.checkCluesValid(); 
    }
    ge.dispose();
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

  public void setDimensions(int rows, int cols){
    puzzlePane.removeAll();
    this.rows=rows; this.cols=cols;
    sizeLabel.setInfo(rows+"X"+cols);
    rowBox=new LabelBox(rows, false, control);
    columnBox=new LabelBox(cols, true, control);
    drawing=new CellGrid(rows, cols, control);
    c = new GridBagConstraints();
    c.gridx=1; c.gridy=1;
    c.gridwidth=1; c.gridheight=1;
    c.weightx=1;c.weighty=1;
    c.fill=GridBagConstraints.BOTH;
    c.anchor=GridBagConstraints.CENTER;
    puzzlePane.add(drawing,c);
    c.weightx=0;c.weighty=0;
    c.gridy=0; puzzlePane.add(columnBox,c);
    c.gridx=0; c.gridy=1; puzzlePane.add(rowBox,c);
    c.gridy=0; puzzlePane.add(logoLabel,c);
    this.setVisible(true);
    cluePointSize=calculateCluePointSize();
    setClueFontAndSize(cluePointSize);
    this.pack();
  }
  private int calculateCluePointSize(){
    return Resource.MINIMUM_CLUE_POINTSIZE+(4*Resource.MAXIMUM_CLUE_POINTSIZE)/(Math.max(rows,cols));
  }
  private void setClueFontAndSize(int pointSize){
    Font f=new Font("Arial",Font.BOLD,cluePointSize);
    FontMetrics fm= this.getGraphics().getFontMetrics(f);
    int fontHeight=fm.getHeight();
    int fontWidth=fm.stringWidth("0,");
    int boxAllocation=4+Math.max(fontHeight,fontWidth);
    rowBox.setFontAndSize(f, (int)(0.5*fontWidth*(cols+1)), boxAllocation);
    columnBox.setFontAndSize(f, boxAllocation, (int)(0.5*fontHeight*(rows+1)));
  }

  public void zoomFont(int changeInPointSize){
    if (changeInPointSize>0)cluePointSize++;
    else cluePointSize--;
    if(cluePointSize<Resource.MINIMUM_CLUE_POINTSIZE) cluePointSize=Resource.MINIMUM_CLUE_POINTSIZE;
    if(cluePointSize>Resource.MAXIMUM_CLUE_POINTSIZE) cluePointSize=Resource.MAXIMUM_CLUE_POINTSIZE;
    setClueFontAndSize(cluePointSize);
    this.pack();
    setVisible(true);
  }

  public void setClueText(int idx, String text, boolean isColumn){
    if (isColumn) columnBox.setClueText(idx,text);
    else rowBox.setClueText(idx,text);
  }

  public String getClues(boolean isColumn){
    if (isColumn) return columnBox.getClues();
    else return rowBox.getClues();
  }

  public void setLabelToolTip(int idx, int freedom, boolean isColumn){
    if (isColumn) columnBox.setLabelToolTip(idx, freedom);
    else rowBox.setLabelToolTip(idx, freedom);
  }

  public void redrawGrid(){drawing.repaint();}

  private void createToolBar(){
    toolbar=new JToolBar();
    gradeSpinner=new JSpinner(new SpinnerNumberModel(5,1,Resource.MAXIMUM_GRADE,1));
    int position=0;

    toolbar.add(new MyAction("New",createImageIcon("images/New24.gif","New icon"),"NEW_GAME"));
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Make a new blank puzzle grid");
    position++;

    toolbar.add(new MyAction("Random game",createImageIcon("images/dice.png","Random icon"),"RANDOM_GAME"));
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Generate a random puzzle");
    position++;

    toolbar.add(gradeSpinner);
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Set the difficulty of the generated puzzle");
    position++;

    toolbar.add(new MyAction("Load game",createImageIcon("images/Open24.gif","Load icon"),"LOAD_GAME"));
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Load a puzzle from file");
    position++;

    toolbar.add(new MyAction("Save game",createImageIcon("images/Save24.gif","Save icon"),"SAVE_GAME"));
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Save the puzzle to file");
     position++;

    toolbar.add(new MyAction("Hide game",createImageIcon("images/eyes-closed.png","Hide icon"),"HIDE_GAME"));
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Hide the solution and start solving");
     position++;

    toolbar.add(new MyAction("Show game",createImageIcon("images/eyes-open.png","Show icon"),"SHOW_GAME"));
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Show the solution to the puzzle");
     position++;

    toolbar.add(new MyAction("Check",createImageIcon("images/errorcheck.png","Check icon"),"CHECK_GAME"));
     position++;
    toolbar.add(new MyAction("Undo",createImageIcon("images/Undo24.gif","Undo icon"),"UNDO_MOVE"));
     position++;
    toolbar.add(new MyAction("Redo",createImageIcon("images/Redo24.gif","Redo icon"),"REDO_MOVE"));
     position++;

    toolbar.add(new MyAction("Restart",createImageIcon("images/Refresh24.gif","Restart icon"),"RESTART_GAME"));
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Start solving this puzzle again");
    position++;

    toolbar.add(new MyAction("Solve game",createImageIcon("images/computer.png","Solve icon"),"SOLVE_GAME"));
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Let the computer try to solve the puzzle");
     position++;

    toolbar.add(new MyAction("Set Size",createImageIcon("images/resize.png","Solve icon"),"RESIZE_GAME"));
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Set the number of rows and columns");
    position++;

    toolbar.add(new MyAction("Smaller",createImageIcon("images/ZoomOut24.gif","Soom Out icon"),"ZOOM_OUT"));
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Make the font smaller");
    position++;

    toolbar.add(new MyAction("Larger",createImageIcon("images/ZoomIn24.gif","Zoom In icon"),"ZOOM_IN"));
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Make the font larger");
    position++;

    toolbar.add(new MyAction("Edit",createImageIcon("images/Edit24.gif","Edit icon"),"EDIT_GAME"));
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Edit the description and clues");
    position++;
    
    toolbar.add(new MyAction("About",createImageIcon("images/About24.gif","About icon"),"ABOUT_GAME"));
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Edit the description and clues");
    position++;
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
      if (command.compareTo("NEW_GAME")==0) control.newGame();
      if (command.compareTo("LOAD_GAME")==0) control.loadGame();
      if (command.compareTo("SAVE_GAME")==0) control.saveGame();
      if (command.compareTo("RANDOM_GAME")==0) control.randomGame(getGrade());
      if (command.compareTo("HIDE_GAME")==0) control.setSolving(true);
      if (command.compareTo("SHOW_GAME")==0) control.setSolving(false);
      if (command.compareTo("SOLVE_GAME")==0) control.userSolveGame();
      if (command.compareTo("RESIZE_GAME")==0) resizeGame();
      if (command.compareTo("RESTART_GAME")==0) control.restartGame();
      if (command.compareTo("ZOOM_IN")==0) control.zoomFont(2);
      if (command.compareTo("ZOOM_OUT")==0) control.zoomFont(-2);
      if (command.compareTo("EDIT_GAME")==0) editGame();
      if (command.compareTo("CHECK_GAME")==0) control.checkGame();
      if (command.compareTo("UNDO_MOVE")==0) control.undoMove();
      if (command.compareTo("REDO_MOVE")==0) control.redoMove();
      if (command.compareTo("ABOUT_GAME")==0) Utils.showInfoDialog("Gnonograms for Java version "+Resource.VERSION_STRING+"\n\n by Jeremy Wootten\n<jeremywootten@gmail.com>");
    }
  }

  protected ImageIcon createImageIcon(String path,String description){
    java.net.URL imgURL = this.getClass().getResource(path);
    if (imgURL != null) return new ImageIcon(imgURL, description);
    else {
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

    public DimensionsDialog(JFrame owner, int r, int c){
      super(owner, "Enter number of rows and columns", true);
      this.setLayout(new BorderLayout());
      this.setUndecorated(true);
      rowLabel=new JLabel("Rows");
      columnLabel=new JLabel("Columns");
      rowSpinner=new JSpinner(new SpinnerNumberModel(r,1,Resource.MAXIMUM_GRID_SIZE,1));
      columnSpinner=new JSpinner(new SpinnerNumberModel(c,1,Resource.MAXIMUM_GRID_SIZE,1));
      JPanel spinnerPanel=new JPanel();
      spinnerPanel.add(rowLabel);
      spinnerPanel.add(rowSpinner);
      spinnerPanel.add(columnLabel);
      spinnerPanel.add(columnSpinner);

      this.add(spinnerPanel,BorderLayout.PAGE_START);
      this.add(Utils.okCancelPanelFactory(this,"DIMENSIONS_OK"),BorderLayout.PAGE_END);
      this.pack();
    }

    public void actionPerformed(ActionEvent a){
      String command=a.getActionCommand();
      if (command.compareTo("DIMENSIONS_OK")==0) wasCancelled=false;
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

    protected String getInfo(){return this.info;}

    protected void setInfo(String info){
      if (info.length()<1) this.info=".....";
      else this.info=info;
      this.setText(this.heading+":"+this.info+" ");
    }
  }
}

