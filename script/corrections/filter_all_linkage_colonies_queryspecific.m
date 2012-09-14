%%
% FILTER_ALL_LINKAGE_COLONIES_QUERYSPECIFIC - generates the list of colonies affected by linkage
%
% Inputs:
%   sgadata - structure containing all the colony size data
%   linkagefile - the name of the file containing the coordinates of the linkage windows
%
% Outputs:
%   all_linkage_cols - indices of the colonies affected by linkage
%
% Authors: Chad Myers (cmyers@cs.umn.edu), Anastasia Baryshnikova (a.baryshnikova@utoronto.ca)
%
% Last revision: 2010-07-19
%
%%

function all_linkage_cols = filter_all_linkage_colonies_queryspecific(sgadata, linkagefile)

    % Print the name and path of this script
    p = mfilename('fullpath');
    fprintf('\nLinkage filter script:\n\t%s\n\n',p);
    
    % Load chromosomal coordinates
    chromdata = importdata('chrom_coordinates.txt');
    orfs_coords = chromdata.textdata;
    chrom_coords = [chromdata.data(:,1),chromdata.data(:,2),chromdata.data(:,3)];

    all_linkage_cols = []; 
    linkage_dist = 200e3;   % default linkage distance
    
    % Load query-specific linkage
    %lnkg = importdata(linkagefile);
    [lnkg.textdata, lnkg.data(:,1), lnkg.data(:,2)] = textread(linkagefile,'%s %d %d');
    lnkg.data = [min(lnkg.data(:,1), lnkg.data(:,2)), max(lnkg.data(:,1), lnkg.data(:,2))];
    linkage_reg = zeros(length(sgadata.orfnames),2) - 1;
    [t,ind1,ind2] = intersect(sgadata.orfnames, lnkg.textdata);
    linkage_reg(ind1,:) = lnkg.data(ind2,:);

    % If no query-specific linkage info is available, assume 200 kb.
    all_querys = unique(sgadata.querys);
    ind = find(linkage_reg(all_querys,1) < 0);
    fprintf('No linkage info for these queries (200 kb have to be assumed):\n');
    fprintf('%s\n', sgadata.orfnames{all_querys(ind)});
    
    fprintf('No coordinate info for these queries:\n');
    for i = 1:length(ind)
        t = strmatch(sgadata.orfnames_ref{all_querys(ind(i))}, orfs_coords, 'exact');
        if isempty(t)
            fprintf('%s\n', sgadata.orfnames{all_querys(ind(i))});
            continue;
        end
        linkage_reg(all_querys(ind(i)),:) = [max(chrom_coords(t,2)-linkage_dist,1),chrom_coords(t,3)+linkage_dist];
    end


    % URA3 linkage (WT-specific)
    t = get_linked_ORFs('YEL021W', orfs_coords, linkage_dist, chrom_coords);
    [int,ia,ib] = intersect(t, sgadata.orfnames);
    ura3_linkage_cols = find(ismember(sgadata.arrays,ib) & ismember(sgadata.querys,strmatch('undefined',sgadata.orfnames)));
    
    % LYP1 linkage
    t = get_linked_ORFs('YNL268W', orfs_coords, linkage_dist, chrom_coords);
    [int,ia,ib] = intersect(t, sgadata.orfnames);
    lyp1_linkage_cols = find(ismember(sgadata.arrays,ib));
    
    % CAN1 linkage
    t = get_linked_ORFs('YEL063C', orfs_coords, linkage_dist, chrom_coords);
    [int,ia,ib] = intersect(t, sgadata.orfnames);
    can1_linkage_cols = find(ismember(sgadata.arrays,ib));

    all_linkage_cols = [all_linkage_cols; ura3_linkage_cols; lyp1_linkage_cols; can1_linkage_cols];
    
    exp_linkage_cols = [];
    
    fprintf(['Mapping query-specific linkage...\n|', blanks(50), '|\n|']);
    y = 0;
    
    for i = 1:length(all_querys)
        
        curr_chrom = findstr(sgadata.orfnames{all_querys(i)}(2), 'ABCDEFGHIJKLMNOP');
        if isempty(curr_chrom)
            if ~strcmp('undefined',sgadata.orfnames{all_querys(i)})
                fprintf('Could not get a chromosome # for this orf: %s\n', sgadata.orfnames{all_querys(i)});
            end
            continue;
        end
        
        % Get query-specific linked ORFs (= a set of ORFs that start or end within the linkage region)
        indt = find(chrom_coords(:,1) == curr_chrom);
        lnkg_reg = linkage_reg(all_querys(i),:);
        indtt = find((min(chrom_coords(indt,2:3),[],2) >= min(lnkg_reg) & min(chrom_coords(indt,2:3),[],2) < max(lnkg_reg)) | ...
        (max(chrom_coords(indt,2:3),[],2) >= min(lnkg_reg) & max(chrom_coords(indt,2:3),[],2) < max(lnkg_reg)));
        t = orfs_coords(indt(indtt));
        
        [int,ia,ib] = intersect(t, sgadata.orfnames);
                
        curr_inds = find(ismember(sgadata.arrays,ib) & sgadata.querys == all_querys(i));
        exp_linkage_cols = [exp_linkage_cols; curr_inds];
        
        % Print progress
        x = fix(i * 50/length(all_querys));
        if x > y
            fprintf('*')
            y = x;
        end
    end
    fprintf('|\n');

    all_linkage_cols = [all_linkage_cols; exp_linkage_cols];



       

        
