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

import java.util.Properties;
import java.util.InvalidPropertiesFormatException;
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
import javax.swing.JPanel;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JSpinner;
import javax.swing.SpinnerNumberModel;
import javax.swing.BorderFactory;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import javax.swing.JFrame;
import java.awt.Dimension;

public class Config extends Properties {
    private String configDirectoryPath=System.getProperty("user.home")+"/.jpw";
    private boolean valid=false;
    private Properties properties;
    
    File propertiesFile ;
     
    public Config(){
        boolean alreadyExists=false;        
        File configDirectory=new File(configDirectoryPath);
        propertiesFile=new File(configDirectoryPath+"/gnonograms-java.conf");
        
        try{ 
            configDirectory.mkdirs();
            alreadyExists=!propertiesFile.createNewFile();
            }
        catch(IOException e){out.println("Problem creating properties file "+e.getMessage());}
        if(!alreadyExists){
            valid=createDefaultProperties();
        }
        else{
            if(!loadProperties()){
                valid=createDefaultProperties();
            }
            else valid=true;
        }
            
    }
    
    private boolean createDefaultProperties(){
        Properties defaultProperties= new Properties();
        defaultProperties.setProperty("model.rows","10");
        defaultProperties.setProperty("model.cols","15");
        defaultProperties.setProperty("model.grade","5");
        defaultProperties.setProperty("view.pointsize","10");
        this.properties=new Properties(defaultProperties);
        return saveProperties();
    }
    
    private int getInteger(String key, int defaultValue){
        try{
            return Integer.valueOf(properties.getProperty(key));
        }
        catch (Exception e){return defaultValue;}
    }
    private void setInteger(String key, int value){
        properties.setProperty(key,String.valueOf(value));
    }
    
    public int getRows(){return getInteger("model.rows",Resource.DEFAULT_ROWS);}
    public void setRows(int value){setInteger("model.rows",value);}
        
    public int getCols(){return getInteger("model.cols",Resource.DEFAULT_COLS);}
    public void setCols(int value){setInteger("model.cols",value);}
    
    public double getGrade(){return (double)getInteger("model.grade",Resource.DEFAULT_GRADE);}
    public void setGrade(double value){setInteger("model.grade",(int)value);}
    
    public int getPointSize(){return getInteger("model.pointsize",10);}
    public void setPointSize(int value){setInteger("model.pointsize",value);}
    
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
        private JSpinner rowSpinner,columnSpinner,gradeSpinner, pointsizeSpinner;
        public boolean wasCancelled=false;
        
        public ConfigDialog(JFrame owner, int rows, int cols, int grade, int pointsize){
            super(owner,"Preferences",true);
            this.setLayout(new BorderLayout());
            this.setPreferredSize(new Dimension(300,250));
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
            c.ipadx=6; c.ipady=6;
            c.fill=GridBagConstraints.NONE;
            c.anchor=GridBagConstraints.LINE_END;
            infoPane.add(new JLabel("Number of rows"),c);
            c.gridy=1;
            infoPane.add(new JLabel("Number of columns:"),c);
            c.gridy=2;
            infoPane.add(new JLabel("Difficulty"),c);
            c.gridy=3;
            infoPane.add(new JLabel("Font size"),c);
            
            rowSpinner=new JSpinner(new SpinnerNumberModel(rows,1,Resource.MAXIMUM_GRID_SIZE,1));
            columnSpinner=new JSpinner(new SpinnerNumberModel(cols,1,Resource.MAXIMUM_GRID_SIZE,1));
            gradeSpinner=new JSpinner(new SpinnerNumberModel(grade,1,(int)Resource.MAXIMUM_GRADE,1));
            pointsizeSpinner=new JSpinner(new SpinnerNumberModel(pointsize,Resource.MINIMUM_CLUE_POINTSIZE,Resource.MAXIMUM_CLUE_POINTSIZE,1));

            c.weightx=1;
            c.anchor=GridBagConstraints.LINE_START;
            c.fill=GridBagConstraints.NONE;
            c.gridx=1; c.gridy=0;
            infoPane.add(rowSpinner,c);
            c.gridy=1;
            infoPane.add(columnSpinner,c);
            c.gridy=2;
            infoPane.add(gradeSpinner,c);
            c.gridy=3;
            infoPane.add(pointsizeSpinner,c);
            
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
        protected int getGrade(){return spinnerValueToInt(gradeSpinner.getValue());}
        protected int getPointSize(){return spinnerValueToInt(pointsizeSpinner.getValue());}
        
        private int spinnerValueToInt(Object o){
            return ((Integer)o).intValue();
        }
    }

}
