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
        this.properties=new Properties(defaultProperties);
        return saveProperties();
    }
    
    private int getInteger(String key, int defaultValue){
        if(valid) return Integer.valueOf(properties.getProperty(key));
        else return defaultValue;
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
            out.println(msg+"-creating default."); return false;
            }
        //catch(NullPointerException e){out.println("Null properties file -creating default "+e.getMessage()); return false;}
        //catch(InvalidPropertiesFormatException e){out.println("Invalid properties file  -creating default "+e.getMessage()); return false;}
        //catch(IOException e){out.println("Problem loading properties file -creating default "+e.getMessage()); return false;}
        return true;
        
    }

}
