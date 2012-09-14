spatial_normalization <- function(sgadata, field, ignore_ind, plateid_map) {
	gaussian_filt = fgaussian(7,2)
	average_filt = faverage(9)
	
	if(!exists('ignore_ind')){
		ignore_ind = c()
	}
	
	uniq_plateids = unique(sgadata$plateid)
	
	#Data before rows ignored
  	returned_data = sgadata[[field]]
  	#Ignore these rows
  	curr_data = returned_data
  	curr_data[ignore_ind] = NA
	
 	#progressBar <- txtProgressBar(style=3, width=40)
	for(i in 1:length(uniq_plateids)){
		#Set progress bar
  		#setTxtProgressBar(progressBar, i)
		
		#Get the plate id and the indicies of rows corresponding to that plate id
  		curr_plateid = uniq_plateids[i]
  		ind = plateid_map[curr_plateid][[1]]
  		
  		#Construct plate map used to make plate matrix of colonies
  		r = sgadata$row[ind]
  		c = sgadata$col[ind]
  		plate_ind = (c - 1)*NUM_ROWS + r
  		
  		#Default index to 1
  		plate_map = matrix(1, NUM_ROWS, NUM_COLS)
  		plate_map[plate_ind] = ind
  		
  		#Keeps track of NA elements in plate_map which were replaced by 1
  		plate_map_ref = matrix(-1, NUM_ROWS, NUM_COLS)
  		plate_map_ref[plate_ind] = ind
  		
  		#Indicies of NA values in plate_map which were replaced by a 1
  		ind_pm_na = which(plate_map_ref < 0)
  		
  		#Construct the matrix of colonies
  		plate_mat = matrix(curr_data[as.vector(plate_map)],NUM_ROWS,NUM_COLS)
  		plate_mat[ind_pm_na] = NA
  		
  		#Fill NA with a placeholder (mean of all colonies) 
  		t = plate_mat
  		ind_na = which(is.na(t))
  		t[ind_na] = mean(plate_mat, na.rm=TRUE)
  		#Fill in NA with smoothed version of neighbors using gaussian blur
  		filt_g = applyfilter(t, gaussian_filt)
  		t[ind_na] = filt_g[ind_na]
  		
  		#Apply median/average filters
  		filtered = medianfilter2d(t, 7)
  		filtered = applyfilter(filtered, average_filt, 'replicate')
  		
  		filtered = filtered;
  		f = as.numeric(filtered - mean(filtered))
  		
  		returned_data[plate_map] = (returned_data[plate_map] - f);
	}
	#close(progressBar)
	
	#Return final result
	return(returned_data)
}