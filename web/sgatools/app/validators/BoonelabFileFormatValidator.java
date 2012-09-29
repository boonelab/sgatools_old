package validators;

import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;

import javax.swing.JOptionPane;

public class BoonelabFileFormatValidator {
	public String FILE_PATH;
	public String FILE_NAME;
	public Integer FILE_NUMBER;
	public Boolean MULTIPLE_AD;

	private Boolean IS_CONTROL;
	
	public List<String> FILE_DATA;
	public BoonelabFileFormatValidator(String filePath,String fileName, Integer fileNumber, Boolean multipleArrayDefinitions){
		FILE_PATH = filePath;
		FILE_NAME = fileName;
		FILE_NUMBER = fileNumber;
		FILE_DATA = new ArrayList();
		IS_CONTROL = false;
		MULTIPLE_AD = multipleArrayDefinitions;
	}
	
	public Object[] isValid() throws IOException{
		
		//File name format TYPE_QUERY_ARRAYPLATEID_.*
		String[] filenameSp = FILE_NAME.split("_");
		
		//Should have at least TYPE and QUERY
		if(filenameSp.length < 3){
			return new Object[]{false, "Invalid file name"};
		}
		//Is t a control group?
		if(filenameSp[0].matches("^[Ww][Tt].*")){
			IS_CONTROL = Boolean.TRUE;
		}
		
		//Is query name valid?
		if(!filenameSp[1].matches("^[\\w\\d+-]+$")){
			return new Object[]{false, "Invalid query name"};
		}
		
		//If we are using more than one array definition file, 3rd value should be an array plate id
		if(MULTIPLE_AD){
			if(filenameSp.length < 4){
				return new Object[]{false, "Missing array plate id"};
			}
			if(!Help.isInteger(filenameSp[2])){
				return new Object[]{false, "Invalid array plate id"};
			}
		}
		
		try {
            DataInputStream in = new DataInputStream(new FileInputStream(FILE_PATH));
            BufferedReader br = new BufferedReader(new InputStreamReader(in));
            String strLine;
            
            int lineNumber = 1;
            int skipFirstNLines = 14;
            //Read File Line By Line
            while ((strLine = br.readLine()) != null){
            	if(lineNumber < skipFirstNLines){
            		lineNumber++;
            		continue;
            	}
            	
            	//Trim the line
            	strLine = strLine.trim();
            	
            	//Check if its a comment line
            	if(strLine.startsWith("#")){
                	FILE_DATA.add(strLine);
                    lineNumber++;
                    continue;
                }
                
            	//Check if its a blank line
                if(strLine.isEmpty()){
                	continue;
                }
                
                //Check if its the 3 column format, split by one or more spaces
                String[] sp = strLine.trim().split("\\s+");
                if(sp.length == 4){
                	//Ensure the format is correct
                	if(!Help.isInteger(sp[0])){
                		return new Object[]{false, "value '"+sp[0]+"' on column 1 of line "+lineNumber+" is expected to be of type integer"};
                	}else if(!Help.isInteger(sp[1])){
                		return new Object[]{false, "value '"+sp[1]+"' on column 2 of line "+lineNumber+" is expected to be of type integer"};
                	}else if(!Help.isDouble(sp[2])){
                		return new Object[]{false, "value '"+sp[2]+"' on column 3 of line "+lineNumber+" is expected to be of type double"};
                	}
                	
                	String query = FILE_NUMBER + "";
                	if(IS_CONTROL) query = "ctrl";
                	
                	FILE_DATA.add(sp[0]+"\t"+sp[1]+"\t"+sp[2] + "\t" + FILE_NUMBER + "\t" + query+ "\t-\t-\t-\t-");
                	lineNumber++;
                	continue;
                }else{
                	return new Object[]{false, "Not a valid colony file"};
                }
            }
        }catch(Exception e){
        	JOptionPane.showMessageDialog(null, e.getMessage());
        	return new Object[]{false, "Failed to read"};
        }
		
		return new Object[]{true, "Successfully read file"};
	}
	
}
