%%
% APPLY_SPATIAL_NORMALIZATION - corrects colony sizes for spatial effects
%
% Inputs:
%   sgadata - structure containing all the colony size data
%   field - the name of the field to use as input
%   ignore_cols - indices of colonies to ignore in this correction
%   plate_id_map - cell array of indices of colonies on each plate
%
% Outputs:
%   newdata - corrected colony sizes
%
% Authors: Chad Myers (cmyers@cs.umn.edu), Anastasia Baryshnikova (a.baryshnikova@utoronto.ca)
%
% Last revision: 2010-07-19
%
%%

function newdata = apply_spatial_normalization(sgadata,field,ignore_cols,plate_id_map)

    % Print the name and path of this script
    p = mfilename('fullpath');
    fprintf('\nSpatial correction script:\n\t%s\n\n',p);

    if ~exist('ignore_cols')
        ignore_cols = [];
    end
    
    % List of unique plateids
    all_plates = unique(sgadata.plateids);

    gausfilt = fspecial('gaussian',7,2);
    avgfilt = fspecial('average',9);
    
    newdata = sgadata.(field);
    
    olddata = newdata;
    olddata(ignore_cols) = NaN;
    
    fprintf(['Spatial normalization...\n|' blanks(50) '|\n|']);
    for i = 1:length(all_plates)
        
        % List of sgadata indices to this plate colonies
        ind = plate_id_map{all_plates(i)};
        
        % Array of sgadata indices to this plate colonies
        plate_map = zeros(32,48)+1;  % Default reference to 1st index
        plate_map_ref = zeros(32,48)-1;
        
        % Populate the array
        iii = sub2ind([32,48], sgadata.rows(ind), sgadata.cols(ind));
        
        plate_map(iii) = ind;
        plate_map_ref(iii) = ind;
        
        % Array of this plate colony sizes
        plate_mat = zeros(32,48) + NaN;
        plate_mat(:) = olddata(plate_map(:));
        
        % Fix the default reference to 1st index
        plate_mat(plate_map_ref < 0) = NaN;
        
        t = plate_mat;
        ind = find(isnan(t));   
        
        % Fill in Nans with smoothed version of neighbors
        t(ind) = nanmean(plate_mat(:));
        
        prefilt = imfilter(t,gausfilt,'replicate');
        t(ind) = prefilt(ind);
        
        filtered = medfilt2(t,[7,7]);
        filtered = imfilter(filtered,avgfilt,'replicate');
        
        
        f = (filtered(:)-nanmean(filtered(:)));
        newdata(plate_map(:)) = newdata(plate_map(:)) - f;
        
        plate_mat(:) = newdata(plate_map(:));
        
        % Print progress
        print_progress(length(all_plates),i);
        
    end 
    fprintf('|\n');
    
    %sgadata.logresidual_spatialnorm = newdata;
    %sgadata.residual_spatialnorm = exp(sgadata.logresidual_spatialnorm).*sgadata.arraymedian-sgadata.arraymedian;
    %newdata = sgadata.colsize_platenorm + (sgadata.residual_spatialnorm - sgadata.residual);
    