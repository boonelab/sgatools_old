#Returns a gaussian filter matrix with dimensions x by x: equal to fspecial function in matlab
#Inputs:
#	x = dimensions (number of rows/cols) of the returned gaussian filter
#	sigma = standard deviation 
fgaussian <- function(x, sigma){
	x = seq(x)
	mat = matrix(NA, length(x),length(x));
	for(i in 1:length(x)){
		for(j in 1:length(x)){
			n1 = x[i];
			n2 = x[j];
			mat[i,j] = exp(-(n1^2+n2^2)/(2*sigma^2));
		}
	}
	mat = mat/sum(mat)
	return(mat)
}

#Average filter
faverage <- function(size){
	x = 1/(size*size)
	ret = matrix(rep(x, size*size), size,size)
	return(ret)
}

#Helper function for fgaussian - given some value x, returns a gradient array begining with 0 on the inside and increasing outwards. Example: x = 7 returns [3,2,1,0,1,2,3] 
#Inputs:
#	x = number of elements in the returned array
seq <- function(x){
	n = x;
	x = c(1:x)
	if(n%%2){
		rhs = x[1:floor(length(x)/2)];
		lhs = rev(rhs);
		return(c(lhs,0,rhs))
	}else{
		rhs = x[1:floor(length(x)/2)] - 0.5;
		lhs = rev(rhs);
		return(c(lhs,rhs))
	}
}

#Applies a filter to a matrix: see imfilter (matlab) with replicate option
#Inputs:
#	mat = matrix to which the filter is applied
# 	filter = a square matrix filter to be applied to the matrix 
applyfilter <- function(mat, filter, padding_type = 'zeros'){
	mat2 = mat
	fs = dim(filter);
	if(fs[1] != fs[2])
		stop('Filter must be a square matrix')
	if(fs[1] %% 2 == 0)
		stop('Filter dimensions must be odd')
	if(fs[1] == 1)
		stop('Filter dimensions must be greater than one')
		
	x = fs[1];
	a = (x-1)/2;
	
	s = dim(mat2)
	r = matrix(0, s[1], s[2])
	
	start = 1+a;
	end_1 = s[1]+a;
	end_2 = s[2]+a;
	
	mat2 = padmatrix(mat, a, padding_type)
	
	for(i in start:end_1){
		for(j in start:end_2){
			temp = mat2[(i-a):(i+a), (j-a):(j+a)] * filter;
			r[(i-a),(j-a)] = sum(temp)
		}
	}
	return(r)
}

#Applies a filter to a matrix: see imfilter (matlab) with replicate option
#Inputs:
#	mat = matrix to which the filter is applied
# 	dim = number of rows/cols of window
medianfilter2d <- function(mat, dim, padding_type = 'zeros'){
	mat2 = mat
	fs = c()
	fs[1] = dim
	fs[2] = dim
	
	if(fs[1] != fs[2])
		stop('Filter must be a square matrix')
	if(fs[1] %% 2 == 0)
		stop('Filter dimensions must be odd')
	if(fs[1] == 1)
		stop('Filter dimensions must be greater than one')
		
	x = fs[1];
	a = (x-1)/2;
	
	s = dim(mat2)
	r = matrix(0, s[1], s[2])
	
	start = 1+a;
	end_1 = s[1]+a;
	end_2 = s[2]+a;
	
	mat2 = padmatrix(mat, a, padding_type)
	
	for(i in start:end_1){
		for(j in start:end_2){
			temp = mat2[(i-a):(i+a), (j-a):(j+a)];
			r[(i-a),(j-a)] = median(temp)
		}
	}
	return(r)
}

#Adds a padding to some matrix mat such that the padding is equal to the value of the nearest cell
#Inputs:
#	mat = matrix to which the padding is added
#	lvl = number of levels (rows/columns) of padding to be added
#	padding = type of padding on the matrix, zero will put zeros as borders, replicate will put the value of the nearest cell
padmatrix <- function(mat, lvl, padding){
	s = dim(mat);
	row_up = mat[1,]
	row_down = mat[s[1],]
	
	if(padding == 'zeros'){
		row_up = rep(0, length(row_up))
		row_down = rep(0, length(row_down))
	}
	#Add upper replicates
	ret = t(matrix(rep(row_up, lvl), length(as.vector(row_up))))
	#Add matrix itself
	ret = rbind(ret, mat)
	#Add lower replicates
	ret = rbind(ret, t(matrix(rep(row_down, lvl), length(as.vector(row_down)))))
	
	#Add columns
	s = dim(ret);
	col_left = ret[,1]
	col_right = ret[,s[2]]
	
	if(padding == 'zeros'){
		col_left = rep(0, length(col_left))
		col_right = rep(0, length(col_right))
	}
	
	#Add left columns
	ret2 = matrix(rep(col_left, lvl), length(as.vector(col_left)))
	#Add matrix itself
	ret2 = cbind(ret2, ret)
	#Add right columns
	ret2 = cbind(ret2, matrix(rep(col_right, lvl), length(as.vector(col_right))))
	
	#return 
	return(ret2)
}