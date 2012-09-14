package validators;

import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;

public class ColonyFileFormatValidator {
	public String FILE_PATH;
	public String FILE_NAME;
	public Integer FILE_NUMBER;
	
	private boolean IS_CONTROL;
	
	public List<String> FILE_DATA;
	public ColonyFileFormatValidator(String filePath,String fileName,  Integer fileNumber){
		FILE_PATH = filePath;
		FILE_NAME = fileName;
		FILE_NUMBER = fileNumber;
		FILE_DATA = new ArrayList();
		IS_CONTROL = fileName.matches("^[Ww][Tt].*");
	}
	
	public Object[] isValid() throws IOException{
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
            	
            	if(strLine.startsWith("#")){
                	FILE_DATA.add(strLine);
                    lineNumber++;
                    continue;
                }
                
                if(strLine.isEmpty()){
                	continue;
                }
                
                //Check if its the 3 column format
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
        	return new Object[]{false, "Failed to read "+FILE_NAME};
        }
		
		return new Object[]{true, "Successfully read file"};
	}
}
