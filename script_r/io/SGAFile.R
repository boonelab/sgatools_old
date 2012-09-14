readSGAFile <- function(inputfile){
	no_col <- max(count.fields(inputfile, sep = "\t"))
	read.data.raw = read.delim(inputfile, sep='\t', header=F, comment.char='', stringsAsFactors=FALSE, fill=TRUE,col.names=1:no_col)
	
	comment_ind = grep( '^#.*', read.data.raw[[1]])
	print(head(comment_ind))
	read.data = read.data.raw[-comment_ind,]
	print(head(read.data))
	#Indicies of all header lines            
	header_lines_ind = grep('@[A-Za-z]{2}', read.data[[1]])
	header_lines = read.data[[1]][header_lines_ind]

	#Find first header line
	HD_start_ind = grep('@[Hh][Dd]', read.data[[1]])
	#Find plate header
	PL_start_ind = grep('@[Pp][Ll]', read.data[[1]])

	PL_end_ind = PL_start_ind
	#If @PL is the last header line, the end is the end of the data (length of rows)
	i = grep('@[Pp][Ll]', header_lines);
	if(i == length(header_lines)){
		PL_end_ind = dim(read.data)[1]
	}else{
		PL_end_ind = header_lines_ind[i+1]-1
	}
	#Our plate data
	PL_data = read.data[(PL_start_ind + 1): (PL_end_ind),]
	PL_data[PL_data == '-'] = NA
	
	#Now data is formatted as:
	#Row, Col, Plate id, Raw colony size, Query ORF, Array ORF, and possible NAs
	names(PL_data) = c('row', 'col',  'colonysize','plateid', 'query', 'array', 'normalizedcolonysize', 'score', 'supp')
	
	#Set numerical columns - the rest are characters 
	PL_data[[1]] = as.numeric(PL_data[[1]])
	PL_data[[2]] = as.numeric(PL_data[[2]])
	PL_data[[3]] = as.numeric(PL_data[[3]])
	PL_data[[7]] = as.numeric(PL_data[[7]])
	PL_data[[8]] = as.numeric(PL_data[[8]])
	
	
	#Init. SP data
	SP_data = data.frame(ORF=NA, IGNA=NA, CHNUM=NA, CHSTR=NA, CHEND=NA, SMF=NA)#Used for KVP data
	SP_data_2 = data.frame(ORF=NA, IGNA=NA, CHNUM=NA, CHSTR=NA, CHEND=NA, SMF=NA)#Used for tabulated data, then merged with SP_data
	
	#Data for extracting suppl. data as key-value pairs
	#Columns in SP_data which correspond to the key
	query_keys = c(3,4,5,6)
	array_keys = c(3,4,5,6,2)   
	#Key names for suppl. data
	names(query_keys) = c('QCHR', 'QSTR', 'QEND', 'QSMF')
	names(array_keys) = c('ACHR', 'ASTR', 'AEND', 'ASMF', 'IGNA')
	
	sp_data_row = 1;
	#Process any SP data as key value pairs
	for(i in 1:dim(PL_data)[1]){
		queryORF = as.character(PL_data$query[i]);
		arrayORF = as.character(PL_data$array[i]);
		kvp = PL_data$supp[i];
		
		rgx = gregexpr("(\\.|\\w)+", kvp)
		matched_kvp = regmatches(kvp, rgx)[[1]]
		
		#We have a query/array ORF and key value pair
		if(!is.na(queryORF) & !is.na(queryORF) & !is.na(kvp)){
			#Loop through all keys
			for(j in 1:length(matched_kvp)){
				#Get the current key
				curr_key = toupper(matched_kvp[j])
				#Get the value of the key
				curr_val = matched_kvp[j+1]
				#If the key used is apart of the standard format.. continue
				if(curr_key %in% names(query_keys)){
					#Get the column where the value should be placed in SP_data
					key_col = as.numeric(query_keys[curr_key])
					#Store it
					SP_data[sp_data_row, key_col] = curr_val;
					SP_data[sp_data_row, 1] = queryORF; #Store the ORF
				}
				if(curr_key %in% names(array_keys)){
					#Get the column where the value should be placed in SP_data
					key_col = as.numeric(array_keys[curr_key])
					#Store it
					SP_data[sp_data_row+1, key_col] = curr_val;
					SP_data[sp_data_row+1, 1] = arrayORF; #Store the ORF
				}
				
				#For every key, a value follows, increment j by 2 to skip this value
				j = j+2;
			}
			
			#Increment the row we are at in SP_data
			sp_data_row = sp_data_row + 2;
		}
		
		
	}
	
	#Do we have SP data as a separate header?
	SP_start_ind = grep('@[Ss][Pp]', read.data[[1]]);
	if(length(SP_start_ind) == 1){
		#If @SP is the last header line, the end is the end of the data (length of rows)
		i = grep('@[Ss][Pp]', header_lines);
		if(i == length(header_lines)){
			SP_end_ind = dim(read.data)[1]
		}else{
			SP_end_ind = header_lines_ind[i+1] -1
		}
		SP_data_tab = read.data[(SP_start_ind + 1): (SP_end_ind),];
		
		#Process TODO
		sp_line = as.character(as.matrix(read.data[SP_start_ind,]))
		cf_vals = grep('[Cc][Ff]:\\w+(,\\w+)*', sp_line);#Find tags with CF
		cf_vals = sp_line[cf_vals[1]]
		cf_vals = strsplit(cf_vals, ':')[[1]][2]#Get stuff on the rhs of colon
		
		rgx = gregexpr("\\w+", cf_vals)
		matched_cols = regmatches(cf_vals, rgx)[[1]]#column format for tabulated suppl. data
		
		matched_cols = toupper(matched_cols)
		names(SP_data_tab) = matched_cols
		
		SP_data_2[1:dim(SP_data_tab)[1],]=NA
 		for(i in 1:length(matched_cols)){
			col = matched_cols[i];
			SP_data_2[[col]] = as.vector(SP_data_tab[[col]])
		}
		
		
	}
	
	#Merge both suppl. data
	SP_data = rbind(SP_data, SP_data_2);
	
	#Remove duplicate supp. data
	SP_data = unique(SP_data[!duplicated(SP_data),])
	
	#Remove rows/cols which are all NA
	SP_data = SP_data[sapply(SP_data, function(x) !all(is.na(x)))]
	SP_data = SP_data[apply(SP_data, 1, function(x) !all(is.na(x))),]
	
	returndata = list(PL_data, SP_data, read.data.raw);
	return(returndata)
}


writeSGAFile <- function(savepath, input.data){
	plate.data = input.data[[1]]
	supp.data = input.data[[2]]
	original.read.data = input.data[[3]]
	
	#Round the data
	plate.data$normalizedcolonysize = round(as.numeric(plate.data$normalizedcolonysize), 3)
	plate.data$score = round(as.numeric(plate.data$score), 3)
	
	#Get header info
	header = t(names(plate.data));
	header[1,1] = paste('#' ,header[1,1], sep="")  
	
	#Set NAs in plate data to -
	plate.data[is.na(plate.data)] = '-'
	
	data.start = min(as.numeric(row.names(original.read.data)));
	data.end = max(as.numeric(row.names(original.read.data)));
	
	plate.data.start = min(as.numeric(row.names(plate.data)));
	plate.data.end = max(as.numeric(row.names(plate.data)));
	
	supp.data.start = min(as.numeric(row.names(supp.data)));
	supp.data.end = max(as.numeric(row.names(supp.data)));
	
	stamp = paste('#Last modified by SGATools 1.0 on', Sys.time(), sep=" ")
	#Write stamp
	write(stamp, savepath)
	
	#Write everything before plate data
	writeCustomColumnLines(original.read.data, savepath, 1, plate.data.start-1)
	
	#Write plate data
	write.table(header, savepath, sep="\t", quote=F, row.names=F, col.names=F, append=TRUE)
	write.table(plate.data, savepath, sep="\t", quote=F, row.names=F, col.names=F, append=TRUE);
	
	#If we have data after plate data, write it
	if(plate.data.end+1 <= data.end){
		writeCustomColumnLines(original.read.data, savepath, plate.data.end+1, data.end)
	}
}

writeCustomColumnLines <- function(data, savepath, start, end){
	for(i in start:end){
		line = as.character(data[i,])
		empty = grep('^\\s{0}$', line);
		nas = which(line == 'NA');
		
		#Remove NAs and empty columns
		remove.ind = union(empty, nas)
		line = line[-remove.ind]
		
		#write the line
		write.table(t(line), savepath, sep="\t", quote=F, row.names=F, col.names=F, append=TRUE)
	}
}