package controllers;


import play.mvc.Http.MultipartFormData;
import play.mvc.Http.MultipartFormData.FilePart;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import javax.swing.JFrame;
import javax.swing.JOptionPane;
import javax.swing.JTextField;

import models.*;
import play.data.Form;
import play.mvc.Controller;
import play.mvc.Result;
import play.mvc.Http.MultipartFormData.FilePart;
import validators.BoonelabFileFormatValidator;
import validators.Help;
import validators.SGAFileFormatValidator;
import views.html.*;
import views.html.normalize.*;
import views.html.score.*;
import views.html.imageanalysis.*;


import java.io.*;

public class SGAToolsController extends Controller {
	final static Form<SGAToolsJob> normalizationForm = form(SGAToolsJob.class);
	final static Form<SGAToolsJob> scoringForm = form(SGAToolsJob.class);
	
	
	public static Result initNormalizationForm(){
		SGAToolsJob job = new SGAToolsJob(1);
		Form<SGAToolsJob> newform = normalizationForm.fill(job);
		return ok(nform.render(newform));
	}
	
	public static Result initScoringForm(){
		Form<SGAToolsJob> newform = scoringForm.fill(new SGAToolsJob(2));
		return ok(sform.render(newform));
	}
	
	public static Result initIAForm(){
		SGAToolsJob job = new SGAToolsJob(1);
		Form<SGAToolsJob> newform = normalizationForm.fill(job);
		return ok(iaform.render(newform));
	}
	
	
	public static Result submitNormalizationForm(){
		return submit();
	}
	
	public static Result submitScoringForm(){
		return submit();
	}
	
	public static Result submit(){
		//Get form
		Form<SGAToolsJob> filledForm = normalizationForm.bindFromRequest();
		
		//JOptionPane.showMessageDialog(null, filledForm.data());
		try {
			BufferedWriter out = new BufferedWriter(new FileWriter("/Users/omarwagih/Desktop/job.txt"));
			out.write(filledForm.data().toString());
			out.close();
		} catch (IOException e) {
		}
		
		//Process submission
		long submissionStartTime = new Date().getTime(); //start time
		
		//Type of submission
		Integer jobType = Integer.parseInt(filledForm.bindFromRequest().data().get("jobType"));
		
		//File format - for validation
		String fileFormat = filledForm.bindFromRequest().data().get("fileFormat");
		
		//Any initial errors?
		if (filledForm.hasErrors()) {
			if(jobType==1)
				return badRequest(nform.render(filledForm));
			if(jobType==2)
				return badRequest(sform.render(filledForm));
		}
		
		//Get job
		SGAToolsJob job = filledForm.get();
		
		//Get file(s) uploaded
		MultipartFormData body = request().body().asMultipartFormData();
		List<FilePart> plateFiles = body.getFiles();
		FilePart arrayDefCustomFile = body.getFile("arrayDefCustomFile");
		
		try {
			BufferedWriter out = new BufferedWriter(new FileWriter("/Users/omarwagih/Desktop/job.txt"));
			out.write("arrayDefCustomFile="+arrayDefCustomFile);
			out.close();
		} catch (IOException e) {
		}
		//Store plate files in a map, mapping their name to File object
		Map<String, FilePart> plateFilesMap = new HashMap<String, FilePart>();
        for(FilePart fp : plateFiles){
			plateFilesMap.put(fp.getFilename(), fp);
        }
        
        //Remove extra non plate files
        if(arrayDefCustomFile != null) plateFilesMap.remove(arrayDefCustomFile.getFilename());
        
        //To store plate file paths and the actual names of the plate files as comma seprated strings
        StringBuilder plateFilePathsCSV = new StringBuilder();
        StringBuilder plateFileNamesCSV = new StringBuilder();
        
        //Validate the files
        //Have no files been uploaded?
        if(plateFilesMap.isEmpty()){
        	filledForm.reject("plateFiles", "Missing plate file(s)");
        }

        //If any errors arise, reject the form submission
        if (filledForm.hasErrors()) {
        	if(jobType==1)
				return badRequest(nform.render(filledForm));
			if(jobType==2)
				return badRequest(sform.render(filledForm));
        }
        
		
        int fileNumber = 1;
        //Otherwise, check each file and validate it
        for(FilePart fp: plateFilesMap.values()){
        	
        	
        	//Attempt to validate it
        	try{
        		Object[] obj = new Object[]{false, "Failed to validate files"};
        		//Create validator depending on file format
    			if(fileFormat.equals(ComboboxOpts.fileFormat().get(0))){
    				SGAFileFormatValidator sgav = new SGAFileFormatValidator(fp.getFile().getPath(), fileNumber);
    				obj = sgav.isValid(); 
    			}else if(fileFormat.equals(ComboboxOpts.fileFormat().get(1))){
    				BoonelabFileFormatValidator blfv = new BoonelabFileFormatValidator(fp.getFile().getPath(), fp.getFilename(), fileNumber, false);
    				obj = blfv.isValid(); 
    			}
            	//SGAFileValidator sgav = new SGAFileValidator(fp.getFile().getPath(), fileNumber);
            	fileNumber++;
            	
            	boolean isValid = (Boolean) obj[0];
        		String errorMessage = (String) obj[1];
        		if(!isValid){
        			filledForm.reject("plateFiles", "Error in file "+fp.getFilename() +": "+errorMessage);
        			break;
		        }
        	}catch(Exception e){
        		//Redirect to error page/inform developer FATAL ERROR HERE
        	}
        	
        	//Check content type
        	/*
    		String contentType = fp.getContentType();
    		if(!contentType.equalsIgnoreCase("text/plain")){
    			filledForm.reject("sgafiles", "Error in file "+fp.getFilename()+": invalid format, " +
    					"files must be of type plain text or zip, found "+fp.getContentType());
    			break;
    		}
    		*/
    		
    		//Add plate file paths
    		plateFilePathsCSV.append(fp.getFile().getPath()+",");
    		plateFileNamesCSV.append(fp.getFilename()+",");
        }
        
		//Array definitions
		boolean doArrayDef = Boolean.TRUE.equals(job.doArrayDef);
		StringBuilder arrayDefFilePathsCSV = new StringBuilder();
		List<String> adList = ComboboxOpts.arrayDef();
		if(doArrayDef){
			//Custom file -ERROR HERE FILE NOT UPLOADING
			if(adList.indexOf(job.arrayDefPredefined) == adList.size()-1){
				if(arrayDefCustomFile == null){
					filledForm.reject("arrayDefCustomFile", "Missing array definition file");
				}else{
					arrayDefFilePathsCSV.append(arrayDefCustomFile.getFile().getPath());
				}
			}
			//Predefined array def
			else if(job.selectedArrayDefPlate != null){
				String arrayDefDir = Constants.ARRAY_DEF_PATH + "/" + job.selectedArrayDefPlate;
				List<String> adPlatesList = ComboboxOpts.arrayDefPlates(job.arrayDefPredefined);
				if(adPlatesList.indexOf(job.selectedArrayDefPlate) == 0){
					//All plates
					for(int i=1; i<adPlatesList.size(); i++){
						arrayDefFilePathsCSV.append(arrayDefDir + "/" + adPlatesList.get(i) + ",");
					}
				}else{
					//One plate
					arrayDefFilePathsCSV.append(arrayDefDir + "/" + job.selectedArrayDefPlate);
				}
				
			}
			//Selected to do array def, but did not select anything from the dropdown
			else{
				filledForm.reject("arrayDefPredefined", "Please select a predefined array definition or upload your own");
			}
		}
		
        //If any errors arise, reject the form submission
        if (filledForm.hasErrors()) {
        	if(jobType==1)
				return badRequest(nform.render(filledForm));
			if(jobType==2)
				return badRequest(sform.render(filledForm));
        }
        
        //Run script here
        
        //Command to be run from shell
        String cmd =  "Rscript "+ Constants.RSCRIPT_PATH
				+ " --inputfiles " + plateFilePathsCSV
				+ " --savenames " + plateFileNamesCSV.toString().replaceAll("\\s", "%20")
        		+ " --outputdir " + Constants.JOBOUTPUTDIR_PATH
				+ " --handleout " + "savefile"
				+ " --cborder " + job.controlBorders
        		+ " --replicates " + job.replicates 
        		+ " --jobid " + UUID.randomUUID();
		
        //Do we have array definition files?
		if(doArrayDef){
			cmd = cmd +" --doarraydef true";
			cmd = cmd +" --arrdefpaths "+arrayDefFilePathsCSV.toString().replaceAll("\\s", "%20");
		}
		
        //Are we doing normalization alone or scoring as well?
        if(jobType == 1){
        	if(Boolean.TRUE.equals(job.doScoring)){
        		cmd = cmd + " --jobtype both ";
        	}else{
	        	cmd = cmd + " --jobtype normalize ";
	        }
        }else if(jobType == 2){
        	cmd = cmd +" --jobtype score ";
        }
       
        //Are always do heatmaps
		cmd = cmd +" --doheatmaps yes";
		
        
        /*
        JFrame f = new JFrame();
        JTextField tf = new JTextField();tf.setText(cmd);
        f.getContentPane().add(tf);
        f.pack();
        f.setVisible(true);
        f.setSize(800,200);
        */
        
        //Init variables needed for the read
        String zipPath = "";
        StringBuilder shell_output = new StringBuilder();
        StringBuilder shell_output_error = new StringBuilder();
        try{
	        //Try execute and read
	        Process p = Runtime.getRuntime().exec(cmd);
	        
	        //Read in output returned from shell
	        BufferedReader in = new BufferedReader(new InputStreamReader(p.getInputStream()) );
	        String line;
	        while ((line = in.readLine()) != null) {
	        	shell_output.append(line+"\n");
	        }
	        
	        //Read in error input stream (if we have some error)
	        BufferedReader in_error = new BufferedReader(new InputStreamReader(p.getErrorStream()));
	        String line_error;
	        while ((line_error = in_error.readLine()) != null) {
	        	shell_output_error.append(line_error+"\n");
	        }
	        in_error.close();
        }catch(Exception e){
        	//Some fatal error occurred with the console
        	//Handle it TODO 
        }
        
        //JOptionPane.showMessageDialog(null, shell_output+"\n"+shell_output_error);
        //Set zipPath which should be the last line read
        String[] sp = shell_output.toString().split("\n");
        zipPath = sp[sp.length-1];//Last line in output
        
        //Get second path
        String[] out_paths = zipPath.split("#");
        zipPath = out_paths[0];
        String heatmapsPath  = out_paths[1];
        
        //Done reading, get the last line read from the input - this should be our path to the result file
        File resultFile = new File(zipPath);
        File heatmapFile = new File(heatmapsPath);
        if(!resultFile.exists()){
        	//Error occurred show JOptionPane with error input stream 
        	JOptionPane.showMessageDialog(null, shell_output_error);
        	
        	//Handle it/redirect to error page/report TODO
        }
        
        //job.plotted_data_path = resultFile.getParentFile().getName() + "/"+heatmapFile.getName();
        job.outputPath = resultFile.getParentFile().getName() + "/"+resultFile.getName();
        job.plateFileNamesCSV = "("+plateFilesMap.size()+") "+plateFileNamesCSV.substring(0,plateFileNamesCSV.length()-1).toString().replaceAll(",", ", ");
        
        //Save time elapsed
        long submissionEndTime = new Date().getTime(); //end time
        long milliseconds = submissionEndTime - submissionStartTime; //check different
        int seconds = (int) (milliseconds / 1000) % 60 ;
        int minutes = (int) ((milliseconds / (1000*60)) % 60);
        job.timeElapsed =  minutes + " mins "+ seconds + " secs";
	
        if(jobType==1)
			return ok(nsummary.render(filledForm.get()));
        else if(jobType==2)
			return ok(ssummary.render(filledForm.get()));
        else
        	return TODO;
	}
}