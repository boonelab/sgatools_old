# APPLY_PLATE_NORMALIZATION - corrects colony sizes for plate effects

plate_normalization <- function(sgadata, field, ignore_ind, overall_median, plateid_map) {
  #Used to get median of center 60% of colonies, change if needed
  lower = 0.2
  upper = 0.8
  
  uniq_plateid = unique(sgadata$plateid)
  result = sgadata[[field]]
  vals = sort(sgadata[[field]]) #R automatically removes NA values
  length = length(vals)
  
  # Median of the middle 60% of all the data
  if(!exists('overall_median')){
  	overall_median = median(vals[round(lower*length):round(upper*length)], na.rm = TRUE)
  }	
  
  #If we have not defined a list of ignore rows, set it to empty
  if(!exists('ignore_ind')){
  	ignore_ind = c()
  }
  
  #Data before rows ignored
  before_ignore = sgadata[[field]]
  #Ignore these rows
  sgadata[[field]][ignore_ind] = NA
  
  #progressBar <- txtProgressBar(style=3, width=40)
  #Loop and do plate correction for each unique plate
  for (i in 1:length(uniq_plateid)){
  	#Set progress bar
  	#setTxtProgressBar(progressBar, i)
  	
  	#Get the plate id and the indicies of rows corresponding to that plate id
  	curr_plateid = uniq_plateid[i]
  	ind = plateid_map[curr_plateid][[1]]
  	
  	#Sort the data to be used in median calculation
  	vals = sgadata[[field]][ind]
  	vals = sort(vals)
  	
  	#If plate is incomplete and has insufficeint colonies, we skip it
  	if(length(vals) < 10)
  		next
  	
  	#Median of the plate
  	length = length(vals)
  	plate_median = median(vals[round(lower*length):round(upper*length)], na.rm = TRUE)
  	
  	#Store the final result computed using all data (including ignored) in result array
  	result[ind] = before_ignore[ind]* (overall_median/plate_median)
  	
  }
  #close(progressBar) 
  #Return final result
  return(result)
	
}