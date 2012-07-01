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
import java.awt.Component;
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
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;

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
  protected ImageIcon hideIcon, revealIcon;
  private JLabel logoLabel;
  private InfoLabel nameLabel,authorLabel,licenseLabel,scoreLabel,sizeLabel,dateLabel;
  private JToolBar toolbar;
  private JPanel puzzlePane, toolbarPane, infoPane;
  private int rows, cols;
  private int cluePointSize;
  private JSpinner gradeSpinner;
  private JButton hiderevealButton;

  public Viewer(Controller control){
    this.control=control;
    this.setDefaultCloseOperation(EXIT_ON_CLOSE);
    this.setTitle("Gnonograms for Windows");
    this.setResizable(false);
    this.setMaximumSize(new Dimension(1200,750));
    cluePointSize=20;

    scaledLogo=createImageIcon("images/gnonograms3-256.png","Logo");
    if (scaledLogo==null)logoLabel=new JLabel("MISSING ICON");
    else{
      scaledLogo=new ImageIcon(scaledLogo.getImage().getScaledInstance(128,128,BufferedImage.SCALE_SMOOTH));
      logoLabel=new JLabel(scaledLogo);
    }
    hideIcon=createImageIcon("images/eyes-closed.png","Hide icon");
    revealIcon=createImageIcon("images/eyes-open.png","Reveal icon");

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
    
    addWindowListener(new WindowAdapter() {
        @Override
        public void windowClosing(WindowEvent e) {
            quit();
        }
    });
  }

  public String getClueText(int idx, boolean isColumn){
    if (isColumn) return columnBox.getClueText(idx);
    else return rowBox.getClueText(idx);
  }
  public int getPointSize(){return cluePointSize;}
  
  public double getGrade(){
    Object g=gradeSpinner.getValue();
    if (g==null || !(g instanceof Double))return Resource.DEFAULT_GRADE;
    else return ((Double)(g)).doubleValue();
  }
  public void setGrade(double grade){gradeSpinner.setValue(grade);}
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
    if (isSolving){
        hiderevealButton.setIcon(revealIcon);
        hiderevealButton.setToolTipText("Reveal the solution");
    }
    else{
        hiderevealButton.setIcon(hideIcon);
        hiderevealButton.setToolTipText("Hide the solution");
    }
  }

  protected void resizeGame(){
    int[] d=getDimensions(rows,cols);
    if (d==null) return;
    else control.resize(d[0],d[1]);
  }
  
  protected void quit(){control.quit();}

  private void editGame(){
    GameEditor ge=new GameEditor(this,rows, cols);
    ge.setGameName(getName());
    ge.setCreationDate(getCreationDate());
    ge.setAuthor(getAuthor());
    ge.setLicense(getLicense());
    for (int r=0; r<rows; r++) ge.setClue(r,rowBox.getClueText(r),false);
    for (int c=0; c<cols; c++) ge.setClue(c,columnBox.getClueText(c),true);
    ge.setLocationRelativeTo((Component)this);
    ge.setVisible(true);

    if (ge.wasCancelled){out.println("Was cancelled");}
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
    dialog.setLocationRelativeTo((Component)this);
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
    this.pack();
  }

  public void setClueFontAndSize(int pointSize){
    cluePointSize=pointSize;
    Font f=new Font("Arial",Font.BOLD,cluePointSize);
    FontMetrics fm= this.getGraphics().getFontMetrics(f);
    int fontHeight=fm.getHeight();
    int fontWidth=fm.stringWidth("0,");
    int boxAllocation=4+Math.max(fontHeight,fontWidth);
    rowBox.setFontAndSize(f, (int)(0.5*fontWidth*(cols+1)), boxAllocation);
    columnBox.setFontAndSize(f, boxAllocation, (int)(0.5*fontHeight*(rows+1)));
    this.pack();
    setVisible(true);
  }

  public void zoomFont(int changeInPointSize){
    if (changeInPointSize>0)cluePointSize++;
    else cluePointSize--;
    if(cluePointSize<Resource.MINIMUM_CLUE_POINTSIZE) cluePointSize=Resource.MINIMUM_CLUE_POINTSIZE;
    if(cluePointSize>Resource.MAXIMUM_CLUE_POINTSIZE) cluePointSize=Resource.MAXIMUM_CLUE_POINTSIZE;
    setClueFontAndSize(cluePointSize);
  }

  public void setClueText(int idx, String text, boolean isColumn){
    if (isColumn) {
      columnBox.setClueText(idx,text);
      setLabelToolTip(idx,Utils.freedomFromClue(rows,text),true);
    }
    else {
      rowBox.setClueText(idx,text);
      setLabelToolTip(idx,Utils.freedomFromClue(cols,text),false);
    }
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

    toolbar.add(new MyAction("Load game",createImageIcon("images/Open24.gif","Load icon"),"LOAD_GAME"));
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Load a puzzle from file");
    position++;

    toolbar.add(new MyAction("Save game",createImageIcon("images/Save24.gif","Save icon"),"SAVE_GAME"));
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Save the puzzle to file");
     position++;
     
    toolbar.addSeparator();
    position++;

    toolbar.add(new MyAction("Hide game",hideIcon,"HIDE_REVEAL_GAME"));
    hiderevealButton=((JButton)(toolbar.getComponentAtIndex(position)));
    hiderevealButton.setToolTipText("Hide the solution and start solving");
     position++;

    toolbar.add(new MyAction("Check",createImageIcon("images/errorcheck.png","Check icon"),"CHECK_GAME"));
     position++;
     
    toolbar.addSeparator();
    position++;

    toolbar.add(new MyAction("Undo",createImageIcon("images/Undo24.gif","Undo icon"),"UNDO_MOVE"));
     position++;
    toolbar.add(new MyAction("Redo",createImageIcon("images/Redo24.gif","Redo icon"),"REDO_MOVE"));
     position++;

    toolbar.add(new MyAction("Restart",createImageIcon("images/Refresh24.gif","Restart icon"),"RESTART_GAME"));
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Start solving this puzzle again");
    position++;
     
    toolbar.addSeparator();
    position++;

    toolbar.add(new MyAction("Random game",createImageIcon("images/dice.png","Random icon"),"RANDOM_GAME"));
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Generate a random puzzle");
    position++;

    toolbar.add(new MyAction("Solve game",createImageIcon("images/computer.png","Solve icon"),"SOLVE_GAME"));
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Let the computer try to solve the puzzle");
     position++;
     
    toolbar.addSeparator();
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
    
    toolbar.add(new MyAction("Preferences",createImageIcon("images/Preferences24.gif","Preferences icon"),"EDIT_PREFERENCES"));
    ((JComponent)(toolbar.getComponentAtIndex(position))).setToolTipText("Edit preferences");
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
      if (command.equals("NEW_GAME")) control.newGame();
      if (command.equals("LOAD_GAME")) control.loadGame();
      if (command.equals("SAVE_GAME")) control.saveGame();
      if (command.equals("RANDOM_GAME")) control.randomGame(getGrade());
      if (command.equals("HIDE_REVEAL_GAME")) 
      {
        JButton b=(JButton)a.getSource();
        if (b.getToolTipText().contains("Hide")){
          control.setSolving(true);
        }
        else{
          control.setSolving(false);
        }
      }
      if (command.equals("SOLVE_GAME")) control.userSolveGame();
      if (command.equals("RESIZE_GAME")) resizeGame();
      if (command.equals("RESTART_GAME")) control.restartGame();
      if (command.equals("ZOOM_IN")) control.zoomFont(2);
      if (command.equals("ZOOM_OUT")) control.zoomFont(-2);
      if (command.equals("EDIT_GAME")) editGame();
      if (command.equals("CHECK_GAME")) control.checkGame();
      if (command.equals("UNDO_MOVE")) control.undoMove();
      if (command.equals("REDO_MOVE")) control.redoMove();
      if (command.equals("ABOUT_GAME")) Utils.showInfoDialog("Gnonograms for Java version "+Resource.VERSION_STRING+"\n\n by Jeremy Wootten\n<jeremywootten@gmail.com>");
      if (command.equals("EDIT_PREFERENCES")) control.editPreferences();
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

