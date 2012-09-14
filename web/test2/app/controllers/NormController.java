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

public class NormController extends Controller {

    final static String RSCRIPT_PATH = "/Users/omarwagih/Desktop/boone-summer-project-2012/script_r/Main.R";
    final static String JOBOUTPUTDIR_PATH = "/Users/omarwagih/Desktop/boone-summer-project-2012/web/test2/public/other";
	
	final static long maxFileSize = 5;
	final static double oneMegaByte = 1048576.0;//1 MB
	
	final static Form<NormJob> normForm = form(NormJob.class);
	
	public static Result blankNormForm() {
		Form<NormJob> newform = normForm.fill(new NormJob(2,4,200, false));
		
		return ok(form.render(newform));
	}
	
	
	
	public static Result submit() {
		long lStartTime = new Date().getTime(); //start time
		
		Form<NormJob> filledForm = normForm.bindFromRequest();
		
	    if (filledForm.hasErrors()) {
	        return badRequest(form.render(filledForm));
	    	//return ok("error:"+filledForm.errorsAsJson());
	    } else {
	    	NormJob nj = filledForm.get();
	    	
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
		        return badRequest(form.render(filledForm));
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
	            		+ " -o " +JOBOUTPUTDIR_PATH + " -d savefile -b " + nj.numBorders 
	            		+ " -r "+nj.numReplicates +" -j "+UUID.randomUUID() +" -t normalize";
	            
	            /*
	            JFrame f = new JFrame();
	            JTextField tf = new JTextField();tf.setText(cmd);
	            f.getContentPane().add(tf);
	            f.pack();
	            f.setVisible(true);
	            f.setSize(800,200);
	            */
	            
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
	        nj.outputPath = zipPath.substring(zipPath.indexOf("other/"), zipPath.length());
	        
	        //Summary details
	        
	        //Save time elapsed
	        long lEndTime = new Date().getTime(); //end time
	        long milliseconds = lEndTime - lStartTime; //check different
	        int seconds = (int) (milliseconds / 1000) % 60 ;
	        int minutes = (int) ((milliseconds / (1000*60)) % 60);
	        //int hours   = (int) ((milliseconds / (1000*60*60)) % 24);
	        String timeElapsed = minutes + " mins "+ seconds + " secs";
	        nj.summary_timeElapsed = timeElapsed;
	        
	        //Save total number of plate files
	        nj.summary_plateFiles = "("+plateFilesMap.size()+") "+saveNames.substring(0,saveNames.length()-1).toString().replaceAll(",", ", ");
	        
	        //Array files used
	        //nj.summary_arrayIgnoreFile = ignoreFile == null? "-" : ignoreFile.getFilename();
	        
	        //Save linkage applied or no?
	        //nj.summary_linkageCorrection = posFile == null? "-" : "Yes ("+nj.linkageCut+" KB)";

	        //Save 
	        
			return ok(summary.render(filledForm.get()));
	        
	        /* Check resourceFile for null, then extract the File object and process it */
	     }
	}
	
    /**
    * Validates tab delimited file based on number of columns and their types
     * ex. minNumCol = 3, maxNumCol = 4 means the file can have 3-4 tab 
     * delimited columns, and colType = "str_str_dbl_dbl" means the first
     * two columns must be a string and the other two must be double
     * @param f file to validate
     * @param minNumCol min number of tab delimited columns
     * @param maxNumCol max number of tab delimited columns
     * @param colType type of each column separated by '_' types are: int, dbl and str
     * @return returns true if file is valid, false otherwise
     */
    public static Object[] fileColumnsValid(String filepath, int minNumCol, int maxNumCol, String colType, boolean hasHeader){
        String errorMessage = "";
        Object[] returnObj = new Object[2];
    	try{
        	// Open the file that is the first 
			// command line parameter
			FileInputStream fstream = new FileInputStream(filepath);
			// Get the object of DataInputStream
			DataInputStream in = new DataInputStream(fstream);
			BufferedReader br = new BufferedReader(new InputStreamReader(in));
			String str;
			int line = 1;
			//Read File Line By Line
        	while ((str = br.readLine()) != null)   {
        		if(hasHeader && line==1){
        			line++;
        			continue;
        		}
        		String[] str_sp = str.split("\t");
                  
                  
                //Ensure correct number of columns
                if(str_sp.length < minNumCol || str_sp.length > maxNumCol){
                    String expectedCol = "";
                    if(minNumCol == maxNumCol) expectedCol = minNumCol+"";
                    else expectedCol = minNumCol + "-" + maxNumCol;
                    errorMessage =" on line "+line+" expected "+expectedCol+ " columns, found "+str_sp.length;
                    returnObj[0] = false;
                    returnObj[1] = errorMessage;
                    return returnObj;
                }
                  
                //Ensure type of column is correct
                String[] type_sp = colType.split("_");
                
                for(int i = 0; i<str_sp.length; i++){
                    String s = str_sp[i];
                    String t = type_sp[i];
                    int column = i+1;
                    
                    //If string, we dont need to do anything
                    if(t.equalsIgnoreCase("str")){
                        //No need to do anything
                    }
                    
                    //If expected double, check it
                    if(t.equalsIgnoreCase("dbl")){
                    	if(!HelpMethods.isDouble(s)){
                    		errorMessage = " on line "+line+" expected column "+column+" to be of type double";
                            returnObj[0] = false;
                            returnObj[1] = errorMessage;
                            return returnObj;
                    	}
                      }
                    
                    //If expected integer, check it
                    if(t.equalsIgnoreCase("int")){
                    	if(!HelpMethods.isInteger(s)){
                    		errorMessage = " on line "+line+" expected column "+column+" to be of type integer";
                            returnObj[0] = false;
                            returnObj[1] = errorMessage;
                            return returnObj;
                    	}
                    }
                }
                line++;
        	  }
        	  //Close the input stream
        	  in.close();
        	  if((line == 1 && !hasHeader) || (line==2 && hasHeader)){
        		  //Empty file
        		  errorMessage = " file is empty";
                  returnObj[0] = false;
                  returnObj[1] = errorMessage;
                  return returnObj;
        	  }
        	  returnObj[0] = true;
              returnObj[1] = "";
              return returnObj;
       }catch (Exception e){//Catch exception if any
    	   System.err.println("Error: " + e.getMessage());
    	   returnObj[0] = false;
           returnObj[1] = e.getMessage();
           return returnObj;
       }
        
    }
	
    public static Object[] plateFileValid(String filepath){
    	try{
	    	FileInputStream fstream = new FileInputStream(filepath);
			// Get the object of DataInputStream
			DataInputStream in = new DataInputStream(fstream);
			BufferedReader br = new BufferedReader(new InputStreamReader(in));
			String str;
			int line = 1;
			String constraints = "";
			String errorMessage = "";
			Object[] toReturn = new Object[2];
			//Read File Line By Line
	    	while ((str = br.readLine()) != null)   {
	    		if(line==1){
	    			//Validate header
	    			String[] headers = str.split("\t");
	    			List<String> headerList = new ArrayList<String>();
	    			StringBuilder headerSB = new StringBuilder();
	    			for(String s: headers){
	    				headerList.add(s);
	    				headerSB.append(s+", ");
	    			}
	    			
	    			String headerStr = headerSB.toString().substring(0, headerSB.length()-2);
	    			
	    			//Process
	    			//Case 1: simple, just 3 columns
	    			if(headerList.size() == 3){
	    				//Check they are the right headers
	    				if(!headerList.contains("row")||!headerList.contains("column")||!headerList.contains("colonysize")){
	    					errorMessage = "expected 3 columns with header names [row, column, colonysize], found ["+headerStr+"]";
	    					toReturn[0] = false; toReturn[1] = errorMessage; return toReturn;
	    				}else{
	    					StringBuilder sb = new StringBuilder();
	    					for(String s: headerList){
	    						if(s.equals("row") || s.equals("column")) sb.append("int_");
	    						if(s.equals("colonysize")) sb.append("dbl_");
	    					}
	    					constraints = sb.toString().substring(0, sb.length()-1);
	    				}
	    			}else if(headerList.size() == 4){
	    				if(!headerList.contains("row")||!headerList.contains("column")||!headerList.contains("colonysize") || !headerList.contains("platenum")){
	    					errorMessage = "expected 4 columns with header names [row, column, colonysize, platenum], found ["+headerStr+"]";
	    					toReturn[0] = false; toReturn[1] = errorMessage; return toReturn;
	    				}else{
	    					StringBuilder sb = new StringBuilder();
	    					for(String s: headerList){
	    						if(s.equals("row") || s.equals("column") || s.equals("platenum")) sb.append("int_");
	    						if(s.equals("colonysize")) sb.append("dbl_");
	    					}
	    					constraints = sb.toString().substring(0, sb.length()-1);
	    				}
	    			}else if(headerList.size() == 5){
	    				if(!headerList.contains("row")||!headerList.contains("column")||!headerList.contains("colonysize") || !headerList.contains("query")|| !headerList.contains("array")){
	    					errorMessage = "expected 5 columns with header names row, column, colonysize, query, array, found ["+headerStr+"]";
	    					toReturn[0] = false; toReturn[1] = errorMessage; return toReturn;
	    				}else{
	    					StringBuilder sb = new StringBuilder();
	    					for(String s: headerList){
	    						if(s.equals("row") || s.equals("column")) sb.append("int_");
	    						if(s.equals("colonysize")) sb.append("dbl_");
	    						if(s.equals("query") || s.equals("array")) sb.append("str_");
	    					}
	    					constraints = sb.toString().substring(0, sb.length()-1);
	    				}
	    			}else if(headerList.size() == 6){
	    				if(!headerList.contains("row")||!headerList.contains("column")||!headerList.contains("colonysize") 
	    						|| !headerList.contains("query")|| !headerList.contains("array") || !headerList.contains("platenum")){
	    					errorMessage = "expected 6 columns with header names [row, column, colonysize, query, array, platenum] found ["+headerStr+"]";
	    					toReturn[0] = false; toReturn[1] = errorMessage; return toReturn;
	    				}else{
	    					StringBuilder sb = new StringBuilder();
	    					for(String s: headerList){
	    						if(s.equals("row") || s.equals("column") || s.equals("platenum")) sb.append("int_");
	    						if(s.equals("colonysize")) sb.append("dbl_");
	    						if(s.equals("query") || s.equals("array")) sb.append("str_");
	    					}
	    					constraints = sb.toString().substring(0, sb.length()-1);
	    				}
	    			}else{
	    				errorMessage = "expected 3-6 columns, found "+headerStr.length();
    					toReturn[0] = false; toReturn[1] = errorMessage; return toReturn;
	    			}
	    			

	    	    	//Process using other validator
	    			headerStr = headerStr.replace(" ,", "_");
	    			return fileColumnsValid(filepath, headerList.size(),headerList.size(),constraints, true);
	    		}
	    	}
	    	
    	}catch(Exception e){
    		
    	}
    	
    	return null;
    }
  
}