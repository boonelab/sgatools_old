#Global variables, later modified
NUM_ROWS = 32; 
NUM_COLS = 48;

runNormalization <- function(
		INPUT_DATA, 
		LINKAGE_CUTOFF=200, 
		CONTROL_BORDER=2, 
		NUM_REPLICATES=4, 
		DEFAULT_MEDIAN_COLONY_SIZE=510, 
		MAX_COLONY_SIZE=1.5 * DEFAULT_MEDIAN_COLONY_SIZE
	){
    ###################################################
	#Loading and processing SGA data
    ###################################################

    sgadata = INPUT_DATA[[1]]
    suppdata = INPUT_DATA[[2]]
    
	#Set row/col to be numeric
	sgadata$row = as.numeric(as.character(sgadata$row))
	sgadata$col = as.numeric(as.character(sgadata$col))
	
	#Set global vars.:number of rows/cols to be the max value in row/col
	NUM_ROWS <<- max(as.numeric(sgadata$row))
	NUM_COLS <<- max(as.numeric(sgadata$col))
	
    #Asign unique plate ids starting from 1
    #Plate -> ind mapping
    #Create a mapping from unique plate ids in the file to row indices of the data
    uniq_plateid = unique(sgadata$plateid)
    names(uniq_plateid) = 1:length(uniq_plateid)
    plateid_map = uniq_plateid
    
    #Duplicate the plate ids, keep the old plate ids stored to be returned to the user
    #Analysis is done using the new plate ids
    sgadata$plateid_old = sgadata$plateid
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
    #Ensure new plateid is numeric
    sgadata$plateid = as.numeric(sgadata$plateid)
    
	#Data preprocessing that should occur after plate ids are resetf
	#If the 5/6th column has one or more NA, we consider Query/Array ORFs are NOT included and will simulate them
	if(length( which(is.na(sgadata$query)) ) > 0 | length( which(is.na(sgadata$array))) | length( which(sgadata$query == '-') ) > 0 | length( which(sgadata$array == '-')) > 0){
		
		rdbl = ceiling(sgadata$row/sqrt(NUM_REPLICATES)) 
    	cdbl = ceiling(sgadata$col/sqrt(NUM_REPLICATES))
    	
    	#Set Array ORF
    	sgadata$array = ((cdbl - 1)* (NUM_ROWS/2)) + rdbl
    	#Set Query ORF to plate id to id
    	if(length( which(is.na(sgadata$query)) ) > 0 | length( which(sgadata$array == '-')) > 0){
			sgadata$query = sgadata$plateid
		}
	}
	#Convert query/array ORF data to completely numeric (speeds up the input process up)
    #Mimics old perl script/reduces dependencies on other script types
    #sgadata = read.table(PL_DATA, sep='\t', header=F)
	orfnames = c(as.character(unique(sgadata$query)), as.character(unique(sgadata$array)))
	sgadata$query = match(sgadata$query, orfnames)
	sgadata$array = match(sgadata$array, orfnames)
	
	###################################################
    #Remove questionable arrays
    ###################################################
    
    #First find rows in SUPP. data with ORFs that exist in the plate data
    ind = which(suppdata$ORF %in% orfnames)
    #Select these rows
    suppdata = suppdata[ind,];
   
    ignore_ind = c()
    #TODO when SP_data available
	if('IGNA' %in% names(suppdata)){
		#Find IGNA rows marked with a 1 (to be ignored)
		ind = which(suppdata$IGNA == 1)
		
		#Find ORF ids for ORF names in supp data
		ind2 = match(suppdata$ORF[ind], orfnames)
		
		#Find rows which with arrays that match this numeric id
		ind3 = which(sgadata$array %in% ind2)	
			
		ignore_ind = c(ignore_ind,ind3)
	}
	
    ###################################################
    #Apply linkage correction
    ###################################################
	c = c('CHNUM', 'CHSTR', 'CHEND')
	#If all 3 columns with chromsome position data are in supp data
	if(length(which(c %in% names(suppdata))) == 3){
		#Get the sub-data frame
		CH_data = suppdata[c('ORF','CHNUM','CHSTR', 'CHEND')]
		
		#Remove any rows with NA
		CH_data = na.omit(CH_data);
		
		linked_ind = get_linked_ind_window(sgadata,orfnames,CH_data, window=LINKAGE_CUTOFF);
    	ignore_ind = unique(c(ignore_ind, linked_ind))
	}

    ###################################################
    #Create optmization mappings
    ###################################################
    #Query -> ind mapping
    #Create a mapping from unique queries to row indices of the data
    uniq_query = unique(sgadata$query)
    names(uniq_query) = uniq_query
    query_map = uniq_query

    for(i in 1:length(uniq_query)){
            q = uniq_query[i];
        ind = which(sgadata$query == q)
        query_map[q] = list(ind)
    }

    #Array -> ind mapping
    #Create a mapping from unique arrays to row indices of the data
    uniq_array = unique(sgadata$array)
    names(uniq_array) = uniq_array
    array_map = uniq_array

    for(i in 1:length(uniq_array)){
            a = uniq_array[i]
        ind = which(sgadata$array == a)
        array_map[a] = list(ind)
    }

    ###################################################
    #Map same replicates to unique plate indicies
    ###################################################

    # Map colony coordinates back to 384 format if we are dealing with quads
    if(NUM_REPLICATES == 4){
        row384 = ceiling(sgadata$row/2)
        col384 = ceiling(sgadata$col/2)
    }else{#We are dealing with one rep
        row384 = sgadata$row
        col384 = sgadata$col
    }
    ###################################################
    #Create unique spot ids for replicates
    ###################################################    
    ind384 = ((col384 - 1)* (NUM_ROWS/2)) + row384 # = sub2ind in matlab

    #Generate spot ids (unique number is given to every one/four replicate colonies)
    #sgadata$replicateid = ind384;
    sgadata$spots = sgadata$plateid*10000 + ind384;

    ###################################################
    # (1) Plate normalization
    ###################################################    
    sgadata$colonysize_platenorm = 
            plate_normalization(sgadata, 'colonysize', ignore_ind, DEFAULT_MEDIAN_COLONY_SIZE, plateid_map);

    ###################################################
    #Remove excessively large colonies replicates
    ################################################### 
    #Find indicies of large colonies
    large_ind = which(sgadata$colonysize_platenorm >= MAX_COLONY_SIZE)

    #Gets spots of large colonies, and returns the count of each spot
    big_spots = table(sgadata$spots[large_ind])

    #Get colonies such that their spot contains at least 3 big colonies
    big_spots = big_spots[big_spots >= 3]
    spots_to_remove = as.numeric(names(big_spots)) 

    #Get indices colonies in spots to remove
    ind = which(sgadata$spots %in% spots_to_remove)

    #Remove
    sgadata$colonysize_platenorm[ind] = NA

    ###################################################
    # (2) Spatial Normalization
    ###################################################  
    sgadata$colonysize_spatialnorm = 
            spatial_normalization(sgadata, 'colonysize_platenorm', ignore_ind, plateid_map)

    ###################################################
    # (3) Row/column correction
    ###################################################
    sgadata$colonysize_rowcol = 
            rowcol_normalization(sgadata, 'colonysize_spatialnorm', ignore_ind, plateid_map) 

    ###################################################
    # (4) Plate normalization 2 
    ###################################################	
    sgadata$colonysize_platenorm_2 = 
            plate_normalization(sgadata, 'colonysize_rowcol', ignore_ind, DEFAULT_MEDIAN_COLONY_SIZE, plateid_map) 

    ###################################################
    # (5) Leave-one-out analysis 
    ###################################################	
    sgadata$colonysize_jackknife = apply_jackknife_filter(sgadata, 'colonysize_platenorm_2', query_map, array_map, plateid_map, orfnames)

    ###################################################
    # Additional filters 
    ###################################################	

    field = 'colonysize_jackknife'
    #Set colony sizes <=0 to NA
    sgadata[[field]][sgadata[[field]] < 1] = NA

    #Set values greater than 1000 to 1000
    sgadata[[field]][sgadata[[field]] > 1000] = 1000

    #Remove border containing control control strains if necessary
    row_up = CONTROL_BORDER
    row_down = NUM_ROWS - CONTROL_BORDER
    col_left = CONTROL_BORDER
    col_right = NUM_COLS - CONTROL_BORDER

    ind = which(sgadata$row <= row_up | sgadata$row > row_down | sgadata$col <= col_left | sgadata$col > col_right)
    sgadata[[field]][ind] = NA

	#Set normalized data
	sgadata$normalizedcolonysize = sgadata[[field]]
	
	keeps <- c('row', 'col','colonysize','plateid_old', 'query', 'array', 'normalizedcolonysize', 'score', 'supp')
	sgadata_complete = sgadata[keeps];
	
	#Before return
	#Put ORFs back instead of numericals
	sgadata_complete$query = orfnames[sgadata_complete$query];
	sgadata_complete$array = orfnames[sgadata_complete$array];
	#Replace NA with '-'
	sgadata_complete[is.na(sgadata_complete)] = '-'
	
    toReturn = list(sgadata_complete)
    toReturn[[2]] = sgadata;
    toReturn[[3]] = orfnames
    toReturn[[4]] = plateid_map
    toReturn[[5]] = array_map
    return(toReturn)
}