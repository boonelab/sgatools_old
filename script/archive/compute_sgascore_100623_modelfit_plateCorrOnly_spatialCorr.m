%% Comments
%
% Requirements: Statistics Toolbox
%
% Code based on compute_sgascore_081004_newres_varfilt_nobootstrp_0p1.m
%
% Define inputfile, outputfile, removearraylist, smfitnessfile and linkagefile ahead of time.
% Defaults:
inputfile = 'Datasets/Raw_data/fullgenome/09-01-16/raw_data_fullgenome_collab_090116.txt_9fields.txt';
outputfile = 'Datasets/SGA_scores/fullgenome/10-07-19/sgascore_in090116_out100719_plateCorrOnly_spatialCorr.txt';
removearraylist = 'Utils/Matlab/Scoring_scripts/SGA/refdata/remove_array_list.txt';
removequerylist = 'Utils/Matlab/Scoring_scripts/SGA/refdata/remove_query_list.txt'; % TO BE REMOVED!!!
linkagefile = 'Utils/Matlab/Scoring_scripts/SGA/refdata/query_specific_linkage_090116.txt';
smfitnessfile = 'Utils/Matlab/Scoring_scripts/SGA/refdata/SMF_standard_SN+DAMP+TS_090501.txt';

%
%
%
% Assumptions:
% 1) control screens queries: "undefined"
% 2) any query can have an annotation after the underscore sign ("YAL002C_test")
% 3) queries and arrays are yeast ORFs (they will get mapped to specific chromosomes and chromosomal coordinates)
% 4) the border of the plates are composed of a control WT strain (HIS3 = YOR202W)
% 5) all plates are in 1536 format (32 rows x 48 columns)
%
% Run: addpath(genpath('Utils/Matlab/Scoring_scripts/SGA/'))
%
%% Checks before starting

% Check inputs
vars_to_check = {'inputfile','removearraylist','linkagefile','smfitnessfile'};
for i = 1 : length(vars_to_check) 
    if ~exist(vars_to_check{i},'var')
        error(['Define' vars_to_check{i} '.']);
    else
        if ~exist(eval(vars_to_check{i}), 'file')
            error(['Indicated ' vars_to_check{i} ' does not exist: ' eval(vars_to_check{i})]);
        end
    end
end

% Check output
if ~exist('outputfile','var')
    error('Define outputfile.');
else
    tmp = split_by_delimiter('/', outputfile);
    outputdir = join_by_delimiter(tmp(1:end-1), '/');
    if ~exist(outputdir,'dir')
        error(['Output directory ' outputdir ' does not exist.']);
    end
end

%% Load raw data

sgadata = load_raw_sga_data_withbatch(inputfile);
fprintf('Data loaded.\n');
 
%% Define colonies to ignore for some normalization steps

% Get colonies corresponding to questionable arrays
dat = importdata(removearraylist);
[t, ind1, ind2] = intersect(sgadata.orfnames, dat);
ignore_cols1 = find(ismember(sgadata.arrays, ind1));

% Get colonies corresponding to questionable queries (TO BE REMOVED)
dat = importdata(removequerylist);
[t, ind1, ind2] = intersect(sgadata.orfnames, dat);
ignore_cols2 = find(ismember(sgadata.querys, ind1));

% Get colonies corresponding to linkage
%all_linkage_cols = filter_all_linkage_colonies_queryspecific(sgadata, linkagefile);
load all_linkage_cols; % (TO BE REMOVED)

ignore_cols = unique([ignore_cols1; ignore_cols2; all_linkage_cols]);

% Save the workspace
% save('-v7.3',[outputfile,'_matfile']);

%% Speed optimization #1: Construct plateid->ind mapping

% Minimize the plateids
sgadata.plateids_old = sgadata.plateids;
[all_plateids, m, n] = unique(sgadata.plateids);
all_plateids_new = (1:length(all_plateids))';
sgadata.plateids = all_plateids_new(n);

% Constructing plateid->ind map
all_plateids = unique(sgadata.plateids);
plate_id_map = cell(max(all_plateids),1);
plate_id_map_ignorecols = cell(max(all_plateids),1);

fprintf(['\nConstructing plateid->ind map...\n|' blanks(50) '|\n|']);
for i = 1:length(all_plateids)
    plate_id_map{all_plateids(i)} = find(sgadata.plateids == all_plateids(i));
    plate_id_map_ignorecols{all_plateids(i)} = setdiff(plate_id_map{all_plateids(i)}, ignore_cols);
    
    print_progress(length(all_plateids),i);
end
fprintf('|\n');

%% Speed optimization #2: Construct query->ind mapping

fprintf('Constructing query->ind map...\n');

all_querys = unique(sgadata.querys);
query_map = cell(max(all_querys),1);

for i=1:length(all_querys),
   query_map{all_querys(i)} =  find(sgadata.querys == all_querys(i));
end

%% Speed optimization #3: Construct array->ind mapping

fprintf('Constructing array->ind map...\n');

all_arrays = unique(sgadata.arrays);
array_map = cell(max(all_arrays),1);

for i=1:length(all_arrays)
   array_map{all_arrays(i)}=find(sgadata.arrays == all_arrays(i));
end

%% Speed optimization #4: Create index of each group of 4 spots

all_arrayplateids = unique(sgadata.arrayplateids);
all_arrayplateids_map = zeros(max(all_arrayplateids),1);
all_arrayplateids_map(all_arrayplateids) = 1:length(all_arrayplateids);

% Map colony coordinates back to 384 format
row384 = ceil(sgadata.rows/2);
col384 = ceil(sgadata.cols/2);
ind384 = sub2ind([16 24], row384, col384);

% Generate a replicate ID unique across multiple arrayplates
sgadata.replicateid = (all_arrayplateids_map(sgadata.arrayplateids)-1)*384 + double(ind384);
sgadata.spots = sgadata.plateids*10000 + sgadata.replicateid;

%% Normalizations


% Default median colony size per plate
default_median_colsize = 510;


% Plate normalization
sgadata.colsize_platenorm = ...
    apply_plate_normalization(sgadata, 'colsize', ignore_cols, default_median_colsize, plate_id_map);


% Filter very large colonies
ind = find(sgadata.colsize_platenorm >= 1.5*default_median_colsize & ...
    sgadata.rows > 2 & sgadata.rows < 31 & ...
    sgadata.cols > 2 & sgadata.cols < 47);

all_spots = unique(sgadata.spots(ind));
num_big_colonies_per_spot = histc(sgadata.spots(ind), all_spots);
spots_to_remove = all_spots(num_big_colonies_per_spot >= 3);

ii = find(ismember(sgadata.spots, spots_to_remove));
sgadata.colsize_platenorm(ii) = NaN;


% Get colony residuals
all_arrplates = unique(sgadata.arrayplateids);
width = 48;
height = 32;
field = 'colsize_platenorm';

sgadata.residual = sgadata.(field);
sgadata.logresidual = sgadata.(field);
sgadata.arraymedian = sgadata.(field);

array_means = zeros(length(all_arrplates),width*height)+NaN;

fprintf(['Calculating colony residuals...\n|' blanks(50) '|\n|']);

for i = 1:length(all_arrplates)
    currplates = unique(sgadata.plateids(sgadata.arrayplateids == all_arrplates(i)));
    t=[];   % stores the list of colony sizes for this arrayplate
    save_inds = struct;
    
    for j = 1:length(currplates)
   
        % Get a matrix of colony sizes (d) and colony indices (d_map) for the plate
        ind = plate_id_map{currplates(j)};
        d = zeros(32,48);
        d(:,[1,2,47,48]) = NaN;
        d([1,2,31,32],:) = NaN;
        
        d_map = zeros(32,48)+1; % Default reference to 1st index
        
        iii = sub2ind([32,48], sgadata.rows(ind), sgadata.cols(ind));
        d_map(iii) = ind;
        d(iii) = sgadata.(field)(ind);
        
        t = [t,d(:)];
        save_inds(j).ind_mat = d_map(:);
        save_inds(j).dat_mat = d(:);
        
    end
    
    array_means(i,:) = nanmedian(t,2);
    array_means(i,array_means(i,:) <= 0)=NaN;
    
    for j=1:length(currplates)
        
        t = sgadata.(field)(save_inds(j).ind_mat);
        t(t <= 0)=NaN;
        sgadata.logresidual(save_inds(j).ind_mat)=log(t./array_means(i,:)');
        sgadata.arraymedian(save_inds(j).ind_mat)=array_means(i,:)';
        sgadata.residual(save_inds(j).ind_mat)=t-array_means(i,:)';
        
    end
    
    % Print progress
    print_progress(length(all_arrplates), i);
    
end

fprintf('|\n');

% Spatial normalization
% sgadata.spatialnorm_colsize = ...
%     apply_spatial_normalization(sgadata, 'logresidual', ignore_cols, plate_id_map);
% 
% % Row/column correction
% sgadata.rowcolcorr_colsize = ...
%     apply_rowcol_normalization(sgadata, 'spatialnorm_colsize', ignore_cols, plate_id_map);
% 
% 
sgadata.rowcolcorr_colsize = sgadata.(field);

% Competition correction
sgadata.residual_spatialnorm = sgadata.rowcolcorr_colsize - sgadata.arraymedian;
sgadata.compcorr_colsize = ...
    apply_competition_correction(sgadata, 'residual_spatialnorm', ignore_cols, plate_id_map);

% 
% % One last round of plate scaling
% sgadata.finalplatecorr_colsize = ...
%     apply_plate_normalization(sgadata, 'compcorr_colsize', ignore_cols, default_median_colsize, plate_id_map);
% 

sgadata.finalplatecorr_colsize = sgadata.compcorr_colsize;

% Save the workspace
% save('-v7.3',[outputfile,'_matfile']);


% Do filtering based on held-out CV values
field = 'finalplatecorr_colsize';
all_querys = unique(sgadata.querys);
result = sgadata.(field);

his3_ind = strmatch('YOR202W',sgadata.orfnames,'exact');

fprintf(['Running the hold-one-out filter...\n|' blanks(50) '|\n|']);
for i = 1:length(all_querys)
    
    ind1 = query_map{all_querys(i)};
    curr_plates = unique(sgadata.plateids(ind1));
    
    for k = 1:length(curr_plates)
        
        ind = plate_id_map{curr_plates(k)};
        max_cols = length(find(sgadata.arrays(ind) == his3_ind));

        curr_arrays = unique(sgadata.arrays(ind));
        curr_mat = zeros(length(curr_arrays),max_cols)+NaN;
        ind_mat = zeros(length(curr_arrays),max_cols)+NaN;
    
        for j = 1:length(curr_arrays)   
            ind2 = find(sgadata.arrays(ind)==curr_arrays(j));
            curr_mat(j,1:length(ind2)) = sgadata.(field)(ind(ind2));
            ind_mat(j,1:length(ind2)) = ind(ind2);

            if curr_arrays(j) == his3_ind
                continue;
            end
        
            ind3 = find(~isnan(curr_mat(j,:)));
            vals = jackknife(@nanstd,curr_mat(j,ind3));        
            t = find(vals < nanmean(vals)*(1-2*(1/length(vals))));

            if length(t) > 1
                continue; 
            end

            result(ind_mat(j,ind3(t))) = NaN;

        end
        
    end
   
    % Print progress
    print_progress(length(all_querys), i);

end
fprintf('|\n');

sgadata.filt_colsize = result;


%% Filters section

field = 'filt_colsize';

% Set values == 0 to NaN
sgadata.(field)(sgadata.(field) < 1) = NaN;

% Set values > 1000 to 1000
sgadata.(field)(sgadata.(field) > 1000) = 1000;

% Remove border (contains HIS3 control strains)
ind = find(sgadata.rows < 3 | sgadata.rows > 30 | sgadata.cols < 3 | sgadata.cols > 46);
sgadata.(field)(ind) = NaN;

% Delete any array strain that is missing more than 15% of its supposed occurrences
all_arrays = unique(sgadata.arrays);

tot_cols = zeros(length(all_arrays),1);
good_cols = zeros(length(all_arrays),1);

for i = 1:length(all_arrays)
    
   tot_cols(i,1) = length(array_map{all_arrays(i)});
   good_cols(i,1) = length(find(~isnan(sgadata.(field)(array_map{all_arrays(i)}))));
   
end

ind = find(good_cols < 0.85 * tot_cols);
ind = setdiff(ind,strmatch('YOR202W',sgadata.orfnames(all_arrays),'exact'));

remove_ind = find(ismember(sgadata.arrays, all_arrays(ind)));
sgadata.(field)(remove_ind) = NaN;

sgadata.(field)(ignore_cols) = NaN;

fprintf('Finished applying filters...\n');

%% Batch correction

% % Get array plate means (use all screens, including WT screens)
% 
% all_arrplates = unique(sgadata.arrayplateids);
% arrplate_ind = zeros(max(all_arrplates),1);
% arrplate_ind(all_arrplates) = 1:length(all_arrplates);  
% 
% width = 48;
% height = 32;
% 
% array_means = zeros(length(all_arrplates),width*height)+NaN;
% 
% fprintf(['Getting arrayplate means...\n|' blanks(50) '|\n|']);
% for i = 1:length(all_arrplates)
%     
%     currplates = unique(sgadata.plateids(sgadata.arrayplateids == all_arrplates(i)));
%     t = [];
%     
%     for j = 1:length(currplates)
%         
%         ind = plate_id_map{currplates(j)};
%         iii = sub2ind([32,48], sgadata.rows(ind), sgadata.cols(ind));
%         
%         d = zeros(32,48);
%         d(:,[1 2 47 48]) = NaN;
%         d([1 2 31 32],:) = NaN;
%         d(iii) = sgadata.(field)(ind);
%         
%         t = [t,d(:)];
%         
%     end
%     
%     array_means(i,:) = nanmean(t,2);
%     
%     % Print progress
%     print_progress(length(all_arrplates),i);
%     
% end
% fprintf('|\n');
%     
% 
% % Do batch normalization using LDA
% 
% save_mats=struct;
% 
% fprintf(['Preparing for batch normalization...\n|' blanks(50) '|\n|']);
% for i=1:length(all_arrplates)
%     
%     curr_plates = unique(sgadata.plateids(sgadata.arrayplateids == all_arrplates(i)));
%     
%     curr_mat = zeros(length(curr_plates),width*height)+NaN;
%     curr_ind_mat = zeros(length(curr_plates),width*height)+NaN;
%     curr_batch = zeros(length(curr_plates),1);
%     
%     for j = 1:length(curr_plates) 
%         
%         ind = plate_id_map{curr_plates(j)};
%         iii = sub2ind([32,48], sgadata.rows(ind), sgadata.cols(ind));
%         
%         d = zeros(32,48);
%         d(:,[1 2 47 48]) = NaN;
%         d([1 2 31 32],:) = NaN;
%         d_map = zeros(32,48) + 1; % default reference to the 1st index
%         
%         d_map(iii) = ind;
%         d(iii) = sgadata.(field)(ind);
%         
%         curr_mat(j,:)=d(:);
%         curr_ind_mat(j,:)=d_map(:);
%         
%         curr_batch(j) = unique(sgadata.batch(ind));
%         
%     end
%     
%     t = curr_mat - repmat(array_means(i,:),size(curr_mat,1),1);
%            
%     save_mats(i).mat = t;
%     save_mats(i).mat_ind = curr_ind_mat;
%     save_mats(i).batch = curr_batch;
%     
%     % Print progress
%     print_progress(length(all_arrplates),i);
%     
% end
% fprintf('|\n');
% 
%     
% sgadata.batchnorm_colsize = sgadata.(field);
% outfield = 'batchnorm_colsize';
% 
% % Normalize out batch effect. Method: LDA (supervised)
% 
% perc_var = 0.1;
% 
% fprintf(['Batch normalization...\n|', blanks(50), '|\n|']);
% 
% for j = 1:length(all_arrplates)
%     
%     t = save_mats(j).mat;
%     t(isnan(t)) = 0;
%     curr_batch = save_mats(j).batch; 
%   
%     % Check if some of the batches are too small -- make a larger orphan batch
%     all_batches = unique(curr_batch);
%     num_batch = histc(curr_batch, all_batches);
%     orphan_batch = max(curr_batch)+1;
%     curr_batch(ismember(curr_batch,all_batches(num_batch < 3))) = orphan_batch;
%   
%     tnorm = multi_class_lda(t,curr_batch,perc_var);
%     sgadata.(outfield)(save_mats(j).mat_ind(:)) = sgadata.(outfield)(save_mats(j).mat_ind(:)) + (tnorm(:)-t(:));
%     
%     % Print progress
%     print_progress(length(all_arrplates),j);
%     
% end
% 
% fprintf('|\n');
% 
% field = 'batchnorm_colsize';

field = 'filt_colsize';


%% Calculate array WT variance
all_arrays = unique(sgadata.arrays);

ind2 = query_map{strmatch('undefined',sgadata.orfnames,'exact')};

array_vars = zeros(length(all_arrays),2);
fprintf(['Calculating array WT variance...\n|' blanks(50) '|\n|']);
for i = 1:length(all_arrays)
    ind = intersect(ind2, array_map{all_arrays(i)});
    t = max(sgadata.(field)(ind),1);
    t(isnan(sgadata.(field)(ind))) = NaN;
    array_vars(i,:)=[nanmean(log(t)),nanvar(log(t))];
    
    print_progress(length(all_arrays),i);
end
fprintf('|\n');

nanind = find(isnan(array_vars(:,1)));

% For the NaNs, we need to compute means from the other screens (not just WT).
% This is useful when there's a WT-screen specific issue (e.g., URA3 linkage group).

for i = nanind'
    ind = array_map{all_arrays(i)};
    t = max(sgadata.(field)(ind),1);
    t(isnan(sgadata.(field)(ind))) = NaN;
    array_vars(i,1)=nanmean(log(t));
end
array_vars(nanind,2) = nanmedian(array_vars(:,2)); % Compute vars from the median across all others

%% Calculate query variance

all_querys = unique(sgadata.querys);

% Mean and variance of double mutants
sgadata.dm_normmean = zeros(length(sgadata.colsize),1)+NaN;
sgadata.dm_normvar = zeros(length(sgadata.colsize),1)+NaN;
sgadata.dm_num = zeros(length(sgadata.colsize),1)+NaN;

fprintf(['Computing average for double mutants...\n|' blanks(50) '|\n|']);

for i = 1:length(all_querys)
    
    if all_querys(i) == strmatch('undefined',sgadata.orfnames)
        continue;
    end
    
    ind = query_map{all_querys(i)};
    ind = setdiff(ind, find(isnan(sgadata.(field))));
    
    spots = sgadata.replicateid(ind) + double(sgadata.plateids(ind))*1000;
    [all_spots, m, n] = unique(spots);
    
    % Compute average, variance and number of colonies for each group of spots
    mn = grpstats(log(sgadata.(field)(ind)), spots, 'mean');
    vr = grpstats(log(sgadata.(field)(ind)), spots, 'std').^2;
    nm = grpstats(sgadata.(field)(ind), spots, 'numel');
    
    sgadata.dm_normmean(ind) = mn(n);
    sgadata.dm_normvar(ind) = vr(n);
    sgadata.dm_num(ind) = nm(n);
    
    % Print progress
    print_progress(length(all_querys), i);
    
end
fprintf('|\n');

% Pool across arrayplates for each query
all_arrayplateids = unique(sgadata.arrayplateids);
query_arrplate_vars = [];   %zeros(length(all_querys),length(all_arrplates))+NaN;
query_arrplate_relerr = []; %zeros(length(all_querys),length(all_arrplates))+NaN;

fprintf(['Pooling across arrayplates for each query...\n|' blanks(50) '|\n|']);
for i = 1:length(all_querys)
    
    ind = query_map{all_querys(i)};
    
    for j = 1:length(all_arrayplateids)
        
        tmp_ind = find(sgadata.arrayplateids(ind) == all_arrayplateids(j));
        currsets = unique(sgadata.setids(tmp_ind));
        
        for k = 1:length(currsets)
            
            tmp_ind2 = find(sgadata.setids(tmp_ind) == currsets(k));
            curr_ind = tmp_ind(tmp_ind2);
            
            query_arrplate_relerr = [query_arrplate_relerr; i,j,k,sqrt(exp((1./(length(curr_ind)-length(unique(sgadata.arrays(curr_ind)))))*nansum(sgadata.dm_normvar(curr_ind).*((sgadata.dm_num(curr_ind)-1)./sgadata.dm_num(curr_ind))))-1)];
            query_arrplate_vars = [query_arrplate_vars; i,j,k,(1./(length(curr_ind)-length(unique(sgadata.arrays(curr_ind)))))*nansum(sgadata.dm_normvar(curr_ind).*((sgadata.dm_num(curr_ind)-1)./sgadata.dm_num(curr_ind)))];
            
        end
    end
    
    % Print progress
    print_progress(length(all_querys), i);
end
fprintf('|\n');

% Save the workspace
% save('-v7.3',[outputfile,'_matfile']);

%%

% Load the single mutant fitness file
[data.f1, data.f2, data.f3] = textread(smfitnessfile,'%s %f %f');
sm_fitness_orfs = data.f1;
sm_fitness = [data.f2 data.f3];
clear data;

[int, a, b] = intersect(sgadata.orfnames, sm_fitness_orfs);
fg_smfit = zeros(length(sgadata.orfnames),2) + NaN;
fg_smfit(a,:) = sm_fitness(b,:);
final_smfit = fg_smfit(:,1);
final_smfit_std = fg_smfit(:,2);

all_arrays = unique(sgadata.arrays);

model_fits = zeros(length(all_arrays),length(sgadata.orfnames)+1) + NaN;
model_fit_std = zeros(length(all_arrays),length(sgadata.orfnames)+1) + NaN;

fprintf(['Model fitting...\n|' blanks(50) '|\n|']);
for i = 1:length(all_arrays)
    
    all_ind = array_map{all_arrays(i)};
    all_ind = setdiff(all_ind, find(isnan(sgadata.(field))));
   
    if isempty(all_ind)
       continue;
    end
   
    if all_arrays(i) == strmatch('YOR202W',sgadata.orfnames)
       continue;
    end

    querys = unique(sgadata.querys(all_ind));
     
    ind2 = find(~isnan(final_smfit(sgadata.querys(all_ind))));
    p = polyfit(final_smfit(sgadata.querys(all_ind(ind2))),sgadata.(field)(all_ind(ind2)),1);
    
    curr_data = sgadata.(field)(all_ind);
% Possible deletion
%    curr_data(ind2) = curr_data(ind2) + (nanmean(sgadata.(field)(all_ind(ind2))) - (p(1)*final_smfit(sgadata.querys(all_ind(ind2)))+p(2)));
    
    curr_querys = sgadata.querys(all_ind);
    
    uniq_querys = unique(curr_querys);
    
    query_effects = zeros(length(uniq_querys),1);
    query_effects_std = zeros(length(uniq_querys),1);
    
    for k = 1:length(uniq_querys)
        
        ind = find(curr_querys == uniq_querys(k));
        query_effects(k) = nanmean(curr_data(ind));
        query_effects_std(k) = nanstd(curr_data(ind));
    end
    
    
    arrmean = nanmean(query_effects);
    arrstd = nanstd(query_effects);
    query_effects = query_effects - arrmean;
   
    query_effects = [arrmean; query_effects];
    query_effects_std = [arrstd; query_effects_std];
   
% Possible deletion
%    res = adjust_model_fit(query_effects, query_effects_std);
%    query_effects(1) = query_effects(1) + res;
%    query_effects(2:end) = query_effects(2:end) - res;

    [int, a, b] = intersect(1:length(sgadata.orfnames), uniq_querys);

    model_fits(i,a+1) = query_effects(b+1);
    model_fit_std(i,a+1) = query_effects_std(b+1);
    model_fits(i,1) = query_effects(1);
    model_fit_std(i,1) = query_effects_std(1);
    
    % Print progress
    print_progress(length(all_arrays),i);
   
end
fprintf('|\n');


% Fill in SM fitness for arrays that appear here that aren't in standard
final_smfit = fg_smfit(:,1);
final_smfit_std = fg_smfit(:,2);

model_smfits = zeros(size(fg_smfit,1),1);
model_smstd = zeros(size(fg_smfit,1),1);

model_smfits(all_arrays)=model_fits(:,1);
model_smstd(all_arrays)=model_fit_std(:,1);

model_smfits(model_smfits == 0) = NaN;
model_smstd(model_smstd == 0) = NaN;

ind = find(~isnan(final_smfit(:,1)) & ~isnan(model_smfits));
p = polyfit(model_smfits(ind), final_smfit(ind),1);

ind = find(isnan(final_smfit(:,1)));
final_smfit(ind) = model_smfits(ind)*p(1)+p(2);
final_smfit_std(ind) = model_smstd(ind)*p(1);


% SGA score
sga_score = model_fits(:,2:end);
sga_score_std = model_fit_std(:,2:end);

complete_mat = zeros(length(sgadata.orfnames)) + NaN;
complete_mat_std = zeros(length(sgadata.orfnames)) + NaN;
complete_mat(:,all_arrays) = sga_score';
complete_mat_std(:,all_arrays) = sga_score_std';

avar = zeros(1,length(sgadata.orfnames)) + NaN;
amean = zeros(1,length(sgadata.orfnames)) + NaN;

avar(all_arrays) = array_vars(:,2);
amean(all_arrays) = array_vars(:,1);

amat = repmat(avar,size(complete_mat,1),1);
amat_mean = repmat(amean,size(complete_mat,1),1);

all_arrayplateids = unique(sgadata.arrayplateids);
all_arrayplateids_map = zeros(max(all_arrayplateids),1);
all_arrayplateids_map(all_arrayplateids) = 1:length(all_arrayplateids);

% Create array to arrayplate map
array_arrplate = cell(max(sgadata.arrays),1);
for i = 1:length(all_arrays)
    
    ind = unique(sgadata.arrayplateids(array_map{all_arrays(i)}));
    array_arrplate{all_arrays(i)} = ind;
    
end

qmat = zeros(size(complete_mat,1),size(complete_mat,2)) + NaN;
for j = 1:length(all_arrays)
    
    arrplate_ind = all_arrayplateids_map(array_arrplate{all_arrays(j)}); % arrayplate(s) this array appears on
    ind = find(ismember(query_arrplate_vars(:,2), arrplate_ind));
       
    for i = 1:length(all_querys)
       ind2 = find(query_arrplate_vars(ind,1) == i);
       qmat(all_querys(i),all_arrays(j))= nanmean(query_arrplate_vars(ind(ind2),4));
    end
    
end

backgd_mean = exp(amat_mean);
backgd_std = exp(sqrt(amat+qmat));  % upper/lower CI bound is backgd_mean*(backgd_std)^n OR backgd_mean/(backgd_std)^n where n is the number of std. dev. for normal cdf


qfit = repmat(final_smfit,1,length(complete_mat));

% To avoid removing real interactions, assume the query fitness is 1 if we
% don't have other fitness information. This will cause incorrectly scaled
% interactions but we have no way of dealing with this is we don't have SM
% fitness information.

qfit(isnan(qfit)) = 1;

afit = repmat(final_smfit',length(complete_mat),1);
qfit_std = repmat(final_smfit_std,1,length(complete_mat));
afit_std = repmat(final_smfit_std',length(complete_mat),1);

dm_expected = afit.*qfit;
ind = find(~isnan(model_fits(:,1)) & ~isnan(final_smfit(all_arrays)));
p = polyfit(final_smfit(all_arrays(ind)),model_fits(ind,1),1);
c = p(1);

eps = complete_mat .* (qfit/c);
eps_std = complete_mat_std.*(qfit/c);

dm_actual = dm_expected + eps;
dm_actual_std = eps_std;

quers = repmat((1:length(complete_mat))',1,length(complete_mat));
arrs = repmat((1:length(complete_mat)),length(complete_mat),1);

% Remove "undefined"
ind = strmatch('undefined',sgadata.orfnames);
complete_mat(ind,:)=NaN;
complete_mat(:,ind)=NaN;


%% Printing out

output_interaction_data([outputfile,'.txt'],sgadata.orfnames,complete_mat,complete_mat_std,backgd_mean,backgd_std,final_smfit,final_smfit_std,dm_expected,dm_actual,dm_actual_std);

%% Final save

save('-v7.3',[outputfile,'_matfile']);

