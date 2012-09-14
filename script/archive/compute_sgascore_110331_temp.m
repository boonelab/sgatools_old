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
    
    % Added back (11-03-31)
    curr_data(ind2) = curr_data(ind2) + (nanmean(sgadata.(field)(all_ind(ind2))) - (p(1)*final_smfit(sgadata.querys(all_ind(ind2)))+p(2)));
    
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
    
    % Added back (11-03-31)
    res = adjust_model_fit(query_effects, query_effects_std);
    query_effects(1) = query_effects(1) + res;
    query_effects(2:end) = query_effects(2:end) - res;
    
   
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