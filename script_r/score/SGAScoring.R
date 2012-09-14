#Does scoring given an SGA screen and its control; 7=normalized scores
runScoring = function(INPUT_DATA){
	
	sgadata = INPUT_DATA[[1]]
    suppdata = INPUT_DATA[[2]]
    
	#Pre-process
	#Replace - with NA
	sgadata[sgadata == '-'] = NA 
	
	control.regex = '^ctrl$';
	
	#Find control rows
	control.rows.ind = grep(control.regex, sgadata$query)
	
	#Get rows which are not control
	noncontrol.rows.ind = setdiff(1:dim(sgadata)[1], control.rows.ind)
	
	query.to.median = unique(sgadata$query[noncontrol.rows.ind])
	names(query.to.median) = NA
	for(i in 1:length(query.to.median)){
		#Get unique query
		q = query.to.median[i]
		#Find noncontrol rows with this query
		ind = which(sgadata$query[noncontrol.rows.ind] == q)
		#Put into query->median hash
		query.norm.col.size = as.numeric(sgadata$normalizedcolonysize[noncontrol.rows.ind][ind]);
		names(query.to.median)[i] = median(query.norm.col.size ,na.rm=T)
	}
	array.smf.median = unique(sgadata$array[control.rows.ind]);
	
	########################
	#Get 60% middle median
	vals = sort(as.numeric(sgadata$normalizedcolonysize))#R automatically removes NA values
	length = length(vals)
	#Used to get median of center 60% of colonies, change if needed
  	lower = 0.2
  	upper = 0.8
	middle_median = median(vals[round(lower*length):round(upper*length)], na.rm = TRUE)
	########################
	
	#If no control data/not enough normalized data
	if(length(array.smf.median)>0 && length>0){
	
	#We can only use arrays that have a SMF
	
	names(array.smf.median) = NA
	for(i in 1:length(array.smf.median)){
		#Get unique array
		a = array.smf.median[i]
		#Get control rows with this array
		ind = which(sgadata$array[control.rows.ind] == a)
		#Put in array->median smf hash
		array.norm.col.size = as.numeric(sgadata$normalizedcolonysize[control.rows.ind][ind]);
		names(array.smf.median)[i] = median(array.norm.col.size ,na.rm=T)
	}
	
	#Loop through all non-control rows, find the query and array and compute the score based on values in the previous 2 hashes we made
	for(i in 1:length(noncontrol.rows.ind)){
		query.orf = sgadata$query[noncontrol.rows.ind][i]
		array.orf = sgadata$array[noncontrol.rows.ind][i]
		norm.col.size = as.numeric(sgadata$normalizedcolonysize[noncontrol.rows.ind][i])
		
		query.plate.median = as.numeric(names(query.to.median[which(query.to.median==query.orf)]))
		median.smf = as.numeric(names(array.smf.median[which(array.smf.median==array.orf)]))
		
		#If either is NA, we cant compute a score for this row - insufficent data
		if(length(query.plate.median) != 1 | length(median.smf) != 1){
			next
		}
		
		#Otherwise, we have necessary info, compute score and put it in sgadata
		score = norm.col.size/middle_median - (query.plate.median/middle_median*median.smf/middle_median);
		
		sgadata$score[noncontrol.rows.ind][i] = score;
	}
	
	}#END IF
	
	sgadata[is.na(sgadata)] = '-' 
	
	return(sgadata)
	##################################################
	'
	dat = sgadata
	datc = controldata
	
	names(dat)[scorefieldnumber] = finalcolsize
	names(datc)[scorefieldnumber] = finalcolsize
	
	ignorenamean = function(x){mean(x, na.rm=TRUE)}	#Computes mean ignoring any NA values
	ignorenavar = function(x){var(x, na.rm=TRUE)}	#Computes variance ignoring any NA values
	isnacount = function(x){sum(is.na(x))}	#Count of NA elements
	
	spotstats = 		summaryBy(finalcolsize ~ spots, id=~query+array, data=dat, FUN=c(ignorenamean, ignorenavar, isnacount))
	controlspotstats = 	summaryBy(finalcolsize ~ spots, id=~query+array, data=datc, FUN=c(ignorenamean, ignorenavar, isnacount))
	'
}