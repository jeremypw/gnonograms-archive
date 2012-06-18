import javax.swing.JTabbedPane;
import javax.swing.JPanel;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JComponent;
import javax.swing.JTextField;
import javax.swing.JFrame;
import javax.swing.JButton;
import javax.swing.JScrollPane;

import java.awt.GridBagLayout;
import java.awt.GridBagConstraints;
import java.awt.BorderLayout;
/* GameEditor class for Gnonograms-java
 * Keyboard Input puzzle description and clues
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
 * 	Jeremy Wootten <jeremwootten@gmail.com>
 */

import java.awt.GridLayout;
import java.awt.Dimension;

import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

public class GameEditor extends JDialog implements ActionListener{
  private static final long serialVersionUID = 1;
  private JComponent infoPane,rowPane,columnPane;
  private JTextField nameField, authorField, dateField, licenseField;
  private JTextField[] rowClues, columnClues;
  private int rows, cols;
  public boolean wasCancelled=false;

	public GameEditor(JFrame owner, int rows, int cols){
		super(owner,"Edit Game", true);
		this.rows=rows; this.cols=cols;
		this.setLayout(new BorderLayout());
		this.setPreferredSize(new Dimension(500,400));
		JTabbedPane tp=new JTabbedPane();
		tp.add("Information", createInfoPane());
		tp.add("Row Clues",createRowCluePane());
		tp.add("Column Clues", createColumnCluePane());

		this.add(tp,BorderLayout.PAGE_START);
		this.add(Utils.okCancelPanelFactory(this,"INFO_OK"),BorderLayout.PAGE_END);
		this.pack();
	}

	private JPanel createInfoPane(){
		JPanel infoPane=new JPanel(new GridBagLayout());
		GridBagConstraints c=new GridBagConstraints();
		c.gridx=0; c.gridy=0;
    c.gridwidth=1; c.gridheight=1;
    c.weightx=0; c.weighty=0;
    c.ipadx=6; c.ipady=6;
    c.fill=GridBagConstraints.NONE;
    c.anchor=GridBagConstraints.LINE_END;
		infoPane.add(new JLabel("Name of Puzzle:"),c);
		c.gridy=1;
		infoPane.add(new JLabel("Author or Source:"),c);
		c.gridy=2;
		infoPane.add(new JLabel("Date of Creation:"),c);
		c.gridy=3;
		infoPane.add(new JLabel("License or copyright:"),c);
		c.weightx=1;
		c.anchor=GridBagConstraints.LINE_START;
		c.fill=GridBagConstraints.HORIZONTAL;
		c.gridx=1; c.gridy=0;
		nameField=new JTextField(25);
		infoPane.add(nameField,c);
		c.gridy=1;
		authorField=new JTextField(25);
		infoPane.add(authorField,c);
		c.gridy=2;
		dateField=new JTextField(25);
		infoPane.add(dateField,c);
		c.gridy=3;
		licenseField=new JTextField(25);
		infoPane.add(licenseField,c);
		return infoPane;
	}

	private JScrollPane createRowCluePane(){
		JPanel rowCluePane=new JPanel(new GridLayout(0,1));
		JPanel tempPanel;
		JLabel tempLabel;
		JScrollPane sp=new JScrollPane(rowCluePane);
		sp.setPreferredSize(new Dimension(400,300));
		rowClues=new JTextField[rows];
		for (int r=0; r<rows; r++) {
			rowClues[r]=new JTextField(25);
			tempPanel=new JPanel(new BorderLayout());
			tempLabel=new JLabel("Row Clue "+r);
			tempPanel.add(tempLabel,BorderLayout.LINE_START);
			tempPanel.add(rowClues[r],BorderLayout.LINE_END);
			rowCluePane.add(tempPanel);
		}
		return sp;
	}
	private JScrollPane createColumnCluePane(){
		JPanel columnCluePane=new JPanel(new GridLayout(0,1));
		JPanel tempPanel;
		JLabel tempLabel;
		JScrollPane sp=new JScrollPane(columnCluePane);
		sp.setPreferredSize(new Dimension(400,300));
		columnClues=new JTextField[cols];
		for (int c=0; c<cols; c++) {
			columnClues[c]=new JTextField(25);
			tempPanel=new JPanel(new BorderLayout());
			tempLabel=new JLabel("Column Clue "+c);
			tempPanel.add(tempLabel,BorderLayout.LINE_START);
			tempPanel.add(columnClues[c],BorderLayout.LINE_END);
			columnCluePane.add(tempPanel);
		}
		return sp;
	}

	public void setGameName(String name){nameField.setText(name);}
	public void setAuthor(String author){authorField.setText(author);}
	public void setCreationDate(String date){dateField.setText(date);}
	public void setLicense(String license){licenseField.setText(license);}
	public void setClue(int idx, String clue, boolean isColumn){
		if(isColumn) columnClues[idx].setText(clue);
		else rowClues[idx].setText(clue);
	}

//TODO Validate format of clues as entered

	public String getGameName(){return nameField.getText();}
	public String getAuthor(){return authorField.getText();}
	public String getCreationDate(){return dateField.getText();}
	public String getLicense(){return licenseField.getText();}
	public String getClue(int idx, boolean isColumn){
		if(isColumn) return columnClues[idx].getText();
		else return rowClues[idx].getText();
	}

	public void actionPerformed(ActionEvent a){
		String command=a.getActionCommand();
		if (command=="INFO_OK") wasCancelled=false;
		else wasCancelled=true;
		this.setVisible(false);
	}
}
