setwd('/Users/omarwagih/Desktop/boone-summer-project-2012/script_r')

source('io/PrintHelp.R')

options("repos"="http://cran.us.r-project.org")
#printTitle('Installing/loading required packages')
#Check if necessary packages are installed, if not install them and load
packages = c('bootstrap', 'ggplot2', 'reshape', 'optparse', 'scales', 'doBy')
for(i in 1:length(packages)){
	pkg = packages[i];
	if(!pkg %in% rownames(installed.packages())){
		invisible(install.packages(pkg))
	}
	#Load package
	suppressPackageStartupMessages((require(pkg, character.only=TRUE)))
}

#Load all dependant scripts
#printTitle('Loading dependant scripts')
dirs = c('normalize', 'score', 'io', 'simulate')
for(i in 1:length(dirs)){
	pathnames <- list.files(pattern="[.]R$", path=dirs[i], full.names=TRUE);
	for(j in 1:length(pathnames))
		#writeLines(paste('Loading required script:', pathnames[j]))
	invisible(sapply(pathnames, FUN=source));
}

#####################
# ARGUMENT HANDLING #
#####################

option_list <- list(
make_option(c("-i", "--inputfiles"), help="Input plate files (required): containing colony sizes to be normalized (comma separated for multiple files or a zip file with all input files)"),
make_option(c("-s", "--savenames"), help="Save names (optional): for input files if any different (comma separated, in same order as inputfiles)", default="", type="character"),
make_option(c("-o", "--outputdir"), help="Output directory (optional): where the normalized results are saved [default %default]", default="", type="character"),
make_option(c("-d", "--handleout"), help="Handle output (optional): how the output is handled 'savefile' will store results in the output directory, 'console' will print files to the console, 'none' won't produce any output [default %default]", default="savefile", type="character"),
make_option(c("-l", "--linkagecutoff"), help="Linkage cutoff (optional): If chromsome position file is specified, genes within proximity of this linkage cutoff (in KB), are ignored [default %default]", default=200, type="integer"),
make_option(c("-b", "--cborder"), help="Control border (optional): value indicating number of control borders [default %default]", default=2, type="integer"),
make_option(c("-r", "--replicates"), help="Replicates (optional): value indicating number of replicates in the screen  [default %default]", default=4, type="integer"),
make_option(c("-m", "--doheatmaps"), help="Generate heat-maps (optional): plot heat-maps for normalized/scored colony sizes, 'yes' to plot, 'no' otherwise [default %default]", default="no", type="character"),
make_option(c("-t", "--jobtype"), help="Job type (optional): value indicating the type of job 'normalize, 'score' or 'both' [default %default]", default="normalize", type="character"),
make_option(c("-j", "--jobid"), help="Job id (optional): unique jobid for file saving purposes[default %default]", default="1", type="character")
)

#Validate INPUT TODO

#Parse input
args=parse_args(OptionParser(option_list = option_list))
writeLines(toString(args))
#Ensure output dir ends with slash:
if(substr(args$outputdir, nchar(args$outputdir), nchar(args$outputdir)) != '/' & args$outputdir != "")
	args$outputdir = paste(args$outputdir, '/', sep="");

#split inputfiles
inputfiles = strsplit(args$inputfiles, ',')[[1]]
outputdir = args$outputdir
handleoutput = args$handleout
if(args$savenames == ""){ 
	savenames = inputfiles 
}else{ 
	savenames = strsplit(args$savenames, ',')[[1]]
}

jobtype = args$jobtype
doheatmaps = args$doheatmaps


#convert savenames from UTF to latin - save name is the name of the uploaded files by the user
#which are converted to UTF to avoid problems with arg parsing
for(i in 1:length(savenames)) savenames[i] = URLdecode(savenames[i])

#Create a directory for the output - to be zipped
jobDirName = paste("sgatools-job-", args$jobid, sep="");
jobDir = paste(args$outputdir, jobDirName, sep="");
unlink(jobDir, force=TRUE)
dir.create(jobDir, showWarnings = TRUE)

heatmaps_path = paste("sgatools-plots-", args$jobid, '.pdf', sep="");
heatmaps_path = paste(args$outputdir, heatmaps_path, sep="");

customheight = 10;
if(jobtype == 'score'){
	customheight = 3;
}
pdf(heatmaps_path, width=6, height=customheight)

normalizationRan = 0;
for(file in 1:length(inputfiles)){	
	inputfile = inputfiles[file]
	writeLines(inputfile)
	savename = savenames[file]
	inputfileName = strsplit(savename, "/")[[1]];
	inputfileName = inputfileName[length(inputfileName)];
	
	#Read SGA formatted file
   	read.data = readSGAFile(inputfile);
	
	#Run normalization
	if(jobtype=='normalize' | jobtype == 'both'){
		returned_data = runNormalization(INPUT_DATA=read.data, 
				LINKAGE_CUTOFF= (args$linkagecutoff * 1e3),
				CONTROL_BORDER=args$cborder,
				NUM_REPLICATES=args$replicates)
		
		data = returned_data[[1]];#The sgadata returned
		normalizationRan = 1;
		#Plot heatmaps?
		if(doheatmaps == 'yes'){
			plotSGA_all_plates(returned_data[[2]], names(returned_data[[2]])[12:16])
		}
		
		if(jobtype=='both'){
			#Update the read data with the data containing normalized colony sizes
			read.data[[1]] = data
			jobtype='score';
		}
		
	}
	
	if(jobtype=='score'){
		writeLines('doing scoring')
		#Get scores
		data = runScoring(INPUT_DATA=read.data)
		#only plot scored stuff if we did not run normalization
		if(normalizationRan == 0){
			plotSGA_all_plates(data, names(data)[8], type='s')
		}
	}
	
	#Put the modified plate file back into read file
	read.data[[1]] = data;
	
	if(handleoutput == "savefile"){
		if(jobtype=='normalize'){
			savepath = paste(jobDir, "/","normalized_", inputfileName, sep="");
		}
		if(jobtype=='score'){
			savepath = paste(jobDir, "/","scored_", inputfileName, sep="");
		}
		writeSGAFile(savepath, read.data)
		#write.table(data, file=savepath, quote=FALSE, row.names=FALSE,col.names=FALSE, sep="\t", na='')
	}
}

#Close pdf connection for plots
dev.off()

#Zip the saved files
if(outputdir != "")
	setwd(outputdir);

tozip = paste(jobDirName, "/*", sep="");
zipdest = paste(jobDirName, '.zip', sep="");

#If already exists a zip file with same name (unlikely)- remove it
if(file.exists(zipdest))
	unlink(zipdest, force=TRUE)
system(paste('zip' ,zipdest, tozip))

#Delete the directory we zipped and its contents - no longer need
system(paste('rm -rf', jobDir))

#Write destination of zip file
writeLines(paste(jobDir, '.zip','#',heatmaps_path, sep=""))


#####################
#Run 
#data = run('inputdata/raw_sgadata_first10000.txt')

#Simulations
#simulatedData = run('simulated_data.txt')
#noisyData = run('simulated_noisy_data.txt')
#print(simulatedData)
