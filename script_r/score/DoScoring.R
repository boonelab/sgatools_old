#Does scoring given an SGA screen and its control
doScoring = function(sgadata, controldata, scorefieldnumber=dim(sgadata)[2]){
	
	#return(sgadata_subset)
	dat = sgadata
	datc = controldata
	
	names(dat)[scorefieldnumber] = 'finalcolsize'
	names(datc)[scorefieldnumber] = 'finalcolsize'
	
	ignorenamean = function(x){mean(x, na.rm=TRUE)}	#Computes mean ignoring any NA values
	ignorenavar = function(x){var(x, na.rm=TRUE)}	#Computes variance ignoring any NA values
	isnacount = function(x){sum(is.na(x))}	#Count of NA elements
	
	spotstats = 		summaryBy(finalcolsize ~ spots, id=~query+array, data=dat, FUN=c(ignorenamean, ignorenavar, isnacount))
	controlspotstats = 	summaryBy(finalcolsize ~ spots, id=~query+array, data=datc, FUN=c(ignorenamean, ignorenavar, isnacount))
	
	uniquespots = spotstats[[1]];
	giscore = c()
	
	for(i in 1:dim(spotstats)[1]){
		curr_spot = uniquespots[i]
		
		#Do GI score
		ind = which(controlspotstats[[1]] == curr_spot)
		spot_smf = controlspotstats[ind, 2]#Gets mean column in control data at indicies of the spot
		spot_dmf = spotstats[i,2]#Gets the mean column at this i
		giscore[i] = spot_dmf-spot_smf#Score calculation
		
		#Do p-value calculation
	}
	
	#Put the scores back into main data
	spotstats$giscore = giscore
	
	#Normalize to 1?
	#TODO
	
	return(spotstats)
}