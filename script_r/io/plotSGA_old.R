######################################################################
## Last modified on 31/05/12 by Omar Wagih (omar.wagih@utoronto.ca) ##
######################################################################

# Plots a plate after steps of normalization as a heatmap - data after each stop of normalization
# is stored in sgadata. Steps to display is specified by the field containing the normalized data
# in sgadata
# Input
#	sgadata - dataframe containing normalized data
# 	fields - fields of sgadata we want to display
# 	plateid_map - map of plateid -> indicies of rows
#	field_titles - titles for the heatmaps - if not specified, name of the field is used
#	plate_num - which plate to display (defaults to first plate)
#	num_cols - number of columns to distrubte the heatmaps across (defaults to 1)

plotSGA <- function(sgadata, fields, plateid_map, field_titles=fields, plate_num=1, plotcols=1) {
	maxColSize = 0
	minColSize = 0
	for(i in 1:length(fields)){
		field = fields[i]
		ind = plateid_map[[plate_num]]
		dat = sgadata[[field]][ind]
		if(max(dat, na.rm=TRUE)>maxColSize)
			maxColSize=max(dat)
		if(min(dat, na.rm=TRUE)<minColSize)
			minColSize=min(dat)
	}
	
	plots = as.list(rep(NA,length(fields)))
	for(i in 1:length(fields)){
		field = fields[i]
		field_title = field_titles[i]
		
		ind = plateid_map[[plate_num]]
		dat = sgadata[[field]]
				
		#Construct plate map used to make plate matrix of colonies
  		r = sgadata$row[ind]
  		c = sgadata$col[ind]
  		plate_ind = (c - 1)*num_rows + r
  	
  		#Default size to NA
  		plate_map = matrix(NA, num_rows, num_cols)
  		plate_map[plate_ind] = dat[ind]
		df = as.table(plate_map)
		
		colnames(df)=c(1:48)
  		rownames(df)=c(1:32)
  		
  		#Melt matrix
  		dfmelt = melt(df)
  		
  		p <- ggplot(dfmelt, aes(x=X2, y=X1, fill=value)) +
  		geom_tile() + 
  		scale_fill_gradient(low='black', high='yellow', limits=c(minColSize,maxColSize)) +
  		labs(x = "Column", y = "Row") +
  		scale_y_continuous() + scale_y_reverse() + 
  		opts(axis.ticks = theme_blank(), title=field_title) +theme_bw(base_size=10)
  		
  		plots[[i]] = p
	}
	pdf('pdf/plot9.pdf', width=5, height=10)
	x <- multiplot(plotlist=plots, cols=plotcols)
	dev.off()
}

# Plots a plate after steps of normalization as a heatmap - data after each stop of normalization
# is stored in sgadata. Steps to display is specified by the field containing the normalized data
# in sgadata. Different from previous in that it produces facets 
# Input
#	sgadata - dataframe containing normalized data
# 	fields - fields of sgadata we want to display
# 	plateid_map - map of plateid -> indicies of rows
#	field_titles - titles for the heatmaps - if not specified, name of the field is used
#	plate_num - which plate to display (defaults to first plate)

plotSGA_facet <- function(sgadata, fields, plateid_map, field_titles=fields, plate_num=1){
	for(i in 1:length(fields)){
		field = fields[i]
		ind = plateid_map[[plate_num]]
		dat = sgadata[[field]][ind]
		dat[which(dat<0)] = 0
		dat[which(dat>1000)] = 1000
		sgadata[[field]][ind] = dat
	}
	
	fulldat = as.data.frame(matrix(NA, 0,4))
	colnames(fulldat) = c('X1','X2','value','field_name')
	for(i in 1:length(fields)){
		field = fields[i]
		field_title = field_titles[i]
		
		ind = plateid_map[[plate_num]]
		dat = sgadata[[field]]
		
		#Construct plate map used to make plate matrix of colonies
  		r = sgadata$row[ind]
  		c = sgadata$col[ind]
  		plate_ind = (c - 1)*num_rows + r
  	
  		#Default size to NA
  		plate_map = matrix(NA, num_rows, num_cols)
  		plate_map[plate_ind] = dat[ind]
		
		df = as.table(plate_map)
		colnames(df)=c(1:48)
  		rownames(df)=c(1:32)
  		
  		#Melt matrix
  		dfmelt = melt(df)
  		dfmelt$title = field_title
		
		fulldat = rbind(fulldat, dfmelt)
		
	}
	#Sorting for facet
	fulldat$title <- factor(fulldat$title, levels = field_titles)
	
	ggplot(fulldat, aes(x=X2, y=X1, fill=value)) +
  	geom_tile() + 
  	scale_fill_gradient(low='black', high='yellow', limits=c(0,1000)) +
  	labs(x = "Column", y = "Row") +
  	scale_y_continuous() + scale_y_reverse() +
  	opts(title=paste('Before and after normalization - Plate:',plate_num), panel.background=theme_blank()) +
  	theme_bw(base_size=10) +
  	facet_grid(title ~ .)
}

# Function used to plot multiple plots in one
# Obtained from http://wiki.stdout.org/rcookbook/Graphs/Multiple%20graphs%20on%20one%20page%20(ggplot2)/
multiplot <- function(..., plotlist=NULL, cols) {
    require(grid)

    # Make a list from the ... arguments and plotlist
    plots <- c(list(...), plotlist)

    numPlots = length(plots)

    # Make the panel
    plotCols = cols                          # Number of columns of plots
    plotRows = ceiling(numPlots/plotCols) # Number of rows needed, calculated from # of cols

    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(plotRows, plotCols)))
    vplayout <- function(x, y)
        viewport(layout.pos.row = x, layout.pos.col = y)

    # Make each plot, in the correct location
    for (i in 1:numPlots) {
        curRow = ceiling(i/plotCols)
        curCol = (i-1) %% plotCols + 1
        print(plots[[i]], vp = vplayout(curRow, curCol ))
    }

}