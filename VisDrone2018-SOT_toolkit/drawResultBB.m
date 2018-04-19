close all;
clear, clc;
warning off all;
addpath(genpath('.')); 

datasetPath = 'VisDrone2018-SOT-test-challenge\'; % the dataset path
trks = configTrackers; % the set of trackers

evalType = 'OPE'; % the evaluation types such as OPE, SRE and TRE
pathDraw = ['./tmp/' evalType '/'];% the folder that will stores the images with overlaid bounding box
rstIdx = 1; % the result index (1~20)
pathRes = ['.\results\results_' evalType '\']; % the folder containing the tracking results
seqs = configSeqs(fullfile(datasetPath,'sequences')); % the set of sequences

LineWidth = 2;
plotSetting;

lenTotalSeq = 0;
resultsAll = [];
trackerNames = [];
%% draw visual results for each sequence
for index_seq = 1:length(seqs)
    seq = seqs{index_seq};
    seq_name = seq.name;
    seq_length = seq.endFrame-seq.startFrame+1;
    lenTotalSeq = lenTotalSeq + seq_length;
    %% draw visual results of each tracker
    for index_algrm = 1:length(trks)
        algrm = trks{index_algrm};
        name = algrm.name;
        trackerNames{index_algrm} = name;
        % check the result format       
        res_mat = [pathRes seq_name '_' name '.mat'];
        if(~exist(res_mat, 'file'))
            res_txt = [res_mat s.name '.txt'];
            results = cell(1,1);
            results{1}.res = load(res_txt);
            results{1}.type = 'rect';
            results{1}.annoBegin = 1;
            results{1}.startFrame = 1;
            results{1}.len = size(results{1}.res, 1);
        else
            load(res_mat);
        end
        res = results{rstIdx};
        
        if(~isfield(res,'type') && isfield(res,'transformType'))
            res.type = res.transformType;
            res.res = res.res';
        end
            
        if strcmp(res.type,'rect')
            for i = 2:res.len
                r = res.res(i,:);               
                if(isnan(r) | r(3)<=0 | r(4)<=0)
                    res.res(i,:)=res.res(i-1,:);
                end
            end
        end
        resultsAll{index_algrm} = res;
    end
           
    pathSave = [pathDraw seq_name '_' num2str(rstIdx) '/'];
    if(~exist(pathSave,'dir'))
        mkdir(pathSave);
    end
    
    for i = 1:seq_length
        image_no = seq.startFrame + (i-1);
        id = sprintf(strcat('img%0',num2str(seq.nz),'d'), image_no);
        fileName = strcat(seq.path,'/',id,'.',seq.ext);       
        img = imread(fileName);        
        imshow(img);

        text(5, 20, ['#' id(4:end)], 'Color','y', 'FontWeight','bold', 'FontSize',24);
        
        for j = 1:length(trks)           
            LineStyle = plotDrawStyle{j}.lineStyle;
            
            switch resultsAll{j}.type
                case 'rect'
                    rectangle('Position', resultsAll{j}.res(i,:), 'EdgeColor', plotDrawStyle{j}.color, 'LineWidth', LineWidth,'LineStyle',LineStyle);
                case 'ivtAff'
                    drawbox(resultsAll{j}.tmplsize, resultsAll{j}.res(i,:), 'Color', plotDrawStyle{j}.color, 'LineWidth', LineWidth,'LineStyle',LineStyle);
                case 'L1Aff'
                    drawAffine(resultsAll{j}.res(i,:), resultsAll{j}.tmplsize, plotDrawStyle{j}.color, LineWidth, LineStyle);                    
                case 'LK_Aff'
                    [corner, c] = getLKcorner(resultsAll{j}.res(2*i-1:2*i,:), resultsAll{j}.tmplsize);
                    hold on,
                    plot([corner(1,:) corner(1,1)], [corner(2,:) corner(2,1)], 'Color', plotDrawStyle{j}.color,'LineWidth',LineWidth,'LineStyle',LineStyle);
                case '4corner'
                    corner = resultsAll{j}.res(2*i-1:2*i,:);
                    hold on,
                    plot([corner(1,:) corner(1,1)], [corner(2,:) corner(2,1)], 'Color', plotDrawStyle{j}.color,'LineWidth',LineWidth,'LineStyle',LineStyle);
                case 'SIMILARITY'
                    warp_p = parameters_to_projective_matrix(resultsAll{j}.type,resultsAll{j}.res(i,:));
                    [corner, c] = getLKcorner(warp_p, resultsAll{j}.tmplsize);
                    hold on,
                    plot([corner(1,:) corner(1,1)], [corner(2,:) corner(2,1)], 'Color', plotDrawStyle{j}.color,'LineWidth',LineWidth,'LineStyle',LineStyle);
                otherwise
                    disp('The type of output is not supported!')
                    continue;
            end
        end        
        imwrite(frame2im(getframe(gcf)), [pathSave  num2str(i) '.jpg']);
    end
    clf
end