printTitle <- function(title, n=50){
	
	title = paste('', title, '')
	x = floor(((n- nchar(title))-2) /2)
	sp1 = paste(rep(' ', x), collapse='')
	title = paste('#', sp1, title, sep='')
	
	x = n - (nchar(title)) - 1
	sp2 = paste(rep(' ', x), collapse='')
	
	title = paste(title, sp2,'#', sep='')
	
	lower = paste(rep('#', n), collapse='')
	writeLines(rep('#', n), sep='')
	writeLines(paste('\n',title, sep=''))
	writeLines(paste(lower, '\n'), sep='')
}