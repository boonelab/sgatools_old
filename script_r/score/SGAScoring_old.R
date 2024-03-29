#Main method which will run normalizations/filters and return the normalized data
num_rows=32
num_cols=48

run <- function(inputfile, removearraylist=NA, chromposfile=NA, linkagecutoff=200,
	control_border=2, numReplicates=4, num_rows=32, num_cols=48, default_median_colsize = 510, 
	maxColSizeFactor = 1.5, maxColSize = maxColSizeFactor*default_median_colsize){

    ######################################################################
    ###################### DATA PRE-PROCESSING ###########################
    ######################################################################
    #Read in file
    tmpsgadata = read.table(inputfile, header=TRUE, sep="\t");
    if(length(names(tmpsgadata)) <= 6){
    	newsgadata = as.data.frame(matrix(NA, dim(tmpsgadata)[1],9))
    	#We have our shortform format which must be transformed into 9 column for the script
    	#Query / array part - tricky - if we have query column its easy
    	if("query" %in% names(tmpsgadata)){
    		newsgadata[[1]] = tmpsgadata$query
    		newsgadata[[2]] = tmpsgadata$array
    	}else{
    		#No query column, must get num replicates and generate query array
    		#We assume all one query, even if multiple plates in one file 
    		newsgadata[[1]] = rep(1, dim(tmpsgadata)[1]);
    		
    		if(numReplicates==4){
    			rnrm = 1:nrow 
    			rdbl = ceiling(rnrm/2) 
    			cnrm = 1:ncol 
    			cdbl = ceiling(cnrm/2)
    			quad_matrix = matrix(NA, nrow, ncol)
				pairs = expand.grid(unique(rdbl), unique(cdbl))
				for(i in 1:dim(pairs)[1]){
					x = as.integer(pairs[i,][1])
					y = as.integer(pairs[i,][2])
					x = rnrm[which(rdbl == x)]
					y = cnrm[which(cdbl == y)]
					#Assign i to that block
					quad_matrix[x,y] = rep(i,4);
				}
				
    		}
    		
    		
    	}
    	
    	#Array plate id, set number, plate id, batch number all set to 1s
    	newsgadata[[3]] = rep(1, dim(tmpsgadata)[1]) 
    	newsgadata[[4]] = rep(1, dim(tmpsgadata)[1]) 
    	
    	if("platenum" %in% names(tmpsgadata)){
    		newsgadata[[5]] = tmpsgadata$platenum
    	}else{
    		newsgadata[[5]] = rep(1, dim(tmpsgadata)[1])
    	}
    	
    	newsgadata[[6]] = rep(1, dim(tmpsgadata)[1])
    	newsgadata[[7]] = tmpsgadata$row
    	newsgadata[[8]] = tmpsgadata$column
    	newsgadata[[9]] = tmpsgadata$colonysize
    	
    }

    ######### LOAD SGA DATA #########
    #printTitle('Loading plate data')
	
    #writeLines('-Converting ORF names to numeric (Perl)')
    #First execute perl script to convert data to completely numeric (speeds up the input process up)
    perlCmd = paste('perl', 'io/process_rawsga_dmdata.pl' ,inputfile)
    system(perlCmd, intern=TRUE, ignore.stdout=TRUE, ignore.stderr=TRUE)

    #writeLines('-Reading in converted data')
    #Load data generated by perl script
    sgadata_numeric_path = paste(inputfile, '_numeric', sep="")
    sgadata = read.table(sgadata_numeric_path, header=F)
    names(sgadata) = c('query', 'array', 'arrayplateid', 'set', 'plateid', 'batch', 'row', 'col', 'colonysize')
    sgadata = as.data.frame(sgadata)
    #writeLines(paste('\t-Lines read in:',dim(sgadata)[1]))
	
    #writeLines('-Loading ORF to numeric map')
    #Load map generated by perl script
    sgadata_map_path = paste(inputfile, '_orfidmap', sep="")
    orfidmap = read.table(sgadata_map_path, header=F)
    names(orfidmap) = c('orf', 'id')
    orfidmap = as.data.frame(orfidmap)
    orfidmap = orfidmap[order(orfidmap$id),] #sort by id
    orfnames = orfidmap$orf
	
	#Remove files generated by perl script
	unlink(c(sgadata_numeric_path, sgadata_map_path));
    #split by _????

    ######### REMOVE QUESTIONABLE ARRAYS #########
    #printTitle('Setting data points to ignore')
    ignore_ind = c()
    #Load column one (only column) from the file
    if(!is.na(removearraylist)){
    	
            #writeLines(paste('\n-Reading ignore array file:', removearraylist))
            ignoredat = read.table(removearraylist)$V1
            #writeLines(paste('\t-Number of arrays read:', length(ignoredat)))
            ignore = intersect(ignoredat, orfnames)
            ignore = which(orfnames %in% ignoredat)
            ignore_ind = which(sgadata$array %in% ignore)
            #writeLines(paste('\t-Number of arrays in input data:', length(ignoredat)))
    		writeLines(paste('#found array file:',removearraylist, '# has', length(ignore_ind), 'indcies in data'));
    }else{
    	writeLines('#no array file');
            #writeLines('-No ignore array file found, skipping step')
	}
    #Get colonies corresponding to linkage???????????????????
    #IMPLEMENT LINKAGE STANDARD 200KB
    #writeLines('\nTODO: Finding linked genes:')
    if(!is.na(chromposfile)){
    	linked_ind = get_linked_ind_window(sgadata,orfnames,chromposfile=chromposfile, window=linkagecutoff);
    	ignore_ind = unique(c(ignore_ind, linked_ind))
    	writeLines(paste('#found chrompos file', chromposfile, 'linked indicies=',toString(linked_ind)));
    }else{
    	writeLines('#no chrompos file');
    }
	
    writeLines(paste('#TOTAL IGNORED IND=', length(ignore_ind)));
    #printTitle('Running speed optimization')
    ######### SPEED OPTIMIZATION 1 #########
    #writeLines('-Creating a map from plateid to index')
    #Asign unique plate ids starting from 1
    #Create a mapping from unique plate ids in the file to row indices of the data
    uniq_plateid = unique(sgadata$plateid)
    names(uniq_plateid) = 1:length(uniq_plateid)
    plateid_map = uniq_plateid

    for(i in 1:length(uniq_plateid)){
            #unique id of old
            old_id = uniq_plateid[i];
            #indices of this plate id in data
            ind = which(sgadata$plateid == old_id) 
            #the new plate id
            new_id = names(old_id) 
            sgadata$plateid = replace(sgadata$plateid, ind, new_id)

            #unique plate to indices map
            plateid_map[new_id] = list(ind)
    }
    # Ensure new plate ids are numeric
    sgadata$plateid = as.numeric(sgadata$plateid)

    ######### SPEED OPTIMIZATION 2 #########

    #writeLines('-Creating a map from query to index')
    #Create a mapping from unique queries to row indices of the data
    uniq_query = unique(sgadata$query)
    names(uniq_query) = uniq_query
    query_map = uniq_query

    for(i in 1:length(uniq_query)){
            q = uniq_query[i];
            ind = which(sgadata$query == q)
            query_map[q] = list(ind)
    }

    ######### SPEED OPTIMIZATION 3 #########

    #writeLines('-Creating a map from array to index')
    #Create a mapping from unique arrays to row indices of the data
    uniq_array = unique(sgadata$array)
    names(uniq_array) = uniq_array
    array_map = uniq_array

    for(i in 1:length(uniq_array)){
            a = uniq_array[i]
            ind = which(sgadata$array == a)
            array_map[a] = list(ind)
    }

    #writeLines('-Generating unique ids for groups of replicates')

    #writeLines('\t-Assigning plate-unique ids for replicates')
    # Map colony coordinates back to 384 format
    if(numReplicates == 4){
    	row384 = ceiling(sgadata$row/2)
    	col384 = ceiling(sgadata$col/2)
    }else{
    	row384 = sgadata$row
    	col384 = sgadata$col
    }
    
    ind384 = ((col384 - 1)* (num_rows/2)) + row384 # = sub2ind in matlab

    #writeLines('\t-Assigning globally-unique ids for replicates')
    #Generate spot ids (unique number is given to every four replicate colonies)
    sgadata$replicateid = ind384;
    sgadata$spots = sgadata$plateid*10000 + sgadata$replicateid;

    ######################################################################
    ########################### NORMALIZATIONS ###########################
    ######################################################################

    ######### PLATE NORMALIZATION #########
    #printTitle('Applying plate normalization')
    sgadata$colonysize_platenorm = plate_normalization(sgadata, 'colonysize', ignore_ind, default_median_colsize, plateid_map) 
    #writeLines('')

    ######### REMOVE LARGE COLONIES #########
    #printTitle('Removing large colonies')
    #writeLines(paste('-Removing colonies larger than',maxColSizeFactor,'x', default_median_colsize))
    #Remove large colonies
    large = which(sgadata$colonysize_platenorm >= maxColSize)

    ignoreBorder = which(sgadata$row > 2 & sgadata$row < 31 & sgadata$col > 2 & sgadata$col < 47)

    #if statement goes here
    ind = intersect(large, ignoreBorder)

    #Gets spots of large colonies, and returns the count of each spot
    big_spots = table(sgadata$spots[ind])

    #Get colonies such that their spot contains at least 3 big colonies
    big_spots = big_spots[big_spots >= 3]
    spots_to_remove = as.numeric(names(big_spots)) 

    #Get indices colonies in spots to remove
    ind = which(sgadata$spots %in% spots_to_remove)

    #Remove
    #sgadata$colonysize_platenorm[ind] = NA

    ######### SPATIAL NORMALIZATION #########
    #printTitle('Applying spatial normalization')
    sgadata$colonysize_spatialnorm = spatial_normalization(sgadata, 'colonysize_platenorm', ignore_ind, plateid_map) 
    #writeLines('')
    ######### ROW/COLUMN CORRECTION #########
    #printTitle('Applying row/column correction')
    sgadata$colonysize_rowcol = rowcol_normalization(sgadata, 'colonysize_spatialnorm', ignore_ind, plateid_map) 
    #writeLines('')

    ######### ANOTHER PLATE NORMALIZATION? #########
    #printTitle('Applying plate normalization (round 2)')
	sgadata$colonysize_platenorm_2 = plate_normalization(sgadata, 'colonysize_rowcol', ignore_ind, default_median_colsize, plateid_map) 
    #writeLines('')
    ######################################################################
    ########################### FILTERS ##################################
    ######################################################################

    ######### LEAVE-ONE-OUT ANALYSIS #########
    source('norm/jackknife.R')
    sgadata$colonysize_jackknife = apply_jackknife_filter(sgadata, 'colonysize_platenorm_2', query_map, array_map, plateid_map, orfnames)

    field = 'colonysize_jackknife'
    #Set colony sizes <=0 to NA
    sgadata[[field]][sgadata[[field]] < 1] = NA

    #Set values greater than 1000 to 1000
    sgadata[[field]][sgadata[[field]] > 1000] = 1000

    #Remove border containing control his3 strains if necessary
    row_up = control_border
    row_down = num_rows - control_border
    col_left = control_border
    col_right = num_cols - control_border

    ind = which(sgadata$row <= row_up | sgadata$row > row_down | sgadata$col <= col_left | sgadata$col > col_right)
    sgadata[[field]][ind] = NA
	
	#Return a list 
	toReturn = list(sgadata)
	toReturn[[2]] = orfnames
	toReturn[[3]] = plateid_map
	toReturn[[4]] = array_map
	return(toReturn)
}