#Compare sgadata produced from mynormalization to that of costanzo

comparePracticalData <- function(sgadata, orfnames, platenum=1, costanzopath, savepath=NA, normcol=16){
	
	plots = as.list(rep(NA,length(platenum)*2))
	
	j = 1
	for(x in seq.int(from=1, to=length(platenum)*2, by=2))?{
	c = getComparedData(sgadata=sgadata, orfnames=orfnames, platenum=platenum[j], costanzopath=costanzopath, normcol=normcol)
	corr = signif(cor(c[[3]],c[[4]], use='pairwise.complete.obs'), digits=3)
	
	cor_plot <- ggplot(c, aes(dmf_costanzo, normalized_colsize), size=2, position = position_jitter(x = 2,y = 2) )  + theme_gray(base_size=9)+ geom_jitter(colour=alpha("black",0.15))+   geom_point( size=1 ) + geom_hex( bins=50) + opts(legend.position = "none") +scale_y_continuous('Low-throughput normalization') +scale_x_continuous('Costanzo double mutant fitness')  + annotate("text",x=250,y=600,label=paste("r=",corr, sep='')) 
	#+ opts(title=paste("r=",corr, sep=''))
	
	
	
	a1 = as.data.frame(1:length(c[[3]]))
	a1$colsize = c[[3]]
	a1$Type = 'Costanzo double mutant fitness'
	names(a1) = letters[1:3]
	
	a2 = as.data.frame(1:length(c[[4]]))
	a2$colsize = c[[4]]
	a2$Type = 'Low-throughput normalization'
	names(a2) = letters[1:3]
	
	a3 = rbind(a1,a2)
	
	plot <- ggplot(data=a3, aes(x=a, y=b, group=c, color=c))+ theme_gray(base_size=9) + geom_point(size=1.2)+scale_y_continuous('Colony number') +scale_x_continuous('Colony size')+ scale_colour_manual(values=c("#4D88E8", "#79BA11"), name="Legend")+ opts(legend.position = "none")
	
	plots[[x]] = plot
	plots[[x+1]] = cor_plot
	
	j=j+1
	}#END PLATENUM FORLOOP
	
	#PLOT MULTIPLOT
	if(!is.na(savepath)){
		pdf(savepath, width=length(platenum), height=ceiling(length(platenum)*3.5))
		multiplot(plotlist=plots, cols=2)
		dev.off()
	}else{
		multiplot(plotlist=plots, cols=2)
	}
	
	#return(costanzo_sub)
}

#Compares correlation for steps
compareCorrelation <- function(sgadata, orfnames, platenum, costanzopath, stepcompare=c(9,16)){
	corrRaw = c()
	corrNorm = c()
	
	for(i in 1:length(platenum)){
		#Get correlation of raw data with costanzo data for this plate number
		c = getComparedData(sgadata=sgadata, orfnames=orfnames, platenum=platenum[i], normcol=stepcompare[1], costanzopath=costanzopath)
		r1 = signif(cor(c[[3]],c[[4]], use='pairwise.complete.obs'), digits=3)
		#Get correlation of normalized data with costanzo data for this plate number
		c = getComparedData(sgadata=sgadata, orfnames=orfnames, platenum=platenum[i], normcol=stepcompare[2], costanzopath=costanzopath)
		r2 = signif(cor(c[[3]],c[[4]], use='pairwise.complete.obs'), digits=3)
		
		#Save for this plate
		corrRaw[i] = r1;
		corrNorm[i] = r2;
		print(i)
		
	}
	
	dftmp = as.data.frame(corrRaw)
	dftmp[[2]] = corrNorm
	dftmp = dftmp[order(dftmp[[1]]),]
	corrRaw = dftmp[[1]]
	corrNorm = dftmp[[2]]
	
	#Plot for all plates
	df1 = as.data.frame(1:length(corrRaw))
	df1[[2]] = corrRaw
	df1[[3]] = 'corr-raw'
	names(df1) = NA
	
	df2 = as.data.frame(1:length(corrNorm))
	df2[[2]] = corrNorm
	df2[[3]] = 'corr-normalized'
	names(df2) = NA
	
	df = rbind(df1,df2)
	names(df) = c('index', 'corr', 'type');
	
	ggplot(data=df, aes(x=index, y=corr, group=type, shape=type, color=type)) + geom_line()
	return(df)
}

#Gets side by side comparison of costanzo vs. normalized data deleting any data points with NA in either
getComparedData <- function(sgadata, orfnames, platenum=1, normcol=16, costanzopath){
	platenum = c(platenum)
	
	j = 1
	ind = which(sgadata$plateid == platenum[j])
	#Columns - query, array, colsize of last normalization
	data = sgadata[ind,c(1,2,normcol)]

	#Group by array and average colony size
	data_agg = aggregate(data, by=list(data[[2]]), FUN=mean)[,c(2,3,4)]
	
	#Change numeric to ORFs
	data_agg[[1]] = orfnames[data_agg[[1]]]
	data_agg[[2]] = orfnames[data_agg[[2]]]
	
	#Query ORF of the plate we're looking at 
	plate_query = toString(data_agg[1,1])
	
	#Read costanzo raw data if not already read
	if(!exists('costanzo'))
		costanzo = read.csv(costanzopath, sep='\t', header=FALSE, fill=TRUE)
	#Find our data
	ind = which(costanzo[[1]] == plate_query & costanzo[[3]] %in% data_agg[[2]])
	
	#Extract our data and columns QUERY ORF, ARRAY ORF, DOUBLE MUTANT FITNESS
	costanzo_sub = costanzo[ind,c(1,3,12)]
	costanzo_sub$V4 = NA
	
	for(i in 1:dim(costanzo_sub)[1]){
		arr = toString(costanzo_sub[i,2])#array
		normVal = data_agg[which(data_agg[[2]] == arr), 3]
		costanzo_sub$V4[i] = normVal
	}
	names(costanzo_sub) = c('query', 'array','dmf_costanzo','normalized_colsize')
	# Default median colony size per plate = 510
	costanzo_sub$dmf_costanzo = costanzo_sub$dmf_costanzo * 510 
	
	#Remove anything that might be NA as it affects plotting/analysis
	notna = which(!is.na(costanzo_sub[[3]]) & !is.na(costanzo_sub[[4]]))
	costanzo_sub = costanzo_sub[notna,]
	
	c = costanzo_sub[order(costanzo_sub[[3]]),];
	corr = signif(cor(c[[3]],c[[4]], use='pairwise.complete.obs'), digits=3)
	
	return(c);
	
}
