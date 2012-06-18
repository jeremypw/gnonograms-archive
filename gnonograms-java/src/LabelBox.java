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

import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.BorderFactory;

import java.awt.GridLayout;
import java.awt.ComponentOrientation;
import java.awt.Color;
import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Dimension;

import static java.lang.System.out;

class LabelBox extends JPanel{
  private static final long serialVersionUID = 1;
  
  GnonogramLabel[] labels;
  int no_labels;
  boolean isColumn;
  Controller control;

  public LabelBox(int no_labels, boolean isColumn, Controller control){
    this.no_labels=no_labels;
    this.isColumn=isColumn;
    this.control=control;

    if (isColumn) this.setLayout(new GridLayout(1,no_labels,0,0));
    else  this.setLayout(new GridLayout(no_labels,1,0,0));
    this.setBorder(BorderFactory.createLineBorder(Color.black));

    labels=new GnonogramLabel[no_labels];
    for (int i=0; i<no_labels; i++) {
      labels[i]=new GnonogramLabel("0", isColumn);
      this.add(labels[i]);
    }
  }

  public void setFontAndSize(Font f, int width, int height){
    for (int i=0; i<no_labels; i++) {
      labels[i].setFont(f);
      labels[i].setPreferredSize(new Dimension(width, height));
    }
  }

  public void setClueText(int l, String text){
    if (l>=no_labels || l<0) return;
    if (text==null) text="?";
    labels[l].setText(text);
  }

  public void setLabelToolTip(int l, int freedom){
    labels[l].setToolTipText("Freedom="+freedom);
  }

  public String getClueText(int l){
    if (l>=no_labels || l<0) return "";
    else return labels[l].getOriginalText();
  }

  public String getClues(){
    StringBuilder sb=new StringBuilder("");
    for (GnonogramLabel l : labels){
      sb.append(l.getOriginalText());
      sb.append("\n");
    }
    return sb.toString();
  }
}