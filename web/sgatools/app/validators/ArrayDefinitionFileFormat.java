package validators;

import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;

public class ArrayDefinitionFileFormat {
	public String FILE_PATH;
	public String FILE_NAME;
	
	public List<String> FILE_DATA;
	public ArrayDefinitionFileFormat(String filePath,String fileName, Integer fileNumber){
		FILE_PATH = filePath;
		FILE_NAME = fileName;
	}
	
	public Object[] isValid() throws IOException{
		try {
            DataInputStream in = new DataInputStream(new FileInputStream(FILE_PATH));
            BufferedReader br = new BufferedReader(new InputStreamReader(in));
            String strLine;
            
            int lineNumber = 1;
            int skipFirstNLines = 5;
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
                    lineNumber++;
                    continue;
                }
                
            	//Check if its a blank line
                if(strLine.isEmpty()){
                	continue;
                }
                
                //Check if its the 3 column format, split by one or more spaces
                String[] sp = strLine.trim().split("\\s+");
                if(sp.length == 3){
                	//Ensure the format is correct
                	if(!Help.isInteger(sp[0])){
                		return new Object[]{false, "value '"+sp[0]+"' on column 1 of line "+lineNumber+" is expected to be of type integer"};
                	}else if(!Help.isInteger(sp[1])){
                		return new Object[]{false, "value '"+sp[1]+"' on column 2 of line "+lineNumber+" is expected to be of type integer"};
                	}else if(!Help.isDouble(sp[2])){
                		return new Object[]{false, "value '"+sp[2]+"' on column 3 of line "+lineNumber+" is expected to be of type double"};
                	}
                	
                	FILE_DATA.add(sp[0]+"\t"+sp[1]+"\t"+sp[2]);
                	lineNumber++;
                	continue;
                }else{
                	return new Object[]{false, "Expected 3 columns on line "+lineNumber+" found " + sp.length};
                }
            }
        }catch(Exception e){
        	return new Object[]{false, "Failed to read "+FILE_NAME};
        }
		
		return new Object[]{true, "Successfully read file"};
	}
	
}
