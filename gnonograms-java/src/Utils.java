/* Utils class for gnonograms-java
 * Various helper methods and dialogues
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
import static java.lang.System.out;
import javax.swing.ImageIcon;
import java.util.ArrayList;
import java.util.ListIterator;
import javax.swing.JButton;
import javax.swing.JPanel;
import javax.swing.JDialog;
import javax.swing.JOptionPane;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.BorderLayout;

public class Utils
{
  static public String clueFromIntArray(int[] cs){
     StringBuilder sb= new StringBuilder("");
    int count=0, blocks=0;
    boolean counting=false;

    for (int i=0; i<cs.length; i++){
      if (cs[i]==Resource.CELLSTATE_EMPTY){
        if (counting){
          sb.append(count);
          sb.append(Resource.BLOCKSEPARATOR);
          counting=false;
          count=0;
          blocks++;
        }
      }
      else if(cs[i]==Resource.CELLSTATE_FILLED){
        counting=true; count++;
      }
    }
    if (counting) {
      sb.append(count);
      sb.append(Resource.BLOCKSEPARATOR);
      blocks++;
    }
    if (blocks==0) sb.append("0");
    else sb.setLength(sb.length() -1);

    return sb.toString();
  }

  public static int freedomFromClue(int regionSize, String clue){
    int[] blocks=blockArrayFromClue(clue);
    int count=0;
    for(int e : blocks) count+=e;
    return regionSize-count-blocks.length+1;
  }

  public static String stringFromIntArray(int[] cs)
  {
    if (cs==null) return "";
    StringBuilder sb= new StringBuilder();
    for (int i=0; i<cs.length; i++)
    {
      sb.append(cs[i]);
      sb.append(" ");
    }
    return sb.toString();
  }

  static public int[] cellStateArrayFromString(String s) throws NumberFormatException {
    String[] data=removeBlankLines(s.split("[\\D\\n]",110));
    int[] csa=new int[data.length];
    for (int i=0; i<data.length; i++) {
      csa[i]=new Integer(data[i]);
    }
    return csa;
  }

  public static String[] removeBlankLines(String[] sa){
    ArrayList<String> al = new ArrayList<String>();
    int count=0;
    for (String s : sa) {
      if (s.length()>0) {al.add(s);count++;}
    }
    String[] result=new String[count];
    for(int i=0; i<count; i++){
      result[i]=al.get(i);
    }
    return result;
  }

  public static int[] blockArrayFromClue(String s)
  {
    String[] clues=removeBlankLines(s.split("[\\D\\n]",50));

    if(clues.length==0) {
      clues=new String[1]; clues[0]="0";
    }
    int[] blocks=new int[clues.length];

    for (int i=0;i<clues.length;i++) {
      blocks[i]=Integer.parseInt(clues[i]);
    }

    return blocks;
  }

  public static boolean showConfirmDialog(String s){
    int result=JOptionPane.showConfirmDialog(null,s,"",JOptionPane.YES_NO_OPTION);
    return (result==JOptionPane.YES_OPTION);
  }
  public static void showWarningDialog(String s){
    JOptionPane.showMessageDialog(null,s,"",JOptionPane.WARNING_MESSAGE);
  }
  public static void showErrorDialog(String s){
     JOptionPane.showMessageDialog(null,s,"",JOptionPane.ERROR_MESSAGE);
  }
  public static boolean showInfoDialog(String s){
    JOptionPane.showMessageDialog(null,s,"",JOptionPane.INFORMATION_MESSAGE);
    return true;
  }
  public static JPanel okCancelPanelFactory(ActionListener listener, String okCommand){
    JButton okButton=new JButton("OK");
    okButton.setActionCommand(okCommand);
    okButton.addActionListener(listener);
    JButton cancelButton=new JButton("Cancel");
    cancelButton.setActionCommand("");
    cancelButton.addActionListener(listener);
    JPanel buttonPanel=new JPanel();
    buttonPanel.setLayout(new BorderLayout());
    buttonPanel.add(okButton, BorderLayout.LINE_START);
    buttonPanel.add(cancelButton, BorderLayout.LINE_END);
    return buttonPanel;
  }
}