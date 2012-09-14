package models;

import play.data.validation.Constraints.*;

public class NormJob {
	
	@Required
	public Integer numBorders;
	@Required
	public Integer numReplicates;
	
	public Integer linkageCut;
	
	//For script output
	public String outputPath;
	
	//Job summary
	public String summary_timeElapsed;
	public String summary_plateFiles;
	public String summary_arrayIgnoreFile;
	public String summary_linkageCorrection;
	
	public NormJob(){}
	
	public NormJob(Integer numBorders, Integer numReplicates, Integer linkageCut, Boolean doLinkage){
		this.numBorders = numBorders;
		this.numReplicates = numReplicates;
		this.linkageCut = linkageCut;
	}
	
	public String toString(){
		return "numBorders="+numBorders+" numReplicates="+numReplicates+" linkageCutoff="+linkageCut+" doLinkage=NA";
	}
	
}
