package models;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import controllers.Constants;

import java.io.*;

public class ComboboxOpts {
	public static List<String> fileFormat(){
		List<String> tmp = new ArrayList();

		tmp.add("SGA file format");
		tmp.add("Boonelab format");
		return tmp;
	}
	
	
	public static List<String> borders(){
		List<String> tmp = new ArrayList();
		tmp.add("0");
		tmp.add("1");
		tmp.add("2");
		tmp.add("3");
		tmp.add("4");
		tmp.add("5");
		return tmp;
	}
	
	public static List<String> replicates(){
		List<String> tmp = new ArrayList();

		tmp.add("4");
		tmp.add("1");
		return tmp;
	}
	
	public static List<String> arrayDef(){
		List<String> tmp = new ArrayList();

		tmp.add("― Predefined array definitions ―");
		File f = new File(Constants.ARRAY_DEF_PATH);
		for(File array_def: f.listFiles()){
			if(array_def.isDirectory())
				tmp.add(array_def.getName());
		}
		tmp.add("― Custom ―");
		return tmp;
	}
	
	public static List<String> arrayDefPlates(String arrayDefinitionFile){
		List<String> tmp = new ArrayList();
		tmp.add("All plates");
		
		File f = new File(Constants.ARRAY_DEF_PATH+"/"+arrayDefinitionFile);
		for(File plate: f.listFiles()){
			if(!plate.getName().startsWith(".")){
				tmp.add(plate.getName());
			}
		}
		
		return tmp;
	}
	
	
}
