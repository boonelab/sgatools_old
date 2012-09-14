/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package validators;

import java.io.*;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.swing.JOptionPane;

import validators.SGAFile.DataSection;
import validators.SGAFile.HeaderLine;

/**
 *
 * @author omarwagih
 */
public class SGAFileValidator {
    public SGAFile SGA_FILE;
    private String SGA_FILE_PATH;
    private Integer FILE_NUMBER;
    
    //Regex constants
    private final String HEADER_LINE_REGEX = "^@[A-Za-z][A-Za-z](\t[A-Za-z][A-Za-z0-9]:[ -~]+)+$";
    private final String INTEGER_REGEX = "\\d+";
    private final String DOUBLE_REGEX = "-?\\d+(\\.\\d+)?";
    private final String STRING_REGEX = "[^/\t]+";
    
    private final String KEYVALUEPAIR_REGEX = "\\w+=[\\w\\.]+";
    private final String KEYVALUEPAIRS_REGEX = 
            "^\\[("+KEYVALUEPAIR_REGEX+")(,\\s*"+KEYVALUEPAIR_REGEX+")*\\]$";
    
    private final String EMPTY_REGEX = "^\\s*$|^-$";
    
    private final String VERSION_REGEX = "(\\d+)(\\.*\\d+)*";
    
    public static Integer NORMALIZE_VALIDATION = 0;
    public static Integer SCORE_VALIDATION = 1;
    public static Integer validationType;
    
    //File format constants
    //@HD required tags/regex
    String[] HD_requiredTags;
    String[] PL_dataformat;
    String[] PL_dataformat_score;
    String[] SP_requiredTags;
    
    Map<String, String> SP_columns, KVP_format;
    
    public SGAFileValidator(String filepath, Integer fileNumber){
        SGA_FILE_PATH = filepath;
        FILE_NUMBER = fileNumber;
        
        //Initialize file format constants
        HD_requiredTags = new String[]{"VN", VERSION_REGEX, "IA", "\\w+"};
        
        PL_dataformat = new String[]{
            INTEGER_REGEX,//Row*
            INTEGER_REGEX,//Column*
            INTEGER_REGEX,//Plate ID*
            DOUBLE_REGEX,//Raw colony size*
            STRING_REGEX       + "|" + EMPTY_REGEX,//Query ORF*
            STRING_REGEX       + "|" + EMPTY_REGEX,//Array ORF*
            DOUBLE_REGEX       + "|" + EMPTY_REGEX,//Normalized colony size*
            DOUBLE_REGEX       + "|" + EMPTY_REGEX,//Score
            KEYVALUEPAIRS_REGEX + "|" + EMPTY_REGEX//Supp. data 
        };
       
        SP_requiredTags = new String[]{"CF", "(\\w+)(,\\s*\\w+)*"};
        
        SP_columns = new HashMap();
        SP_columns.put("ORF"  , STRING_REGEX);
        SP_columns.put("IGNA" , "[01]");
        SP_columns.put("IGNQ" , "[01]");
        SP_columns.put("CHNUM", INTEGER_REGEX);
        SP_columns.put("CHSTR", INTEGER_REGEX);
        SP_columns.put("CHEND", INTEGER_REGEX);
        SP_columns.put("SMF"  , DOUBLE_REGEX);
        
        //Not used
        KVP_format = new HashMap();
        KVP_format.put("ORF", STRING_REGEX);
        KVP_format.put("QCHR", STRING_REGEX);
        KVP_format.put("QSTR", STRING_REGEX);
        KVP_format.put("QEND", STRING_REGEX);
        KVP_format.put("QSMF", STRING_REGEX);
        KVP_format.put("ACHR", STRING_REGEX);
        KVP_format.put("ASTR", STRING_REGEX);
        KVP_format.put("AEND", STRING_REGEX);
        KVP_format.put("ASMF", STRING_REGEX);
        KVP_format.put("IGNA", STRING_REGEX);
        
    }
    
    public Object[] isValid() throws IOException{
        
        //List of valid header lines 
        List<String> remainingHeaderLines = new ArrayList();
        remainingHeaderLines.add("@HD");
        remainingHeaderLines.add("@PL");
        remainingHeaderLines.add("@SP");
        
        //Check if filepath exists
        File SGAFile = new File(SGA_FILE_PATH);
        if(! SGAFile.exists())
            return new Object[]{false, "File does not exist"};
       
        boolean isThreeColFormat = false;
        List<String> threeColData = new ArrayList();
        
        //Check regular expression of header lines to ensure their format
        try {
            DataInputStream in = new DataInputStream(new FileInputStream(SGA_FILE_PATH));
            BufferedReader br = new BufferedReader(new InputStreamReader(in));
            String strLine;
            
            int lineNumber = 1;
            int uncommentedLineNumber = 1;
            
            int skipFirstNLines = 0;
            //Read File Line By Line
            while ((strLine = br.readLine()) != null){
            	if(strLine.startsWith("Colony Project")){
            		lineNumber++;
            		skipFirstNLines = 13;
            		continue;
            	}
            	
            	if(lineNumber <= skipFirstNLines){
            		lineNumber++;
            		continue;
            	}
            	
                if(strLine.startsWith("#")){
                	threeColData.add(strLine);
                    lineNumber++;
                    continue;
                }
                
                if(strLine.isEmpty()){
                	continue;
                }
                
                //Check if its the 3 column format
                String[] sp = strLine.trim().split("\\s+");
                if(sp.length == 4 && !strLine.toLowerCase().startsWith("@")){
                	//Ensure the format is correct
                	if(!Help.isInteger(sp[0])){
                		return new Object[]{false, "value '"+sp[0]+"' on column 1 of line "+lineNumber+" is expected to be of type integer"};
                	}else if(!Help.isInteger(sp[1])){
                		return new Object[]{false, "value '"+sp[1]+"' on column 2 of line "+lineNumber+" is expected to be of type integer"};
                	}else if(!Help.isDouble(sp[2])){
                		return new Object[]{false, "value '"+sp[2]+"' on column 3 of line "+lineNumber+" is expected to be of type double"};
                	}
                	
                	isThreeColFormat = true;
                	threeColData.add(sp[0]+"\t"+sp[1]+"\t"+sp[2]);
                	lineNumber++;
                	continue;
                }
                
                //Ensure the first non-comment line is the @HD line
                else if(uncommentedLineNumber == 1 && 
                        !strLine.toLowerCase().startsWith("@hd"))
                    return new Object[]{false, "The first uncommented line is not a valid @HD header line"};
                
                //Otherwise, ensure all header lines have proper format
                if(strLine.toLowerCase().startsWith("@") 
                        && !strLine.matches(HEADER_LINE_REGEX))
                    return new Object[]{false, "Line "+lineNumber+" is not a valid header line"};
                
                
                else{
                    lineNumber++;
                    uncommentedLineNumber++;
                }
            }
        } catch (Exception ex) {
            return new Object[]{false, "Failed to read file"};
        }
        
        
        //If we have a 3 column format, covert it to SGA file format and ignore validation
        if(isThreeColFormat){
        	DateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        	Date date = new Date();
        	
        	String writePath = SGAFile.getPath();
			try{
				// Create file 
				FileWriter fstream = new FileWriter(writePath);
				BufferedWriter out = new BufferedWriter(fstream);
				out.write("#Converted from 3-column format by SGATools 1.0 on "+dateFormat.format(date)+"\n");
				out.write("@HD\tVN:1.0.0\tIA:NA\n");
				out.write("@PL\tNM:3-column converted plate data\n");
				for(String threeColLine: threeColData){
					out.write(threeColLine+"\t"+FILE_NUMBER+"\t-\t-\t-\t-\t-\n");
				}
				//Close the output stream
				out.close();
				
				return new Object[]{true, "3-column format successfully converted"};
			}catch (Exception e){//Catch exception if any
				return new Object[]{false, "Failed to generate SGA file from 3-column format"};
			}
        }
        
        
        //Header lines are valid, load the data 
        SGA_FILE = new SGAFile(SGA_FILE_PATH);
        
        //Validate header names/tag names
        for(DataSection ds: SGA_FILE.sectionList){
            if(ds.isCommentSection) continue;
            
            String hd = ds.headerLine.headerLineName;
            
            if(!remainingHeaderLines.contains(hd.toUpperCase())){
                return new Object[]{false, "Invalid/duplicate header '"
                        +ds.headerLine.headerLineText+"'"};
            }
            
            //Validate first line header
            if(hd.equalsIgnoreCase("@HD")){
                //Check if required tags are in the header line
                Object[] res = headerTagsValid(ds.headerLine, HD_requiredTags);
                boolean isValid = (Boolean) res[0];
                if(!isValid)
                    return res;
                //Mark it as used already to avoid duplicates
                remainingHeaderLines.remove("@HD");
            }
            
            //Validate plate data
            if(hd.equalsIgnoreCase("@PL")){
            	Object[] res = tabularDataValid(ds, PL_dataformat);
                boolean isValid = (Boolean) res[0];
                if(!isValid)
                    return res;
                
                //Validate kvps TODO
                
                if(ds.data.isEmpty())
                    return new Object[]{false, "No data provided with plate header line"};
                //Mark it as used already to avoid duplicates
                remainingHeaderLines.remove("@PL");
            }
            
            if(hd.equalsIgnoreCase("@SP")){
                //Check if required tags are in the header line
                Object[] res = headerTagsValid(ds.headerLine, SP_requiredTags);
                boolean isValid = (Boolean) res[0];
                if(!isValid)
                    return res;
                
                //Validate that data is not empty
                if(ds.data.isEmpty())
                    return new Object[]{false, "No data provided with supplementry header line"};
                
                //Get column regexes based on the column format in CF tag
                String[] SP_customColumnFormat = getSuppDataColumnFormat(ds.headerLine);
                if(SP_customColumnFormat == null){
                    return new Object[]{false, "One or more column names "
                            + "provided in the CF tags are invalid"};
                }
                
                //Ensure ORF is there
                boolean orfColAvailable = false;
                for(String col: ds.headerLine.tagMap.get("CF").split(",\\s*"))
                    if(col.equalsIgnoreCase("ORF")) orfColAvailable = true;
                if(!orfColAvailable){
                    return new Object[]{false, "Missing required ORF column in supplementry data"};
                }
                
                //Validate the columns using the regexes obtained
                res = tabularDataValid(ds, SP_customColumnFormat);
                isValid = (Boolean) res[0];
                if(!isValid)
                    return res;
                
                //Mark it as used already to avoid duplicates
                remainingHeaderLines.remove("@SP");
            }
        }
        
        //Ensure the required header lines are there
        if(remainingHeaderLines.contains("@HD"))
            return new Object[]{false, "@HD header line is missing"};
        if(remainingHeaderLines.contains("@PL"))
            return new Object[]{false, "@PL header line is missing"};
        
        
        return new Object[]{true, "All lines valid"};
    }
    
    
    
    public Object[] headerTagsValid(HeaderLine hl, String[] requiredTags){
       
       for(int i = 0; i<requiredTags.length; i=i+2){
            String requiredTag = requiredTags[i].toUpperCase();
            String requiredTagRegex = requiredTags[i+1];
            
            //Ensure required tag is there
            if(!hl.tagMap.containsKey(requiredTag))
                return new Object[]{false, "The required tag '"+requiredTag+"' was not found"};
            
            
            //If its there, ensure its value matches the regex
            if(!hl.tagMap.get(requiredTag).matches(requiredTagRegex)){
                return new Object[]{false, "The value of the required tag '"+requiredTag+"' is invalid"};
            }
            
        }
        
        //Success
        return new Object[]{true, "Header tags valid"};
    }

    public Object[] tabularDataValid(DataSection ds, String[] columnFormat){
        for(int i=0; i<ds.data.size(); i++){
            //Split tabular data
            String line = ds.data.get(i);
            String[] sp = line.split("\t",-1);
            
            //If the number of columns is not equal to what is required...
            if(sp.length != columnFormat.length){
                return new Object[]{false, "Expected "+(columnFormat.length)+
                        " columns on line '"+line+"', found "+sp.length};
            }
            
            //Column number is right, now validate the type of each column
            for(int col=0; col<sp.length; col++){
                String colRegex = columnFormat[col];
                String colValue = sp[col];
                //If column does not match its required regex...
                if(!colValue.matches(colRegex)){
                    return new Object[]{false, "Invalid format for column "+(col+1)+" of line '"+line+"'"};
                }
            }
            
        }
        
        //Valid
        return new Object[]{true, "Valid"};
    }
    
    
    public String[] getSuppDataColumnFormat(HeaderLine suppHeaderLine){
        String format = suppHeaderLine.tagMap.get("CF");
        String[] sp = format.split(",\\s*");
        String[] columnFormat = new String[sp.length];
        
        for(int i =0; i<sp.length; i++){
            String col = sp[i].toUpperCase();
            
            //If the columns entered is not in the standard SP columns, return null 
            //Null used as an indicator that its invalid
            if(!SP_columns.containsKey(col))
                return null;
            
            columnFormat[i] = SP_columns.get(col);
        }
        
        return columnFormat;
    }
}
