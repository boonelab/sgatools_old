######################################################################
## Last modified on 31/05/12 by Omar Wagih (omar.wagih@utoronto.ca) ##
######################################################################

#WORK ON LATER
get_linked_orfs_ind <- function(sgadata, field, orfnames, chromdata) {
	
	#Load chromsosome positions
	pos = chromdata;
	#NO LONGER READ pos = as.data.frame(read.table(chromdata, header=FALSE))
	names(pos) = c('orf', 'chrom', 'start', 'end')
	
	#Only use ORFs which are also in our data
	ind = which(pos$orf %in% orfnames)
	pos = pos[ind,]
	
	#Loop through different chromosomes
	query_uniq = unique(sgadata$query)
	print(length(query_uniq))
	for(i in 1:length(query_uniq)){
		#Current query we are looking at and the chromosome it is on
		query_curr = query_uniq[i]
		query_orf = orfnames[query_curr]
		
		#i contains the index of the row containing the chromosome number
		j = match(query_orf, pos$orf);
		query_chrom = pos$chrom[j]
		query_start = pos$start[j]
		
		#Get arrays associated with this query
		ind = which(sgadata$query == query_curr)
		arrays_curr = sgadata$array[ind]
		
		#Bind the colony sizes (add to data frame)
		arrays_curr = as.data.frame(cbind(arrays_curr, sgadata[[field]][ind]))
		
		#Average colony sizes
		df = aggregate(arrays_curr[[2]], by=list(arrays_curr[[1]]), mean)
		
		print(head(df))
		
		#Column 2 now contains mean colony sizes and column 1 has unique arrays
		#Now, we add start and end chromosome positions to our data frame
		df$orf = orfnames[df[[1]]] #Orf names added as a column
		
		ind = match(df$orf, pos$orf)
		df$chrom = pos$chrom[ind]
		df$start = pos$start[ind]
		df$end = pos$end[ind]
		df$diff = (df$start - query_start)
		
		#Find indicies of the arrays which are on the same chromosome as the current query
		ind = which(df$chrom == query_chrom)
		df = df[ind,]
		
		#Sort by start position and plot
		df = df[order(df$diff),]
		
		print(i)
		#TODO
		if(i==2){
			x=which(!is.na(df[[2]]))
			d = df[x,]
			barplot(d[[2]])
			lines(lowess(d[[2]], f=0.1), col = 2,lwd=3)
		}
		
	}
	
}

get_linked_ind_window <- function(sgadata, orfnames, ch_data, window=200e3) {
	
	#What will be returned
	sgadata_linkage_rows = c()
	
	#Load chromsosome positions
	#pos = as.data.frame(read.table(chromposfile, header=FALSE))
	pos = ch_data
	names(pos) = c('orf', 'chrom', 'start', 'end')
	
	#Only use ORFs which are also in our data
	ind = which(pos$orf %in% orfnames)
	pos = pos[ind,]
	
	#Loop through different chromosomes
	query_uniq = unique(sgadata$query)
	for(i in 1:length(query_uniq)){
		#Current query we are looking at and the chromosome it is on
		query_curr = query_uniq[i]
		query_orf = orfnames[query_curr]
		
		#i contains the index of the row containing the chromosome number
		i = match(query_orf, pos$orf);
		query_chrom = pos$chrom[i]
		query_start = pos$start[i]
		query_end = pos$end[i]
		query_mid = (query_end - query_start)/2
		
		#Get arrays associated with this query
		ind = which(sgadata$query == query_curr)
		arrays_curr = sgadata$array[ind]
		
		#Average colony sizes
		df = as.data.frame(arrays_curr)
		
		#Column 2 now contains mean colony sizes and column 1 has unique arrays
		#Now, we add start and end chromosome positions to our data frame
		df$orf = orfnames[df[[1]]] #Orf names added as a column
		
		ind = match(df$orf, pos$orf)
		df$chrom = pos$chrom[ind]
		df$start = pos$start[ind]
		df$end = pos$end[ind]
		df$mid = (df$end - df$end)/2
		
		#Find indicies of the arrays which are on the same chromosome as the current query
		ind = which(df$chrom == query_chrom)
		df = df[ind,]
		
		#Which are within the window range - i.e. to be removed
		ind_rem = which(abs(df$mid - query_mid) < window)
		arrays_rem = df[[1]][ind_rem]
		
		#Pick our indicies of the main sgadata
		ind = which(sgadata$query == query_curr & (sgadata$array %in% arrays_rem) )
		sgadata_linkage_rows =  c(sgadata_linkage_rows, ind)
		
	}
	print(head(sgadata_linkage_rows, n=3000))
	#Return indicies
	#return(sgadata_linkage_rows)
	
}