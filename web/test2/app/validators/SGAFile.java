package validators;


import java.io.*;
import java.util.*;

/**
 *
 * @author omarwagih
 */
public class SGAFile {
    public List<DataSection> sectionList;
    public String SGA_FILE_PATH;
    
    public SGAFile(String filepath) throws IOException{
        SGA_FILE_PATH = filepath;
        
        //Validate
        
        //Get line count
        int lineCount = getLineCount(filepath);
        
        //Init global/local variables
        sectionList = new ArrayList();
        List<String> currentSection = new ArrayList();
        List<String> currentCommentSection = new ArrayList();
        
        // Open the file
        FileInputStream fstream = new FileInputStream(filepath);

        // Get the object of DataInputStream
        DataInputStream in = new DataInputStream(fstream);
        BufferedReader br = new BufferedReader(new InputStreamReader(in));
        
        String strLine;
        int lineNumber = 0;
        //Read File Line By Line
        while ((strLine = br.readLine()) != null){
            //Incrememnt line number
            lineNumber++;
            
            //Skip comment FOR NOW
            if(strLine.startsWith("#")){
                //Add line to current comment section
                currentCommentSection.add(strLine);
                //Create a data section object
                DataSection csec = 
                        new DataSection(currentCommentSection, true);
                //Add it to list of Data Sections
                sectionList.add(csec);
                //Reset 
                currentCommentSection = new ArrayList();
                continue;
            }
            if(strLine.startsWith("@")){
                //We are at the first header line
                if(currentSection.isEmpty()){
                    currentSection.add(strLine);
                }//We are at a middle/ending header line
                else{
                    //If we're at the last line, add the last line
                    //if(lineNumber == lineCount){
                    //    currentSection.add(strLine);
                    //}
                    
                    //Create a datasection object for all what we have so far
                    DataSection dsec = new DataSection(currentSection, false);
                    //Add it to our main list of data sections
                    sectionList.add(dsec);
                    
                    //Temp print
                    //System.out.println(dsec);
                    
                    //Clear our current section list and add the next header
                    currentSection = new ArrayList();
                    currentSection.add(strLine);
                    
                    //Continue
                }
            }else{
                //Add data lines
                currentSection.add(strLine);
            }
            
            
        }
        
        //If we have anything remaining in the current selection by the end of the file, add it
        if(!currentSection.isEmpty()){
            DataSection dsec = new DataSection(currentSection, false);
            //Add it to our main list of data sections
            sectionList.add(dsec);
                    
            //Temp print
            //System.out.println(dsec);
        }

        //Close the input stream
        in.close();
    }
    
    /**
     * Gets number of lines in a file
     * @param filepath path to file
     * @return Number of lines
     * @throws IOException 
     */
    public int getLineCount(String filepath) throws IOException {
        InputStream is = new BufferedInputStream(new FileInputStream(filepath));
        try {
            byte[] c = new byte[1024];
            int count = 0;
            int readChars = 0;
            while ((readChars = is.read(c)) != -1) {
                for (int i = 0; i < readChars; ++i) {
                    if (c[i] == '\n')
                        ++count;
                }
            }
            return count+1;
        } finally {
            is.close();
        }
    }
    
    
    public class DataSection{
        HeaderLine headerLine;
        List<String> data;
        Boolean isCommentSection;
        
        public DataSection(List<String> sectionLines, boolean isCommentSection){
            //Comment line is treated as a data section
            this.isCommentSection = isCommentSection;
            if(isCommentSection){
                headerLine = null;
                data = sectionLines;
            }else{//Not comment
                //Create header line object from the first line of this data section
                headerLine = new HeaderLine(sectionLines.get(0));
                //Remove header line, only data (if available should be left)
                sectionLines.remove(0);

                //Initialize data
                data = new ArrayList();

                //If we have data in this section other than the header line, process it
                if(!sectionLines.isEmpty()){
                    data = sectionLines;
                }
            }
            
        }
        
        @Override
        public String toString(){
            return "HEADERLINE="+headerLine+"\n"+"DATA="+data;
            
        }
        
        public void printComments(){
            for(DataSection ds: sectionList){
                if(ds.isCommentSection) System.out.println(ds.toString());
            }
        }
    }
    
    class HeaderLine{
        String headerLineText;
        String headerLineName;
        Map<String, String> tagMap;
        
        public HeaderLine(String headerLine){
            //The actual header line as a string
            headerLineText = headerLine;
            
            //Split the line
            String[] sp = headerLine.split("\t");
            
            //Store the name of the header line
            headerLineName = sp[0];
            
            tagMap = new HashMap();
            //If we have tags/values in the header line, process them
            if(sp.length > 1){
                //For loop all tags
                for(int i = 1; i<sp.length; i++){
                    //Separate the tag and its value
                    String[] tag = sp[i].split(":");
                    //Store in tag map
                    tagMap.put(tag[0].toUpperCase(), tag[1]);
                }
            }
        }
        
        @Override
        public String toString(){
            return "NAME="+headerLineName+"\tTAGS="+tagMap.toString();
        }
    }
}
