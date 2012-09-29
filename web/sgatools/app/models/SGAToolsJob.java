package models;

import validators.Help;
import javax.validation.*;

import play.data.validation.Constraints.*;
public class SGAToolsJob {
	
	//General variables
	public String timeElapsed;
	public Integer jobType;
	public String fileFormat;
	public String plateFileNamesCSV;
	public String outputPath;//For script output
	public String plottedDataPath;//For heatmap data
	
	//Specific to normalization
	public Boolean doArrayDef;
	public String arrayDefPredefined;
	public String selectedArrayDefPlate;
	public String arrayDefCustomFile;
	
	public Integer controlBorders;
	public Integer replicates;
	public Boolean doLinkage;
	public String linkageCutoff;
	public Boolean doScoring;
	
	
	//Specific to scoring
	public String scoringFunction;
	
	public SGAToolsJob(){}
	
	public SGAToolsJob(Integer jobType){
		//Initialize
		this.jobType = jobType;
		this.fileFormat = ComboboxOpts.fileFormat().get(0);
		
		this.doArrayDef = false;
		this.arrayDefPredefined = ComboboxOpts.arrayDef().get(0);
		this.selectedArrayDefPlate = "";
		
		this.controlBorders = 0;
		this.replicates = 4;
		this.doLinkage = false;
		this.linkageCutoff = "200";
		this.doScoring = false;
		
		this.scoringFunction = "";
		
		this.arrayDefCustomFile = "";
	}
}
