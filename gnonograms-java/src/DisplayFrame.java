/*
 * DisplayFrame.java
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
import javax.swing.BorderFactory;


import java.awt.Graphics;
import java.awt.Color;
import java.awt.Container;
import java.awt.GridLayout;
import java.awt.GridBagLayout;
import java.awt.GridBagConstraints;
import java.awt.ComponentOrientation;



public class DisplayFrame extends JFrame {

  CellGrid drawing;
  JLabel [] rowlabels, collabels;
  Container contentpane;
  GridBagConstraints c;
  LabelBox rowbox, colbox;

  public DisplayFrame(int rows, int cols)
  {
    init(rows,cols);
    this.setSize(400,400);
    this.setDefaultCloseOperation(EXIT_ON_CLOSE);
    this.setVisible(true);
  }

  private void init(int rows, int cols)
  {
    this.setTitle("My CellGrid");
    this.setResizable(true);
    contentpane=this.getContentPane();
    contentpane.setLayout(new GridBagLayout());

    rowbox=new LabelBox(rows, false);
    colbox=new LabelBox(cols, true);

    String initstring = "1,1,2,5";
    String initlf = ",";

    rowbox.setLabelText(0,initstring,initlf);
    colbox.setLabelText(0,initstring,initlf);

    drawing=new CellGrid(rows, cols);
    c = new GridBagConstraints();
    c.gridx=1;
    c.gridy=1;
    c.gridwidth=cols;
    c.gridheight=rows;
    c.fill=GridBagConstraints.BOTH;
    c.weightx=1;
    c.weighty=1;
    this.add(drawing,c);

    c = new GridBagConstraints();
    c.gridx=1;
    c.gridy=0;
    c.gridwidth=cols;
    c.gridheight=1;
    c.fill=GridBagConstraints.HORIZONTAL;
    c.weightx=1;
    c.anchor=GridBagConstraints.LINE_START;
    this.add(colbox,c);

    c = new GridBagConstraints();
    c.gridx=0;
    c.gridy=1;
    c.gridwidth=1;
    c.gridheight=rows;
    c.fill=GridBagConstraints.VERTICAL;
    c.weighty=1;
    c.anchor=GridBagConstraints.PAGE_START;
    this.add(rowbox,c);
  }
}

