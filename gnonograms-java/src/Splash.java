/* Main class for Gnonograms-java
 * Main entry point.
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
import javax.swing.JFrame;
import javax.swing.JLabel;
import java.awt.Container;
import java.awt.Component;
import javax.swing.JPanel;
import java.awt.BorderLayout;
import java.awt.Dimension;


public class Splash extends JFrame {
    private static final long serialVersionUID = 1;
    JLabel label;
    public Splash(){
    this.setTitle("Splash for Gnonograms for Java");
    this.setResizable(false);
    this.setPreferredSize(new Dimension(300,300));
    label=new JLabel("Please wait");
    label.setHorizontalAlignment(JLabel.CENTER);
    label.setVerticalAlignment(JLabel.CENTER);
    Container contentPane=this.getContentPane();
    contentPane.setLayout(new BorderLayout());
    contentPane.add(label,BorderLayout.CENTER);
    JPanel glassPane=new JPanel();
    this.pack();
    this.setVisible(true);
    }
  }
