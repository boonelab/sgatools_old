package controllers;

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
import validators.ColonyFileFormatValidator;
import validators.Help;
import validators.SGAFileValidator;
import views.html.*;
import views.html.normalize.*;
import views.html.score.*;
import views.html.imageanalysis.*;

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
		
		//Process submission
		long submission_start_time = new Date().getTime(); //start time
		
		//Type of submission
		Integer job_type = Integer.parseInt(filledForm.bindFromRequest().data().get("job_type"));
		
		//Any initial errors?
		if (filledForm.hasErrors()) {
			if(job_type==1)
				return badRequest(nform.render(filledForm));
			if(job_type==2)
				return badRequest(sform.render(filledForm));
		}
		
		//Get job
		SGAToolsJob job = filledForm.get();
		
		//Get file(s) uploaded
		List<FilePart> plate_files = request().body().asMultipartFormData().getFiles();
		FilePart array_definition_file = request().body().asMultipartFormData().getFile("array_definition_file");
		
		//Store plate files in a map, mapping their name to File object
		Map<String, FilePart> plate_files_map = new HashMap<String, FilePart>();
        for(FilePart fp : plate_files){
			plate_files_map.put(fp.getFilename(), fp);
        }
        
        //Remove extra non plate files
        if(array_definition_file != null) plate_files_map.remove(array_definition_file.getFilename());
        
        //To store plate file paths and the actual names of the plate files as comma seprated strings
        StringBuilder plate_file_paths = new StringBuilder();
        StringBuilder save_names = new StringBuilder();
        
        //Validate the files
        //Have no files been uploaded?
        if(plate_files_map.isEmpty()){
        	filledForm.reject("sgafiles", "Missing SGA formatted file(s)");
        }

        //If any errors arise, reject the form submission
        if (filledForm.hasErrors()) {
        	if(job_type==1)
				return badRequest(nform.render(filledForm));
			if(job_type==2)
				return badRequest(sform.render(filledForm));
        }
        
        int fileNumber = 1;
        
        List<ColonyFileFormatValidator> colonyFormattedData = new ArrayList();
        //Otherwise, check each file and validate it
        for(FilePart fp: plate_files_map.values()){
        	
        	//Create colony validator 
        	ColonyFileFormatValidator colval = new ColonyFileFormatValidator(fp.getFile().getPath(), fp.getFilename(), fileNumber);
        	try{
        		Object[] obj = colval.isValid();
            	boolean isValid = (Boolean) obj[0];
        		String errorMessage = (String) obj[1];
        		if(isValid){
		        	//Valid, skip SGA validator
		        	colonyFormattedData.add(colval);
		        	fileNumber++;
		        	continue;
		        }
        	}catch(Exception e){
        		//Redirect to error page/inform developer FATAL ERROR HERE
        	}
        	
        	//Create validator
        	SGAFileValidator sgav = new SGAFileValidator(fp.getFile().getPath(), fileNumber);
        	fileNumber++;
        	
        	//Attempt to validate it
        	try{
        		Object[] obj = sgav.isValid();
            	boolean isValid = (Boolean) obj[0];
        		String errorMessage = (String) obj[1];
        		if(!isValid){
        			filledForm.reject("sgafiles", "Error in file "+fp.getFilename() +": "+errorMessage);
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
    		plate_file_paths.append(fp.getFile().getPath()+",");
    		save_names.append(fp.getFilename()+",");
        }
        
        //Process colony formatted files if available
        if(colonyFormattedData.size() == plate_files_map.size()){
        	DateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        	Date date = new Date();
        	
        	String writePath = colonyFormattedData.get(0).FILE_PATH;
			try{
				// Create file 
				FileWriter fstream = new FileWriter(writePath);
				BufferedWriter out = new BufferedWriter(fstream);
				out.write("#Converted from 3-column format by SGATools 1.0 on "+dateFormat.format(date)+"\n");
				out.write("@HD\tVN:1.0.0\tIA:NA\n");
				
				//Write info on merged plates
				for(ColonyFileFormatValidator cfd: colonyFormattedData){
					out.write("# Plate ID "+cfd.FILE_NUMBER+" - "+cfd.FILE_NAME+"\n");
				}
				
				out.write("@PL\tNM:3-column converted plate data\n");
				
				for(ColonyFileFormatValidator cfd: colonyFormattedData){
					for(String line: cfd.FILE_DATA){
	        			out.write(line+"\n");
	        		}
	        	}
				//Close the output stream
				out.close();
				
				plate_file_paths = new StringBuilder(writePath);
				save_names = new StringBuilder("colony_plates.txt,");
			}catch (Exception e){//Catch exception if any
				
			}
        	
        }else if(colonyFormattedData.size() != 0 && colonyFormattedData.size() < plate_files_map.size()){
        	//Error
        	filledForm.reject("sgafiles", "Cannot have mix of SGA formatted files and colony formatted files");
        }
        
        
        //If any errors arise, reject the form submission
        if (filledForm.hasErrors()) {
        	if(job_type==1)
				return badRequest(nform.render(filledForm));
			if(job_type==2)
				return badRequest(sform.render(filledForm));
        }
        
        //Run script here
        
        //Command to be run from shell
        String cmd =  "Rscript "+ Constants.RSCRIPT_PATH +  " -i " +plate_file_paths+  " -s " + save_names.toString().replaceAll("\\s", "%20") 
        		+ " -o " +Constants.JOBOUTPUTDIR_PATH + " -d savefile " + "-b "+job.control_borders
        		+ " -r "+job.replicates 
        		+ " -j "+UUID.randomUUID();
        
        //Are we doing normalization alone or scoring as well?
        if(job_type == 1){
        	if(Boolean.TRUE.equals(job.do_scoring)){
        		cmd = cmd +" -t both ";
        	}else{
	        	cmd = cmd +" -t normalize ";
	        }
        }else if(job_type == 2){
        	cmd = cmd +" -t score ";
        }
       
        //Are we doing heat-maps?
        if(Boolean.TRUE.equals(job.show_plate_heatmaps)){
        	cmd = cmd +" -m yes";
        }else{
        	cmd = cmd +" -m no";
        }
        
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
        
        job.plotted_data_path = resultFile.getParentFile().getName() + "/"+heatmapFile.getName();
        job.experiment_name = null;//for now
        job.output_path = resultFile.getParentFile().getName() + "/"+resultFile.getName();
        job.plate_files = "("+plate_files_map.size()+") "+save_names.substring(0,save_names.length()-1).toString().replaceAll(",", ", ");
        
        //Save time elapsed
        long submission_end_time = new Date().getTime(); //end time
        long milliseconds = submission_end_time - submission_start_time; //check different
        int seconds = (int) (milliseconds / 1000) % 60 ;
        int minutes = (int) ((milliseconds / (1000*60)) % 60);
        job.time_elapsed =  minutes + " mins "+ seconds + " secs";
        
        if(job_type==1)
			return ok(nsummary.render(filledForm.get()));
        else if(job_type==2)
			return ok(ssummary.render(filledForm.get()));
        else
        	return TODO;
	}
}