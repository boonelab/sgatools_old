#Generates simulated data
generateSimulatedData <- function(path="simulated_data.txt", path_noise="simulated_noisy_data.txt"){
	ncol = 48
	nrow = 32
	plate_mean = 3
	sigma = 0.8
	mat = matrix(rnorm(ncol*nrow, mean = plate_mean, sd = sigma), nrow, ncol);
	
	#Matrix of noise + interactions ONLY (interactions added below) - used in MSE calc.
	mat_noise_int = mat;
	
	##################################################
	#              Add row/col effects               #
	################################################## 
	
	#Row effect
	row_means = floor(sort(abs(rnorm(nrow/2,sd=5)), decreasing=TRUE))+1
	row_means = c(row_means, floor(sort(abs(rnorm(nrow/2,sd=5))))+1)
	row_sigma = 0.1
	row_effect = matrix(rep(1,nrow*ncol), ncol=ncol)*rnorm(nrow, mean=row_means, sd=row_sigma)
	mat <- mat + row_effect
	
	#Column effect
	col_means = floor(sort(abs(rnorm(ncol/2,sd=5)), decreasing=TRUE))+1
	col_means = c(col_means, floor(sort(abs(rnorm(ncol/2,sd=5))))+1)
	col_sigma = 0.1
	col_effect = t(matrix(rep(1,nrow*ncol), ncol=ncol))*rnorm(ncol, mean=col_means, sd=col_sigma)
	mat <- mat + t(col_effect)
	
	#Make quads similar 
	rnrm = 1:nrow
	rdbl = ceiling(rnrm/2)
	cnrm = 1:ncol
	cdbl = ceiling(cnrm/2)

	#Generate array as quads
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
	
	##################################################
	#                  Smooth quads                  #
	################################################## 
	#Max 384
	quads_to_smooth = 100

	#Generate random pairs representing quads and randomize the rows
	rand_pairs = expand.grid(unique(rdbl), unique(cdbl))
	rand_pairs = rand_pairs[sample(1:dim(rand_pairs)[1]),]
	rand_pairs2 = rand_pairs

	for(i in 1:quads_to_smooth){
		#Our random pair
		x = as.integer(rand_pairs[1,][1])
		y = as.integer(rand_pairs[1,][2])
	
		x = rnrm[which(rdbl == x)]
		y = cnrm[which(cdbl == y)]
	
		#x and y are now our actual indicies of the quad
		mat[x,y] = rnorm(4, mean=mean(mat[x,y]), sd=0.3)
	
		rand_pairs = rand_pairs[2:dim(rand_pairs)[1],]
	}
	
	##################################################
	#                    Add GIs                     #
	################################################## 
	num_gis = 25
	simulated_interaction_quads = rep(NA,num_gis)
	
	for(i in 1:num_gis){
		#Our random pair
		x = as.integer(rand_pairs[1,][1])
		y = as.integer(rand_pairs[1,][2])
		
		while(x == 1 | y == 1 | x == 16 | y == 24){
			x = as.integer(rand_pairs[1,][1])
			y = as.integer(rand_pairs[1,][2])
		
			rand_pairs = rand_pairs[2:dim(rand_pairs)[1],]
		}
		x = rnrm[which(rdbl == x)]
		y = cnrm[which(cdbl == y)]
		
		k = (as.vector(quad_matrix[x,y])[1])
		simulated_interaction_quads[i] = k
		
		#x and y are now our actual indicies of the quad
		r = matrix(runif(4, 0.0, 0.5), 2,2);
		mat[x,y] = mat[x,y] * r
		mat_noise_int[x,y] = mat_noise_int[x,y] * r
		rand_pairs = rand_pairs[2:dim(rand_pairs)[1],]
	}
	
	##################################################
	#           Add outlier colonies jackknife       #
	################################################## 
	num_outliers = 20
	rand_pairs = expand.grid(unique(rnrm), unique(cnrm))
	rand_pairs = rand_pairs[sample(1:dim(rand_pairs)[1]),]

	for(i in 1:num_outliers){
		#Our random pair
		x = as.integer(rand_pairs[1,][1])
		y = as.integer(rand_pairs[1,][2])
	
		mat[x,y] = mat[x,y]*2
		rand_pairs = rand_pairs[2:dim(rand_pairs)[1],]
	}
	
	
	##################################################
	#               Add spatial effect               #
	################################################## 
	#Add to mat
	gradient = matrix(NA, nrow, ncol)
	for(i in 1:nrow)
		gradient[i,] = sort(abs(rnorm(ncol, 2,2)), decreasing=TRUE)
	
	mat = mat + gradient
	
	#Melt mat and correct its format for the SGA script
	matmelt = melt(mat)
	final = as.data.frame(matrix(NA, nrow*ncol, 9)); #9 column format
	

	
	#Query and array 
	final[[1]] = rep(1, length(matmelt[[1]]))
	final[[2]] = as.vector(quad_matrix)
	#Array plate id, set number, plate id, batch number all set to 1s
	final[[3]] = rep(1, nrow*ncol)
	final[[4]] = rep(1, nrow*ncol)
	final[[5]] = rep(1, nrow*ncol)
	final[[6]] = rep(1, nrow*ncol)
	#Rows, cols and colony sizes
	final[[7]] = matmelt[[1]]
	final[[8]] = matmelt[[2]]
	final[[9]] = matmelt[[3]]
	
	final_noise = final
	final_noise[[9]] = as.vector(mat_noise_int);
	write.table(final, path, quote=FALSE, sep="\t", row.names=FALSE, col.names=FALSE)
	write.table(final_noise, path_noise, quote=FALSE, sep="\t", row.names=FALSE, col.names=FALSE)
	write.table(simulated_interaction_quads, "simulated_interaction_quads.txt", quote=FALSE, sep="\t", row.names=FALSE, col.names=FALSE)
	writeLines(paste('Simulated data saved to:', path))
	writeLines(paste('Noisy simulated data saved to:', path_noise))
	
	
	
}

analyzeSimulatedData <- function(simulatedData, nosiyData, fields, fieldTitles=fields){
	firstField = fields[1];
	df = as.data.frame(1:length(fields))
	MSE = c()
	
	for(i in 1:length(fields)){
		field = fields[i];
		mse = (simulatedData[[field]] - nosiyData[firstField])^2;
		mse = mean(mse, na.rm=TRUE)
		MSE = c(MSE, sqrt(mse))
	}
	df[[2]] = MSE
	names(df) = c('a','b')
	
	mse_plot <- ggplot(df, aes(x=a, y=b)) + theme_grey(base_size=9) +geom_point(shape=3) + geom_line(size=0.1)+
	opts(title='MSE of data after each step of normalization') +
	scale_x_discrete('Step', breaks=1:length(fields),labels=fieldTitles) +
	scale_y_continuous('Square root of MSE')
	
	#Save plot
	#ggsave(filename='pdf/mse_after_step_k.pdf', plot=p)
	
	#Compare interactions
	int = read.table('simulated_interaction_quads.txt', header=FALSE)
	int = as.data.frame(int)[[1]]
	num_gis = length(int);
	
	cutoffs = seq.int(from=0, to=1000, by=10)
	df = as.data.frame(cutoffs)
	df$tp = NA
	df2 = df
	
	lastField = length(names(simulatedData));
	
	for(i in 1:length(cutoffs)){
		cutoff = cutoffs[i];
		tp_rate = 0
		tp_rate_n = 0
		for(j in 1:num_gis){
			x = int[j]
			
			ind = which(simulatedData$array == x)
			s1 = simulatedData[ind, lastField]
			s2 = noisyData[x, firstField]
			
			s1 = s1[which(!is.na(s1))]
			s2 = s2[which(!is.na(s2))]
			
			pass = length(which(s1 < cutoff))
			pass2 = length(which(s2 < cutoff))
			
			if(pass == length(s1))
				tp_rate = tp_rate + 1
			if(pass2 == length(s2))
				tp_rate_n = tp_rate_n + 1
		}
		df[i,2] = (tp_rate/num_gis)*100
		df2[i,2] = (tp_rate_n/num_gis)*100
	}
	
	#plot
	df$type = 'after_norm';
	df2$type = 'before_norm';
	df3 = rbind(df2,df);
	
	tp_plot <-ggplot(df3, aes(x=cutoffs,y=tp), group=type) + theme_grey(base_size=9) + geom_line(aes(color=type), size=0.6)  + 
	opts(title='True positive rate for quadruples below cutoff') +
	scale_x_continuous('Cutoff') + scale_y_continuous('True positive rate') +
	scale_colour_hue(name='Legend',labels=c('After normalization', 'Before normalization'), h=c(50, 200))
	
	#ggsave(filename='pdf/quadruples_tp_rate.pdf', plot=p);
	#Done
	
	plots = as.list(rep(NA,2))
	plots[[1]] = mse_plot
	plots[[2]] = tp_plot
	
	multiplot(mse_plot, tp_plot, cols=2)
	#Pick lowest? todo? 
}



#Displays a matrix using ggplot2 heatmap
displayMatrix <- function(mat, savepath=NA){
	df = as.table(mat)
  	rownames(df)=c(1:dim(mat)[1])
	colnames(df)=c(1:dim(mat)[2])
  		
  	#Melt matrix
  	dfmelt = melt(df)
  	
  	ggplot(dfmelt, aes(x=X2, y=X1, fill=value)) +
  	geom_tile() + 
  	scale_fill_gradient(low='black', high='yellow') +
  	labs(x = "Column", y = "Row") +
  	scale_y_continuous() + scale_y_reverse() +
  	opts(title=paste('Simulated data'), panel.background=theme_blank()) +
  	theme_bw(base_size=10)
  	
  	if(!is.na(savepath)){
  		ggsave(savepath)
  		writeLines(paste('Saved to file:', savepath))
  		dev.off()
  	}
}