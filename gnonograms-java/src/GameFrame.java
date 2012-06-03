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

import java.awt.FlowLayout;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.util.Random;
import javax.swing.JFrame;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JTextField;


public class GameFrame extends JFrame implements ActionListener
{
	int randomNumber = (new Random()).nextInt(10)+1;
	int numGuesses=0;
	JTextField textField = new JTextField(5);
	JButton button = new JButton("Guess");
	JLabel label = new JLabel(numGuesses+" guesses");

	public GameFrame()
	{
		this.setTitle("Make a guess!");
		this.setLayout(new FlowLayout());
		this.add(textField);
		this.add(button);
		this.add(label);
		pack();

		button.addActionListener(this);
		this.setDefaultCloseOperation(EXIT_ON_CLOSE);
		this.setVisible(true);
	}

	@Override
	public void actionPerformed(ActionEvent e)
	{
		String textFieldText = textField.getText();
		if (Integer.parseInt(textFieldText)==randomNumber)
		{
			button.setEnabled(false);
			textField.setText("Yes!!");
			textField.setEnabled(false);
		}
		else
		{
			textField.setText("");
			textField.requestFocus();
		}
		numGuesses++;
		String guessWord = (numGuesses == 1) ? " guess" : " guesses";
		label.setText(numGuesses + guessWord);
	}
}

