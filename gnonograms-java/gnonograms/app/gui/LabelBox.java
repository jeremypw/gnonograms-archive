/* LabelBox class for gnonograms-java
 * Holds and manages clue labels
 * Copyright 2012 Jeremy Paul Wootten <jeremywootten@gmail.com>
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

package gnonograms.app.gui;

import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.BorderFactory;
import javax.swing.BoxLayout;

import java.awt.BorderLayout;
import java.awt.GridLayout;
import java.awt.Component;
import java.awt.Color;
import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Dimension;

import static java.lang.System.out;

public class LabelBox extends JPanel{
  //private static final long serialVersionUID = 1;
  private int maxClueLength=10;
  private GnonogramLabel[] labels;
  private int no_labels;
  private int size, logoSize=48;
  private boolean isColumn;
  private String freedomString;

  public LabelBox(int no_labels, boolean isColumn, String freedomString){
    if (isColumn)this.setLayout(new GridLayout(1,no_labels));
    else this.setLayout(new GridLayout(no_labels,1));
    this.no_labels=no_labels;
    this.isColumn=isColumn;
    this.freedomString=freedomString;
    this.setBorder(BorderFactory.createLineBorder(Color.black));

    labels=new GnonogramLabel[no_labels];
    for (int i=0; i<no_labels; i++) {
      GnonogramLabel l=new GnonogramLabel("0", isColumn);
      if (isColumn){
        l.setAlignmentY(Component.BOTTOM_ALIGNMENT);
        l.setAlignmentX(Component.CENTER_ALIGNMENT);
      }
      else{
        l.setAlignmentX(Component.RIGHT_ALIGNMENT);
        l.setAlignmentY(Component.CENTER_ALIGNMENT);
      }
      this.add(l);
      labels[i]=l;
  } }

  public void setFontAndSize(Font f, int size){
    setLabelFont(f);
    this.size=size;
    setSize();
  }
  
  private void setSize(){
    int labelWidth, labelHeight;
    //Trial and error functions giving reasonable appearance.
    if (isColumn){
      labelWidth=size*2+4;
      labelHeight=maxClueLength*size+2;
      logoSize=labelHeight;
    }
    else{
      labelWidth=maxClueLength*size+2;
      labelHeight=size*2+4;
      logoSize=labelWidth;
    }
    Dimension d = new Dimension(labelWidth,labelHeight);
    for (GnonogramLabel l :labels){
      l.setPreferredSize(d);
    }
  }
  
  private void setLabelFont(Font f){
    for (GnonogramLabel l :labels){
      l.setFont(f);
  } }
  
  public void highlightLabel(int label, boolean on){
    if (label>=0 && label<no_labels)(labels[label]).highlightLabel(on);
  }

  public void setClueText(int l, String text){
    if (l>=no_labels || l<0) return;
    if (text==null) text="?";
    labels[l].setText(text);
    if(text.length()>maxClueLength){
      maxClueLength=text.length();
      setSize();
  } }

  public void resetMaximumClueLength(int maxLength){maxClueLength=maxLength;}
  
  public void setLabelToolTip(int l, int freedom){
    labels[l].setToolTipText(freedomString+" "+freedom);
  }

  public String getClueText(int l){
    if (l>=no_labels || l<0) return "";
    else return labels[l].getOriginalText();
  }
  
  public int getLogoSize(){return logoSize;}

  public String getClues(){
    StringBuilder sb=new StringBuilder("");
    for (GnonogramLabel l : labels){
      sb.append(l.getOriginalText());
      sb.append("\n");
    }
    return sb.toString();
  }
  
}
