%%
% APPLY_ROWCOL_NORMALIZATION - corrects colony sizes for row/column effects
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

function newdata = apply_rowcol_normalization(sgadata,field,ignore_cols,plate_id_map)

    % Print the name and path of this script
    p = mfilename('fullpath');
    fprintf('\nRow/column correction script:\n\t%s\n\n',p);

    if ~exist('ignore_cols')
        ignore_cols=[];
    end

    currdata = sgadata.(field);
    newdata = currdata;
    currdata(ignore_cols) = NaN;

    % List of unique plateids
    curr_plates = unique(sgadata.plateids);
    
    fprintf(['Row/column correction...\n|' blanks(50) '|\n|']);
    for i = 1:length(curr_plates)
        
        ind = plate_id_map{curr_plates(i)};
   
        ind3 = find(~isnan(currdata(ind)));
        ind4 = find(isnan(currdata(ind)));
        
        % Smooth across columns
        [v,ind2]=sort(sgadata.cols(ind(ind3)),'ascend');      
        win_size = length(find(v <= 6));
        
        if win_size > 0
            lowsmoothed = smooth(double(sgadata.cols(ind(ind3(ind2)))),currdata(ind(ind3(ind2))),win_size,'lowess');
        else
            lowsmoothed = currdata(ind(ind3(ind2)));
        end  
        %mp = [double(sgadata.cols(ind(ind3(ind2)))) currdata(ind(ind3(ind2))) lowsmoothed]
        
        
        %error('x')
        %[sgadata.cols(ind(ind3(ind2))) currdata(ind(ind3(ind2)))]
        
        %PLOT
        %newdata(ind(ind3(ind2)))=newdata(ind(ind3(ind2)))./(lowsmoothed./nanmean(lowsmoothed));
        %scatter(sgadata.cols(ind(ind3(ind2))), currdata(ind(ind3(ind2))));
        %hold on
        %plot(sgadata.cols(ind(ind3(ind2))),lowsmoothed,'Color','red','LineWidth',3);
        %plot(sgadata.cols(ind(ind3(ind2))),lowsmoothed/mean(lowsmoothed),'Color','blue','LineWidth',1);
        %error('x')
        
        
        % Put the ignored values back
        val_hash = zeros(1,48) + NaN;
        
        [a,ai] = unique(sgadata.cols(ind(ind3(ind2))));
        val_hash(a) = lowsmoothed(ai);
       
        for j = 1:length(ind4)
            if isnan(val_hash(sgadata.cols(ind(ind4(j)))))
                continue;
            end
            newdata(ind(ind4(j))) = newdata(ind(ind4(j)))./(val_hash(sgadata.cols(ind(ind4(j))))./nanmean(lowsmoothed));
        end
   
        % Smooth across rows
        tmpdata = newdata;
        tmpdata(ignore_cols) = NaN;
   
        [v,ind2]=sort(sgadata.rows(ind(ind3)),'ascend');
        win_size = length(find(v <= 6 ));
        
        if win_size > 0
            lowsmoothed = smooth(double(sgadata.rows(ind(ind3(ind2)))),tmpdata(ind(ind3(ind2))),win_size,'rlowess');
        else
            lowsmoothed = tmpdata(ind(ind3(ind2)));
        end
   
        newdata(ind(ind3(ind2)))=newdata(ind(ind3(ind2)))./(lowsmoothed./nanmean(lowsmoothed));
   
        % Put the ignored values back
        val_hash = zeros(1,32) + NaN;
        [a,ai] = unique(sgadata.rows(ind(ind3(ind2))));
        val_hash(a) = lowsmoothed(ai);
   
        for j = 1:length(ind4)
            if isnan(val_hash(sgadata.rows(ind(ind4(j)))))
                continue;
            end
            newdata(ind(ind4(j))) = newdata(ind(ind4(j)))./(val_hash(sgadata.rows(ind(ind4(j))))./nanmean(lowsmoothed));
        end
        
        %%%%%%%%%%
        % Array of sgadata indices to this plate colonies
        plate_map = zeros(32,48)+1; 
        % Populate the array
        iii = sub2ind([32,48], sgadata.rows(ind), sgadata.cols(ind));
        
        plate_map(iii) = ind;
        
        % Array of this plate colony sizes
        plate_mat = zeros(32,48) + NaN;
        plate_mat(:) = newdata(plate_map(:));
        
        if(i == 4)
            figure(1)
            imagesc(plate_mat)
            colormap(copper)
            error('x')
        end
        % Print progress
        print_progress(length(curr_plates), i);
        
    end
    
    fprintf('|\n');

