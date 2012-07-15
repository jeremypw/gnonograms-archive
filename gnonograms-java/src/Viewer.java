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
  private LabelBox rowBox, columnBox;
  private Controller control;
  private InfoLabel nameLabel,authorLabel,licenseLabel,scoreLabel,sizeLabel,dateLabel;
  private JLabel [] rowlabels, collabels;
  private Container contentPane;

  private GridBagConstraints c;
  private BufferedImage rawLogo;
  private ImageIcon myLogo;
  private ImageIcon scaledLogo;
  protected ImageIcon hideIcon, revealIcon;
  private JLabel logoLabel;
  private JToolBar toolbar;
  private JToolBar settingToolBar;
  private JToolBar solvingToolBar;
  private JToolBar commonToolBar;
  private JPanel puzzlePane, toolbarPane, infoPane;
  private JButton hiderevealButton;

  private int rows, cols, cluePointSize=20;
  
  public Viewer(Controller control){
    this.control=control;
    this.setDefaultCloseOperation(EXIT_ON_CLOSE);
    this.setTitle("Gnonograms for Java");
    this.setResizable(false);
//    this.setLocationRelativeTo(null);
    myLogo=Utils.createImageIcon("images/gnonograms3-256.png","Logo");
    logoLabel=new JLabel();
    if (myLogo==null)logoLabel=new JLabel("MISSING ICON");
    if (myLogo==null)logoLabel.setText("MISSING ICON");
    this.setIconImage(myLogo.getImage().getScaledInstance(32,32,BufferedImage.SCALE_SMOOTH));
    
    hideIcon=Utils.createImageIcon("images/eyes-closed.png","Hide icon");
    revealIcon=Utils.createImageIcon("images/eyes-open.png","Reveal icon");

    puzzlePane=new JPanel();
    puzzlePane.setLayout(new GridBagLayout());
    toolbarPane=new JPanel();
    toolbarPane.setLayout(new BorderLayout());
    contentPane=this.getContentPane();
    createInfoPane();

    //createSettingToolBar();
    //createSolvingToolBar();
    createCommonToolBar();
    //toolbarPane.add(settingToolBar,BorderLayout.LINE_START);
    //toolbarPane.add(solvingToolBar,BorderLayout.CENTER);
    toolbarPane.add(commonToolBar,BorderLayout.LINE_START);

    contentPane.setLayout(new BorderLayout());
    contentPane.add(toolbarPane,BorderLayout.PAGE_START);
    contentPane.add(puzzlePane,BorderLayout.LINE_START);
    contentPane.add(infoPane,BorderLayout.PAGE_END);
    
    addWindowListener(new WindowAdapter() {
        @Override
        public void windowClosing(WindowEvent e) {
            quit();
        }
    });
  }

  private void resizeLogoLabelImage(int width, int height){ 
      scaledLogo=new ImageIcon(myLogo.getImage().getScaledInstance(width,height,BufferedImage.SCALE_SMOOTH));
      logoLabel.setIcon(scaledLogo);
  }
  
  public String getClueText(int idx, boolean isColumn){
    if (isColumn) return columnBox.getClueText(idx);
    else return rowBox.getClueText(idx);
  }
  
  public int getPointSize(){return cluePointSize;}
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
    //out.println("Clear info bar");
    setName("");
    setAuthor("");
    setCreationDate("");
    setLicense("");
    setScore("");
  }

  public void setSolving(boolean isSolving){
    drawing.setSolving(isSolving);
    hiderevealButton.setIcon(isSolving ? revealIcon : hideIcon);
    hiderevealButton.setToolTipText(isSolving ? "Reveal the solution" : "Hide the solution");
    //settingToolBar.setVisible(!isSolving);
    //solvingToolBar.setVisible(isSolving);
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

    if (!ge.wasCancelled){
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

  public void setDimensions(int rows, int cols){
    puzzlePane.removeAll();
    this.rows=rows; this.cols=cols;
    sizeLabel.setInfo(rows+"X"+cols);
    rowBox=new LabelBox(rows, false);
    columnBox=new LabelBox(cols, true);
    drawing=new CellGrid(rows, cols, control);
    c = new GridBagConstraints();
    
    c.gridx=1; c.gridy=1;
    c.gridwidth=cols; c.gridheight=rows;
    c.weightx=0;c.weighty=0;
    c.fill=GridBagConstraints.BOTH;
    c.anchor=GridBagConstraints.CENTER;
    puzzlePane.add(drawing,c);
    
    c.weightx=1;c.weighty=1;
    c.fill=GridBagConstraints.BOTH;
    c.gridwidth=cols; c.gridheight=1;
    c.gridx=1; c.gridy=0;
    puzzlePane.add(columnBox,c);
    
    c.fill=GridBagConstraints.BOTH;
    c.gridwidth=1; c.gridheight=rows;
    c.gridx=0; c.gridy=1;
    puzzlePane.add(rowBox,c);

    c.gridwidth=1; c.gridheight=1;
    c.gridx=0; c.gridy=0;
    puzzlePane.add(logoLabel,c);
    this.pack();
  }

  public void setClueFontAndSize(int pointSize){
    cluePointSize=pointSize;
    Font f=new Font("Arial",Font.BOLD,cluePointSize);
    FontMetrics fm= this.getGraphics().getFontMetrics(f);
    int fontWidth=fm.stringWidth("00");
    rowBox.setFontAndSize(f, fontWidth);
    columnBox.setFontAndSize(f, fontWidth);
    logoLabel.setIcon(null);
    this.pack(); //size according to clues
    int imageSize=Math.max(48,Math.max(rowBox.getWidth(),columnBox.getHeight()));
    resizeLogoLabelImage(imageSize,imageSize); //resize logo label accordingly
    this.pack();
    setLocationRelativeTo(null); //centers on screen
  }

  public void zoomFont(int changeInPointSize){
    if (changeInPointSize>0)cluePointSize++;
    else cluePointSize--;
    if(cluePointSize<Resource.MINIMUM_CLUE_POINTSIZE) cluePointSize=Resource.MINIMUM_CLUE_POINTSIZE;
    if(cluePointSize>Resource.MAXIMUM_CLUE_POINTSIZE) cluePointSize=Resource.MAXIMUM_CLUE_POINTSIZE;
    setClueFontAndSize(cluePointSize);
  }

  public void setClueText(int idx, String text, boolean isColumn){
    LabelBox lb= isColumn ? columnBox : rowBox;
    lb.setClueText(idx,text);
    setLabelToolTip(idx, Utils.freedomFromClue((isColumn ? rows : cols),text),isColumn);
  }

  public String getClues(boolean isColumn){
    if (isColumn) return columnBox.getClues();
    else return rowBox.getClues();
  }

  public void setLabelToolTip(int idx, int freedom, boolean isColumn){
    if (isColumn) columnBox.setLabelToolTip(idx, freedom);
    else rowBox.setLabelToolTip(idx, freedom);
  }

  public void redrawGrid(){
    drawing.repaint();
  }

  //private void createSettingToolBar(){
    //JToolBar tb=new JToolBar();
    //tb.setFloatable(false);
    //int position=0;
    //settingToolBar=tb;
  //}
  
  //private void createSolvingToolBar(){
    //JToolBar tb=new JToolBar();
    //tb.setFloatable(false);

    //int position=0;
    //solvingToolBar=tb;
  //}

  private void createCommonToolBar(){
    JToolBar tb=new JToolBar();
    tb.setFloatable(false);

    int position=0;

    tb.add(new MyAction("Create",Utils.createImageIcon("images/New24.gif","Create icon"),"CREATE_GAME"));
    ((JComponent)(tb.getComponentAtIndex(position))).setToolTipText("Draw your own puzzle grid");
    position++;


    tb.add(new MyAction("Edit",Utils.createImageIcon("images/Edit24.gif","Edit icon"),"EDIT_GAME"));
    ((JComponent)(tb.getComponentAtIndex(position))).setToolTipText("Edit the description and clues");
    position++;

    tb.addSeparator();
    position++;
    
    tb.add(new MyAction("Load game",Utils.createImageIcon("images/Open24.gif","Load icon"),"LOAD_GAME"));
    ((JComponent)(tb.getComponentAtIndex(position))).setToolTipText("Load a puzzle from file");
    position++;

    tb.add(new MyAction("Save game",Utils.createImageIcon("images/Save24.gif","Save icon"),"SAVE_GAME"));
    ((JComponent)(tb.getComponentAtIndex(position))).setToolTipText("Save the puzzle to file");
    position++;
    
    tb.addSeparator();
    position++;
    
    tb.add(new MyAction("Undo",Utils.createImageIcon("images/Undo24.gif","Undo icon"),"UNDO_MOVE"));
     position++;
     
    tb.add(new MyAction("Redo",Utils.createImageIcon("images/Redo24.gif","Redo icon"),"REDO_MOVE"));
     position++;

    tb.add(new MyAction("Restart",Utils.createImageIcon("images/Refresh24.gif","Restart icon"),"RESTART_GAME"));
    ((JComponent)(tb.getComponentAtIndex(position))).setToolTipText("Start solving this puzzle again");
    position++;
     
    tb.addSeparator();
    position++;

    tb.add(new MyAction("Solve game",Utils.createImageIcon("images/computer.png","Solve icon"),"SOLVE_GAME"));
    ((JComponent)(tb.getComponentAtIndex(position))).setToolTipText("Let the computer try to solve the puzzle");
     position++;
     
    tb.add(new MyAction("Check",Utils.createImageIcon("images/errorcheck.png","Check icon"),"CHECK_GAME"));
    position++;
    
    tb.addSeparator();
    position++;

    tb.add(new MyAction("Random game",Utils.createImageIcon("images/dice.png","Random icon"),"RANDOM_GAME"));
    ((JComponent)(tb.getComponentAtIndex(position))).setToolTipText("Generate a random puzzle");
    position++;
    
    tb.add(new MyAction("Hide game",hideIcon,"HIDE_REVEAL_GAME"));
    hiderevealButton=((JButton)(tb.getComponentAtIndex(position)));
    hiderevealButton.setToolTipText("Hide the solution and start solving");
    position++;
    
    tb.addSeparator();
    position++;
    
    tb.add(new MyAction("Preferences",Utils.createImageIcon("images/Preferences24.gif","Preferences icon"),"EDIT_PREFERENCES"));
    ((JComponent)(tb.getComponentAtIndex(position))).setToolTipText("Edit preferences");
    position++;

    tb.add(new MyAction("Smaller",Utils.createImageIcon("images/ZoomOut24.gif","Soom Out icon"),"ZOOM_OUT"));
    ((JComponent)(tb.getComponentAtIndex(position))).setToolTipText("Make the font smaller");
    position++;

    tb.add(new MyAction("Larger",Utils.createImageIcon("images/ZoomIn24.gif","Zoom In icon"),"ZOOM_IN"));
    ((JComponent)(tb.getComponentAtIndex(position))).setToolTipText("Make the font larger");
    position++;
    
    tb.add(new MyAction("About",Utils.createImageIcon("images/About24.gif","About icon"),"ABOUT_GAME"));
    ((JComponent)(tb.getComponentAtIndex(position))).setToolTipText("Edit the description and clues");
    position++;
    
    commonToolBar=tb;
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
      if (command.equals("CREATE_GAME")) control.createGame();
      if (command.equals("LOAD_GAME")) {
        control.loadGame();
        setClueFontAndSize(cluePointSize);//resize label boxes if necessary
      }
      if (command.equals("SAVE_GAME")) control.saveGame();
      if (command.equals("RANDOM_GAME")) {
        control.randomGame();
        setClueFontAndSize(cluePointSize);//resize label boxes if necessary
      }
      if (command.equals("HIDE_REVEAL_GAME")) 
      {
        JButton b=(JButton)a.getSource();
        String tt=b.getToolTipText();
        if (tt!=null && tt.contains("Hide")){
          control.setSolving(true);
        }
        else{
          control.setSolving(false);
        }
      }
      if (command.equals("SOLVE_GAME")) control.userSolveGame();
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

