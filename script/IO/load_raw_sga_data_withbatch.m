%%
% LOAD_RAW_SGA_DATA_WITHBATCH
%
% Description:
%   This function loads a text file with raw SGA colony size data.
%   The file is assumed to be in the following tab-delimited format:
%   query ORF, array ORF, arrayplateid, setID, plateID, batchID, row, column, colony
%   size (pixels)
%
% Syntax:
%   data = load_raw_sga_data_withbatch(inputfile)
%
% Inputs:
%   inputfile - input filename
%
% Outputs:
%   data - a structure with fields corresponding to each of the columns 
%
% Authors: Chad Myers (cmyers@cs.umn.edu), Anastasia Baryshnikova (a.baryshnikova@utoronto.ca)
%
% Last revision: 2010-07-19
%
%%
function sgadata = load_raw_sga_data_withbatch(inputfile)

% Print the name and path of this script
p = mfilename('fullpath');
fprintf('\nLoad raw SGA data with batch script: %s\n\n',p);

% First, run perl script to convert data to completely numeric (this speeds
% the input process up)
perl('process_rawsga_dmdata.pl',inputfile);

rawdata = importdata([inputfile,'_numeric']);
rawdata = uint32(rawdata(:,1:9));

sgadata.querys=rawdata(:,1);
sgadata.arrays=rawdata(:,2);
sgadata.arrayplateids=rawdata(:,3);
sgadata.setids=rawdata(:,4);
sgadata.plateids=rawdata(:,5);
sgadata.batch=rawdata(:,6);
sgadata.rows=rawdata(:,7);
sgadata.cols=rawdata(:,8);
sgadata.colsize=double(rawdata(:,9));

data=importdata([inputfile,'_orfidmap']);
[vals,ind] = sort(data.data);
sgadata.orfnames = data.textdata(ind);

% Remove the annotation and save just the ORF name
tmp = split_by_delimiter('_', sgadata.orfnames);
sgadata.orfnames_ref = tmp(:,1);