package controllers;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import javax.swing.JFrame;
import javax.swing.JOptionPane;
import javax.swing.JTextField;

import java.io.*;

import models.*;
import play.*;
import play.data.*;
import play.mvc.*;
import play.mvc.Http.MultipartFormData;
import play.mvc.Http.MultipartFormData.FilePart;

import validators.SGAFileValidator;
import views.html.*;
import views.html.normalize.*;

public class ScoreController extends Controller {

    final static String RSCRIPT_PATH = "/Users/omarwagih/Desktop/boone-summer-project-2012/script_r/Main.R";
    final static String JOBOUTPUTDIR_PATH = "/Users/omarwagih/Desktop/boone-summer-project-2012/web/test2/public/other";
	
	final static long maxFileSize = 5;
	final static double oneMegaByte = 1048576.0;//1 MB
	
	final static Form<ScoreJob> scoreForm = form(ScoreJob.class);
	
	public static Result blankScoreForm() {
		Form<ScoreJob> newForm = scoreForm.fill(new ScoreJob());
		
		return ok(scoreform.render(newForm));
	}
	
	
	public static Result submit() {
		long lStartTime = new Date().getTime(); //start time
		
		Form<ScoreJob> filledForm = scoreForm.bindFromRequest();

	    if (filledForm.hasErrors()) {
	        return badRequest(scoreform.render(filledForm));
	    } else {
	    	ScoreJob sj = filledForm.get();
	    	
	    	//Get all files uploaded
	    	MultipartFormData body = request().body().asMultipartFormData();

	        List<FilePart> plateFiles = body.getFiles();//allows multiple files
	        
	        
	        Map<String, FilePart> plateFilesMap = new HashMap<String, FilePart>();
	        for(FilePart fp : plateFiles){
	        	plateFilesMap.put(fp.getFilename(), fp);
	        }
	        
	        //Validate plate files
	        List<String> invalidPlateFiles = new ArrayList<String>();
	        if(plateFilesMap.isEmpty()){
	        	filledForm.reject("upload01", "Missing SGA formatted file(s)");
	        	
	        }else{
	        	//Validate format of each
	        	for(FilePart fp: plateFilesMap.values()){
	        		//Size validity
	        		double megabytes = (double)fp.getFile().length()/oneMegaByte;
	        		
	        		//Format validity
	        		//Object[] obj = fileColumnsValid(fp.getFile().getPath(), 9,9,"str_str_int_int_int_int_int_int_dbl", false);
	        		//Object[] obj = plateFileValid(fp.getFile().getAbsolutePath());
	        		SGAFileValidator sgav = new SGAFileValidator(fp.getFile().getPath(), SGAFileValidator.NORMALIZE_VALIDATION);
	        		
	        		Object[] obj;
	        		try{
	        			obj = sgav.isValid();
	        		}catch(Exception e){
	        			obj = new Object[]{false, "Failed to read file: "+e.getMessage()};
	        		}
	        		boolean isValid = (Boolean) obj[0];
	        		String errorMessage = (String) obj[1];
		        	
	        		//Check content type
	        		String contentType = fp.getContentType();
	        		if(!contentType.equalsIgnoreCase("text/plain") 
	        				&& !contentType.equalsIgnoreCase("application/zip")){
	        			filledForm.reject("upload01", "Error in file "+fp.getFilename()+": invalid format, " +
	        					"files must be of type plain text or zip, found "+fp.getContentType());
	        			break;
	        		}
	        		//Check size
	        		else if(megabytes > maxFileSize){
		        		filledForm.reject("upload01", "Error in file "+fp.getFilename()+": " +
		        				"file exceeds "+maxFileSize+"MB limit");
		        		break;
			        }//Check format
	        		else if(!isValid){
	        			filledForm.reject("upload01", "Error in file "+fp.getFilename() +": "+errorMessage);
			        }
		        }
	        }
	        
	        
	        //If any errors arise, reject the form submission
	        if (filledForm.hasErrors()) {
		        return badRequest(scoreform.render(filledForm));
	        }
	        
	        //Get all file paths/names of plate files
	        StringBuilder plateFilePaths = new StringBuilder();
	        StringBuilder saveNames = new StringBuilder();
	        for(FilePart fp: plateFilesMap.values()){
	        	plateFilePaths.append(fp.getFile().getPath()+",");
	        	saveNames.append(fp.getFilename()+",");
	        }
	        
	        //Run script
	        String zipPath = "";
	        StringBuilder sb = new StringBuilder();
	        try {
	            String line;
	            //Command to be run from shell
	            String cmd =  "Rscript "+ RSCRIPT_PATH +  " -i " +plateFilePaths+  " -s " + saveNames.toString().replaceAll("\\s", "%20") 
	            		+ " -o " +JOBOUTPUTDIR_PATH + " -d savefile -j "+UUID.randomUUID() +" -t score";
	            

	            JFrame f = new JFrame();
	            JTextField tf = new JTextField();tf.setText(cmd);
	            f.getContentPane().add(tf);
	            f.pack();
	            f.setVisible(true);
	            f.setSize(800,200);
	            
	            
	            Process p = Runtime.getRuntime().exec(cmd);
	            
	            //Read in output returned from shell
	            BufferedReader in = new BufferedReader(new InputStreamReader(p.getInputStream()) );
	            
	            while ((line = in.readLine()) != null) {
	            	zipPath = line;
	            	sb.append(line+"\n");
	            }
	            in.close();
	        }
	        catch (Exception e) {
	        	return ok("error in Rscript");
	        }

	        //JOptionPane.showMessageDialog(null, sb.toString());
	        sj.outputPath = zipPath.substring(zipPath.indexOf("other/"), zipPath.length());
	        
	        //Summary details
	        
	        //Save time elapsed
	        long lEndTime = new Date().getTime(); //end time
	        long milliseconds = lEndTime - lStartTime; //check different
	        int seconds = (int) (milliseconds / 1000) % 60 ;
	        int minutes = (int) ((milliseconds / (1000*60)) % 60);
	        //int hours   = (int) ((milliseconds / (1000*60*60)) % 24);
	        String timeElapsed = minutes + " mins "+ seconds + " secs";
	        sj.summary_timeElapsed = timeElapsed;
	        
	        //Save total number of plate files
	        sj.summary_plateFiles = "("+plateFilesMap.size()+") "+saveNames.substring(0,saveNames.length()-1).toString().replaceAll(",", ", ");
	        
			return ok(scoresummary.render(filledForm.get()));
	        
	        /* Check resourceFile for null, then extract the File object and process it */
	     }
	}
	
}