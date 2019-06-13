


function second_GUI (source, event, statStruct, groupsAns, groupsArray, varsAns, varsArray, caseAns, caseArray, statsAns, statsArray, aHand, graph_panel, stats_disp, outlier_disp, stats_panel, fileVars, outliers_ans, oo1, oo2)

cur_var = varsArray(varsAns.Value);
for cr=1:length(fileVars);
    if strfind(cur_var{1}, fileVars(cr)) == 1;
        gen_var = fileVars{cr}; %general variable for analysis with tiles as statistical cases
    end;
end;
cur_case = caseArray(caseAns.Value);
cur_test = statsArray(statsAns.Value);

%finding which group(s) have been selected for analysis
ij=1;
for i=1:length(groupsAns);
    if groupsAns(i).Value == 1;
       cur_grps(ij,1) = groupsAns(i).String;
       for g=1:length(statStruct);
            for gg=1:length(statStruct(g).Content);
                if strcmp(cur_grps(ij,1), statStruct(g).Content(gg).ExperimGroup) == 1;
                    cur_grps(ij,2) = {ij};     
                end;
            end;
        end;
        ij = ij+1;
    end;
end;  
%assignin('base','cur_grps', cur_grps);

%This piece of code reads out the input from the GUI and rearranges a new structure with the selected groups and respective selected variable data 
for iz=1:length(cur_grps(:,1));
    statData(:,iz).groups = cur_grps{iz};
    for jz=1:length(statStruct);
        for kz=1:length(statStruct(jz).Content);
           if strcmp(statData(:,iz).groups, statStruct(jz).Content(kz).ExperimGroup) == 1;
                switch cur_case{1};
                    case {'wells'};    
                        statData(:,iz).(['plate' num2str(jz)]) = [statStruct(jz).Content(kz).wells(:).(cur_var{1})]'; %wells as statistical cases, for each plate
                    case {'tiles'};
                        statData(:,iz).(['plate' num2str(jz)]) = []';
                        for nz=1:length(statStruct(jz).Content(kz).wells);
                            statData(:,iz).(['plate' num2str(jz)]) = vertcat(statData(:,iz).(['plate' num2str(jz)]), [statStruct(jz).Content(kz).wells(nz).(gen_var)(:).(cur_var{1})]');
                        end;
                    case 'cells';
                    case 'plates';
                    case 'particles';
                end;
            end;
        end;
    end;

    fn = fieldnames(statData);
    en = fn(2:length(fn)); %existing plates

    for k=1:length(en);
        tempArray{k} = statData(iz).(en{k});
    end;
    
    statData(:,iz).all_wells = vertcat(tempArray{:}); %statiscal cases for all plates of each gorup!
    assignin('base','statData', statData);
end;



%Determine if the outlier (if any exists) should be removed from statData
if oo1.Value == 1 && oo2.Value == 1
    'No outliers calculated. Select only one option.'
elseif oo1.Value == 1 || oo2.Value == 1
    statData = transform_data (statData, oo1, oo2);
    assignin('base','statData', statData);        
end;

 


%Make figure
%r = 4;
%t = sum(statData);
%d = abs(data(1)-statData);
%Hi = (max(statData) + (max(stddev)));
%Lo = (Hi - (r*d));


delete(get(graph_panel,'Children'));
aHand = axes('parent', graph_panel);
hold(aHand, 'on');

colors = hsv(numel(statData));
for q = 1:length(statData);
    bar(q, mean(statData(q).all_wells), 'parent', aHand, 'facecolor', colors(q,:));
    errorbar(q, mean(statData(q).all_wells), std(statData(q).all_wells),'.black');
end;
set(gca, 'XTick', 1:numel(statData), 'XTickLabel', cur_grps(:,1));
hold(aHand, 'off');


switch cur_test{1}
    case {'no stats for now'}
        stats_disp.String = cur_test;
    case {'Check distribution'}        
        [outlier_msg, statsMsg] = normality_test(statData, graph_panel, cur_grps, stats_panel);
        stats_disp.String = [cur_test statsMsg];
        outlier_disp.String = outlier_msg;   
    case {'2 sample T-student'}
        statsMsg = t_test(statData, graph_panel, cur_grps, stats_panel);
        stats_disp.String = [cur_test statsMsg];
    case {'Mann-Whitney U'}
        statsMsg = MannU_test(statData, graph_panel, cur_grps, stats_panel);
        stats_disp.String = [cur_test statsMsg];
    case {'One-way ANOVA'}
        [statsMsg] = anova_test(statData, graph_panel, cur_grps, stats_panel);
        stats_disp.String = [cur_test statsMsg];
    case {'Kruskal-Wallis H'}
        [statsMsg] = kruskal_test(statData, graph_panel, cur_grps, stats_panel);
        stats_disp.String = [cur_test statsMsg];      
end;
% 
% function statData = remove_outliers (statData)
% 
%     dp=1;
%     %Check for outliers in the data using the Interquartile Range method
%     for sd = 1:length(statData);
%         active_outlier = 1;
%         while active_outlier == 1;
%             dataMean = mean(statData(sd).all_wells);
%             quartiles{sd} = quantile(statData(sd).all_wells,[0.25,0.5,0.75]); %produce all 3 quartiles
%             q1{sd} = quartiles{sd}(1); %Q1 or first quartile
%             q3{sd} = quartiles{sd}(3); %Q3 or third quartile
%             iqr{sd} = q3{sd}-q1{sd}; %Interquartile Range
%             'outlier cutoff value is: '
%             cutoff{sd} = 1.5*iqr{sd} %cutoff value. If there is a data value farther from the data mean than this, it is considered an outlier!
% 
%             %finding distances between each data point and the data mean. Creating an array
%             %with these distances and the corresponding data points
%             for dm = 1:length(statData(sd).all_wells);
%                 mean2pointDist{dm, 1} = statData(sd).all_wells(dm); %data point
%                 mean2pointDist{dm, 2} = abs(dataMean -(statData(sd).all_wells(dm))); %data point's distance to mean point
%                 mean2pointDist{dm, 3} = dm; %data point's index
%                 mean2pointDist{dm, 4} = statData(sd).groups; %name of experimental group
%                 %assignin('base','mean2pointDist', mean2pointDist);
%             end;
%         %while active_outlier == 1;
%             [curFarPoint, I] = max(cell2mat((mean2pointDist(:, 2)))) %finding the data point farthest away from the data mean
%             if curFarPoint > cutoff{sd} %deleting the data point in case it is in fact an outlier
%                 ['Data point ' num2str(mean2pointDist{I, 1}, 4) ' from ' mean2pointDist{I, 4} ' is an outlier and is now deleted']
%                 delDataPts(dp,:) = mean2pointDist(I,:);
%                 mean2pointDist(I,:) = [];
%                 statData(sd).all_wells = cell2mat(mean2pointDist(:, 1));
%                 assignin('base','mean2pointDist', mean2pointDist);
%                 assignin('base','delDataPts', delDataPts);
%                 dp = dp+1;
%             else
%                 active_outlier = 0;
%                 mean2pointDist = [];
%                 assignin('base','mean2pointDist', mean2pointDist);
%             end;
%         end;
%     end;
%     'There are no more outliers'
% end

end
