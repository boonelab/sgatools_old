%%
% OUTPUT_INTERACTION_DATA - prints out the calculated genetic interactions into a tab delimited text file.
%
%
% Inputs:
%
% Authors: Chad Myers (cmyers@cs.umn.edu), Anastasia Baryshnikova (a.baryshnikova@utoronto.ca)
%
% Last revision: 2010-07-19
%
%%

function output_interaction_data(outputfile,orfnames,escores,escores_std,background_mean,background_std,smfit,smfit_std,dm_expected,dm_actual,dm_actual_std)

pvals = sqrt(normcdf(-abs(escores./escores_std)) .* normcdf(-abs(log((background_mean + escores)./background_mean) ./ log(background_std) )));

fprintf(['Printing output file...\n|' blanks(50) '|\n|']);

fid = fopen(outputfile,'w');
for i = 1:length(escores)
    for j = 1:length(escores)
        if ~isnan(escores(i,j))
              fprintf(fid,'%s\t%s\t%f\t%f\t%e\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n', ...
                  orfnames{i}, orfnames{j}, escores(i,j), escores_std(i,j), pvals(i,j), ...
                  smfit(i), smfit_std(i), smfit(j), smfit_std(j), ...
                  dm_expected(i,j), dm_actual(i,j), dm_actual_std(i,j));
        end
    end
    
    % Print progress
    print_progress(length(escores), i);
    
end
fclose(fid);

fprintf('|\n');