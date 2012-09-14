package models;

import play.data.validation.Constraints.*;
import validators.Help;

public class SGAToolsJob {
	
	//General variables
	public Integer job_type;
	public String experiment_name;
	public String time_elapsed;
	public String plate_files;
	public String output_path;//For script output
	public Boolean show_plate_heatmaps;//For heatmap
	public String plotted_data_path;//For heatmap data
	
	//Specific to normalization
	public Integer control_borders;
	public Integer replicates;
	public Integer linkage_cutoff;
	public Boolean do_scoring;
	
	//Specific to scoring
	public String scoring_function;
	public Boolean average_scores;
	
	public SGAToolsJob(){}
	
	public SGAToolsJob(Integer job_type){
		//Initialize
		this.job_type = job_type;
		
		this.control_borders = 2;
		this.replicates = 4;
		this.linkage_cutoff = 200;
		this.do_scoring = false;
		this.show_plate_heatmaps = false;
		
		this.scoring_function = "";
		this.average_scores = false;
	}
	
	
}
