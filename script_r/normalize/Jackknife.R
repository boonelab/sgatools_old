#
#
#		?????
#
#

apply_jackknife_filter <- function(sgadata, field, query_map, array_map, plateid_map, orfnames) {
	
	#What we will modify and return
	result = sgadata[[field]]
	
	#HIS control, to be ignored
	his3_ind = grep('YOR202W', orfnames, ignore.case=TRUE)
	
	#Loop each query
	for(i in 1:length(query_map)){
		ind_q = query_map[[i]]
		plates_q = unique(sgadata$plateid[ind_q])
		
		#Loop through plates of current query
		for(j in 1:length(plates_q)){
			
			#Indicies of rows matching current plateid
			curr_plate = toString(plates_q[j])
			ind_p = plateid_map[[curr_plate]]
			
			#Arrays on the current plate for our current query
			array_q = unique(sgadata$array[ind_p])
			#Loop through each array
			for(k in 1:length(array_q)){
				curr_array = array_q[k]
				
				#Ignore his3 control, if exists
				if(curr_array %in% his3_ind)
					next
				
				#Indicies of rows containing our current array
				ind_a = which(sgadata$array[ind_p] == curr_array)
				
				#Get the colonies and indicies of the colonies for the curr array
				curr_dat = sgadata[[field]][ind_p][ind_a];
				curr_ind = ind_p[ind_a];
				
				#Find the non-NA values
				ind_notna = which(!is.na(curr_dat))
				curr_dat_notna = curr_dat[ind_notna]
				
				#Compute the actual variance and estimated jackknife variance
				theta <- function(x){sd(x)}
				vals = jackknife(curr_dat_notna, theta)$jack.values
				
				total_dev = var(curr_dat_notna, na.rm=TRUE)*(length(vals)-1)
				jackknife_dev = (vals^2)*(length(vals)-2)
				
				#Find colonies that contribute more than 90% of total variance
				t = which(total_dev - jackknife_dev > 0.9*total_dev)
				
				#If it is only one of four affecting the variance, remove it
				#If more than one of four is affecting the variance, ignore it
				if(length(t) <= 0.25*length(vals)){
					result[ind_p][ind_a][t] = NA
				}
			}
		}
	}
	
	return(result);
}