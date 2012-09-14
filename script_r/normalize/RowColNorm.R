#
#
# DETAILS HERE
#
#
#

rowcol_normalization <- function(sgadata, field, ignore_ind, plateid_map) {
  
  	#If we have not defined a list of ignore rows, set it to empty
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
  		
  		#Get colonies
  		colonies = curr_data[ind];
  		ind_isna = which(is.na(colonies))
  		ind_notna = which(!is.na(colonies))
		
		########## SMOOTH ACROSS COLUMNS ##########
		columns = sgadata$col[ind]
		
		#Sort values with index return
		vals_sorted = sort(columns[ind_notna], index.return=TRUE)
		ind_sorted = vals_sorted[[2]]
		vals_sorted = vals_sorted[[1]]
		
		#Window size to be used in lowess smoothing
		span = length(which(vals_sorted <= 6))/(NUM_ROWS*NUM_COLS)
		
		if(span>0)
			lowess_smoothed = lowess(columns[ind_notna][ind_sorted], colonies[ind_notna][ind_sorted], f=0.09, iter=5)
		else
			lowess_smoothed = colonies[ind_notna][ind_sorted]
		
		#We only care about y values returned by the function
		if(length(lowess_smoothed)==2)
			lowess_smoothed = lowess_smoothed[['y']]
		#print(lowess_smoothed)
		
		tmp = lowess_smoothed / mean(lowess_smoothed)
		returned_data[ind][ind_notna][ind_sorted] = returned_data[ind][ind_notna][ind_sorted] / tmp;
		
		#PUT IGNORED VALUES BACK
		ind_uniqcols = which(duplicated(columns))
		col_to_smoothed_hash = lowess_smoothed[ind_uniqcols]
		names(col_to_smoothed_hash) = columns[ind_uniqcols]
		
		for(i in 1:length(ind_isna)){
			#Column we are looking at- convert to string as R uses string keys in all hashmaps
			this_col = toString(columns[ind_isna][i])
			
			#This column is not in our map, ignore it
			if(is.na(col_to_smoothed_hash[this_col]))
				next
				
			#Get smoothed value for this column
			this_val = col_to_smoothed_hash[this_col]
			
			#Update it
			tmp = this_val/mean(lowess_smoothed)
			returned_data[ind][ind_isna][i] = returned_data[ind][ind_isna][i] / tmp
		}
		
		########## SMOOTH ACROSS ROWS ##########
		
		tmpdata = returned_data 
		tmpdata[ignore_ind] = NA
		rows = sgadata$row[ind]
		colonies = tmpdata[ind]
		
		#Sort row values with index return
		vals_sorted = sort(rows[ind_notna], index.return=TRUE)
		ind_sorted = vals_sorted[[2]]
		vals_sorted = vals_sorted[[1]]
		
		#Window size to be used in lowess smoothing
		span = length(which(vals_sorted <= 6))/(NUM_ROWS*NUM_COLS)
		
		if(span>0)
			lowess_smoothed = lowess(rows[ind_notna][ind_sorted], colonies[ind_notna][ind_sorted], f=0.09, iter=5)
		else
			lowess_smoothed = tmpdata[ind_notna][ind_sorted]		
		
		#We only care about y values returned by the function
		if(length(lowess_smoothed)==2)
			lowess_smoothed = lowess_smoothed[['y']]
		
		tmp = lowess_smoothed / mean(lowess_smoothed)
		returned_data[ind][ind_notna][ind_sorted] = returned_data[ind][ind_notna][ind_sorted] / tmp;
		
		#PUT IGNORED VALUES BACK
		ind_uniqrows = which(duplicated(rows))
		row_to_smoothed_hash = lowess_smoothed[ind_uniqrows]
		names(row_to_smoothed_hash) = rows[ind_uniqrows]
		
		for(i in 1:length(ind_isna)){
			#Row we are looking at- convert to string as R uses string keys in all hashmaps
			this_row = toString(rows[ind_isna][i])
			
			#This column is not in our map, ignore it
			if(is.na(row_to_smoothed_hash[this_row]))
				next
				
			#Get smoothed value for this column
			this_val = row_to_smoothed_hash[this_row]
			
			#Update it
			tmp = this_val/mean(lowess_smoothed)
			returned_data[ind][ind_isna][i] = returned_data[ind][ind_isna][i] / tmp
		}

	}
	
	#close(progressBar)
	return(returned_data)
}