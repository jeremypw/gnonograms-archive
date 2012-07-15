/* Config class for Gnonograms-java
 * Manages persistent user options
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

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

import java.lang.NullPointerException;
import static java.lang.System.out;

import java.awt.GridBagLayout;
import java.awt.GridBagConstraints;
import java.awt.BorderLayout;
import java.awt.Component;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.Dimension;

import javax.swing.ImageIcon;
import javax.swing.JComponent;
import javax.swing.JPanel;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JSpinner;
import javax.swing.SpinnerNumberModel;
import javax.swing.BorderFactory;
import javax.swing.JFrame;
import javax.swing.JSlider;

import java.util.Hashtable;
import java.util.Properties;
import java.util.InvalidPropertiesFormatException;

public class Config extends Properties {
    private String configDirectoryPath=System.getProperty("user.home")+"/.jpw";
    private boolean valid=false;
    private Properties properties, defaultProperties;
    
    File propertiesFile ;
     
    public Config(){
        boolean alreadyExists=false;
        createDefaultProperties();        
        File configDirectory=new File(configDirectoryPath);
        propertiesFile=new File(configDirectoryPath+"/gnonograms-java.conf");
        
        try{ 
            configDirectory.mkdirs();
            alreadyExists=!propertiesFile.createNewFile();
            }
        catch(IOException e){out.println("Problem creating properties file "+e.getMessage());}
        //if(!alreadyExists){
            //valid=createDefaultProperties();
        //}
        //else{
            //if(!loadProperties()){
                //valid=createDefaultProperties();
            //}
            //else valid=true;
        //}
        if(!alreadyExists||!loadProperties()){
            this.properties=new Properties(defaultProperties);
            valid=saveProperties();
        }
        else valid=true;
    }
    
    private void createDefaultProperties(){
        defaultProperties= new Properties();
        defaultProperties.setProperty("model.rows",String.valueOf(Resource.DEFAULT_ROWS));
        defaultProperties.setProperty("model.cols",String.valueOf(Resource.DEFAULT_COLS));
        defaultProperties.setProperty("model.grade",String.valueOf(Resource.DEFAULT_GRADE));
        defaultProperties.setProperty("view.pointsize","20");
        defaultProperties.setProperty("system.puzzledirectory",System.getProperty("user.home"));
    }
    
    private int getInteger(String key){
        try{
            return Integer.valueOf(properties.getProperty(key));
        }
        catch (Exception e){return Integer.valueOf(defaultProperties.getProperty(key));}
    }
    private void setInteger(String key, int value){
        properties.setProperty(key,String.valueOf(value));
    }
    private String getString(String key){
        try{
            return properties.getProperty(key);
        }
        catch (Exception e){return defaultProperties.getProperty(key);}
    }
    private void setString(String key, String value){
        properties.setProperty(key,value);
    }
    
    public int getRows(){return getInteger("model.rows");}
    public void setRows(int value){setInteger("model.rows",value);}
        
    public int getCols(){return getInteger("model.cols");}
    public void setCols(int value){setInteger("model.cols",value);}
    
    public double getGrade(){return (double)getInteger("model.grade");}
    public void setGrade(double value){setInteger("model.grade",(int)value);}
    
    public int getPointSize(){return getInteger("model.pointsize");}
    public void setPointSize(int value){setInteger("model.pointsize",value);}
    
    public String getPuzzleDirectory(){return getString("system.puzzledirectory");}
    public void setPuzzleDirectory(String value){setString("system.puzzledirectory",value);}
    
    public boolean saveProperties(){
        try{
            FileOutputStream fos = new FileOutputStream(propertiesFile);
            properties.storeToXML(fos, null);
        }
        catch(IOException e){out.println("Problem saving properties file "+e.getMessage()); return false;}
        return true;
    }
    
    public boolean loadProperties(){
        try{
            properties=new Properties();
            properties.loadFromXML(new FileInputStream(propertiesFile));
        }
        catch(Exception e){
            String msg="";
            if (e instanceof NullPointerException) msg="Null properties file";
            if (e instanceof InvalidPropertiesFormatException) msg="Invalid format in properties file";
            if (e instanceof IOException) msg="Cannot load properties file";
            out.println(msg+"-creating default."); 
            return false;
            }
        return true;
    }
    
    public boolean editPreferences(JFrame owner){
        ConfigDialog dialog = new ConfigDialog(owner,getRows(),getCols(), (int)getGrade(), getPointSize());
        dialog.setLocationRelativeTo((Component)owner);
        dialog.setVisible(true);
        boolean cancelled=dialog.wasCancelled;
        if (!cancelled){
            setRows(dialog.getRows());
            setCols(dialog.getCols());
            setGrade(dialog.getGrade());
            setPointSize(dialog.getPointSize());
        }
        dialog.dispose();
        return !cancelled;
    }
    
    private class ConfigDialog extends JDialog implements ActionListener {
        private static final long serialVersionUID = 1;
        private JSpinner rowSpinner,columnSpinner, pointsizeSpinner;
        private JSlider gradeSlider;

        public boolean wasCancelled=false;
        
        public ConfigDialog(JFrame owner, int rows, int cols, int grade, int pointsize){
            super(owner,"Preferences",true);
            this.setLayout(new BorderLayout());
            this.add(createInfoPane(rows,cols,grade,pointsize),BorderLayout.PAGE_START);
            this.add(Utils.okCancelPanelFactory(this,"INFO_OK"),BorderLayout.PAGE_END);
            this.pack();
        }
        
        private JPanel createInfoPane(int rows, int cols, int grade, int pointsize){
            JPanel infoPane=new JPanel(new GridBagLayout());
            GridBagConstraints c=new GridBagConstraints();
            c.gridx=0; c.gridy=0;
            c.gridwidth=1; c.gridheight=1;
            c.weightx=0; c.weighty=0;
            c.ipadx=6; c.ipady=12;
            c.fill=GridBagConstraints.NONE;
            c.anchor=GridBagConstraints.LINE_END;
            JLabel tmpLabel=new JLabel(Utils.createImageIcon("images/resize-rows48.png","resizeRowIcon"));
            tmpLabel.setToolTipText("Set number of rows");
            infoPane.add(tmpLabel,c);

            c.gridy=1;
            tmpLabel=new JLabel(Utils.createImageIcon("images/resize-columns48.png","resizeColumnIcon"));
            tmpLabel.setToolTipText("Set number of columns");
            infoPane.add(tmpLabel,c);

            c.gridy=2;
            tmpLabel=new JLabel(Utils.createImageIcon("images/resize-font48.png","resizeFontIcon"));
            tmpLabel.setToolTipText("Set difficulty of puzzles");
            infoPane.add(tmpLabel,c);

            c.gridy=3;
            tmpLabel=new JLabel(Utils.createImageIcon("images/question48.png","difficultyIcon"));
            tmpLabel.setToolTipText("Set difficulty of puzzles");
            infoPane.add(tmpLabel,c);
            
            rowSpinner=new JSpinner(new SpinnerNumberModel(rows,1,Resource.MAXIMUM_GRID_SIZE,1));
            columnSpinner=new JSpinner(new SpinnerNumberModel(cols,1,Resource.MAXIMUM_GRID_SIZE,1));

            int max=(int)Resource.MAXIMUM_GRADE;
            gradeSlider=new JSlider(1, max, grade );
            Hashtable<Integer , JLabel> gradeSliderLabels = new Hashtable<Integer , JLabel>();
            gradeSliderLabels.put(1,new JLabel(Utils.createImageIcon("images/smile.png","easyIcon")));
            gradeSliderLabels.put(max/2,new JLabel(Utils.createImageIcon("images/undecided.png","mediumIcon")));
            gradeSliderLabels.put(max,new JLabel(Utils.createImageIcon("images/confused.png","hardIcon")));
            
            gradeSlider.setLabelTable(gradeSliderLabels);
            gradeSlider.setPaintLabels(true);

            gradeSlider.setPaintTrack(true);
            gradeSlider.setPaintTicks(false);
            gradeSlider.setMajorTickSpacing(5);
            gradeSlider.setMinorTickSpacing(1);
            pointsizeSpinner=new JSpinner(new SpinnerNumberModel(pointsize,Resource.MINIMUM_CLUE_POINTSIZE,Resource.MAXIMUM_CLUE_POINTSIZE,1));

            c.weightx=1;
            c.anchor=GridBagConstraints.LINE_START;
            c.fill=GridBagConstraints.NONE;
            c.gridx=1; c.gridy=0;
            infoPane.add(rowSpinner,c);
            c.gridy=1;
            infoPane.add(columnSpinner,c);
            c.gridy=2;
            infoPane.add(pointsizeSpinner,c);
            c.gridy=3;
            infoPane.add(gradeSlider,c);
            infoPane.setBorder(BorderFactory.createEtchedBorder());
            return infoPane;
        }
        
        public void actionPerformed(ActionEvent a){
            String command=a.getActionCommand();
            wasCancelled=!(command.equals("INFO_OK"));
            this.setVisible(false);
        }
        
        protected int getRows(){return spinnerValueToInt(rowSpinner.getValue());}
        protected int getCols(){return spinnerValueToInt(columnSpinner.getValue());}
        protected int getGrade(){return gradeSlider.getValue();}
        protected int getPointSize(){return spinnerValueToInt(pointsizeSpinner.getValue());}
        
        private int spinnerValueToInt(Object o){
            return ((Integer)o).intValue();
        }
    }

}
