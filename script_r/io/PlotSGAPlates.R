plotSGA_all_plates <- function(sgadata, fields, field_titles=fields, type="n"){
	
	num_rows = NUM_ROWS
	num_cols = NUM_COLS
	
	fulldat = as.data.frame(matrix(NA, 0,4))
	colnames(fulldat) = c('X1','X2','value','field_name')
	
	uniq_plateids = sort(unique(sgadata[['plateid']]))
	
	for(i in 1:length(uniq_plateids)){
		
		curr_plateid = uniq_plateids[i]
		ind = which(sgadata$plateid == curr_plateid)
		for(j in 1:length(fields)){
			curr_field = fields[j];
			curr_field_title = field_titles[j]
			#Construct plate map used to make plate matrix of colonies
  			r = sgadata$row[ind]
  			c = sgadata$col[ind]
  			dat = as.numeric(sgadata[[curr_field]][ind])
  			  			
  			plate_ind = (c - 1)*num_rows + r
  			#Default size to NA
  			plate_map = matrix(NA, num_rows, num_cols)
  			plate_map[plate_ind] = dat
  			
  			df = as.table(plate_map)
			colnames(df)=c(1:num_cols)
  			rownames(df)=c(1:num_rows)
  			
  			#Melt matrix
  			dfmelt = melt(df)
  			dfmelt$title = curr_field_title
		
			fulldat = rbind(fulldat, dfmelt)
		}
		
		
		#Sorting for facet
		fulldat$title <- factor(fulldat$title, levels = field_titles)
		
		p =ggplot(fulldat, aes(x=X2, y=X1, fill=value)) + geom_tile();
  		
  		if(type == "n"){
  			p = p + scale_fill_gradient(name="Colony size", low='black', high='yellow', limits=c(0,1000))
			plot.title = "Before and after normalization"
  		}
  		if(type == "s"){
  			p = p + scale_fill_gradient2(name="Scores", low='red', mid="black", high='green', limits=c(-1,1))
  			plot.title = "Score"
  		}
  		
  		p = p + labs(x = "Column", y = "Row") +
  		scale_y_continuous() + scale_y_reverse() +
  		opts(title=paste(plot.title, ' - Plate:',curr_plateid), panel.background=theme_blank()) +
  		theme_bw(base_size=8) +
  		facet_grid(title ~ .);

  		
  		print(p)
  		
	}
	
}