function [outlier_msg, statsMsg] = normality_test(statData, graph_panel, cur_grps, stats_panel)      



delete(get(graph_panel,'Children'));
delete(findobj(stats_panel, 'tag', 'stats_table'));

xx=axes('parent', graph_panel,'Position', [.05 0.05 .45 .4]);
hold(xx, 'on');


colors = hsv(numel(statData));
for q = 1:length(statData);
    bar(q, mean(statData(q).all_wells), 'parent', xx, 'facecolor', colors(q,:));
    errorbar(q, mean(statData(q).all_wells), std(statData(q).all_wells),'.black');
end;
set(xx, 'XTick', 1:numel(statData), 'XTickLabel', cur_grps(:,1));
hold(xx, 'off');

%%Show distribution and normality graphs and statistical test results
%set(0, 'DefaultFigurePosition', [500         200         280         210])
xx=axes('parent', graph_panel,'Position', [.05 0.55 .45 .4]);
%figure('NumberTitle', 'off','name','Histogram (red is your data, green is gaussian)', 'parent', xx);
hold on;
hist=histfit(vertcat(statData.all_wells),length(vertcat(statData.all_wells)),'kernel'); 
set(hist(1)','facecolor','b', 'parent', xx)
%set(0, 'DefaultFigurePosition', [500         200         280         210])
hold on;
hist1=histfit(vertcat(statData.all_wells),length(vertcat(statData.all_wells)),'normal');
delete(hist1(1)); 
set(hist1(2),'color','g', 'parent', xx); 
set(hist(2),'color','r', 'parent', xx);
hold off
h_leg=legend ([hist1(2) hist(2)],'gaussian', 'your data','FontSize',5,'Location','best');
h_leg=legend ('boxoff');
set(h_leg,'FontSize',7);

%Normplot
xx=axes('parent', graph_panel,'Position', [.55 0.55 .45 .4]);
hold on;
normplot(vertcat(statData.all_wells));
%Boxplot
xx=axes('parent', graph_panel,'Position', [.55 0.05 .45 .4]);
boxplot(vertcat(statData.all_wells));

%Basic distribution test, obtain some p-value
[h,p] = lillietest (vertcat(statData.all_wells));
s=num2str(p);
    


%tb=cell2table(tbl);
%uitable('Data',tb{:,:}, 'RowName',tb.Properties.RowNames, 'units', 'normalized', 'parent', stats_panel, 'Position',[.5 0 .5 1], 'tag', 'stats_table');



%Give distribution statistic results for normality assessment.
if p>0.05
    statsMsg =(['Distribution can be considered NORMAL. Lilliefors test returned p=' s '. Vasco recommends continuing the analysis using PARAMETRIC tests.']);
elseif p<=0.05 && p>=0.01
    statsMsg =(['Lilliefors test returned a P-Value of ' s '. This means you should consider carefully not using PARAMETRIC tests, you should probably use NON-PARAMETRIC. Check your graphs before making a decison.']);              
elseif p<0.01
    statsMsg =(['Your P-Value is waaaaay low(p=' s '). This is NOT a normal distribution. You should definitely go for NON-PARAMETRIC tests!']);                        
end;


%Check for outliers in the data using the Interquartile Range method
outlier_msg = 'No outliers in this data set!';
    %Check for outliers in the data using the Interquartile Range method
    for sd = 1:length(statData);
        %active_outlier = 1;
        dataMean = mean(statData(sd).all_wells);
        quartiles{sd} = quantile(statData(sd).all_wells,[0.25,0.5,0.75]); %produce all 3 quartiles
        q1{sd} = quartiles{sd}(1); %Q1 or first quartile
        q3{sd} = quartiles{sd}(3); %Q3 or third quartile
        iqr{sd} = q3{sd}-q1{sd}; %Interquartile Range
        'outlier cutoff value is: '
        cutoff = 1.5*iqr{sd} %cutoff value. If there is a data value farther from the data mean than this, it is considered an outlier!

        %finding distances between each data point and the data mean. Creating an array
        %with these distances and the corresponding data points
        mean2pointDist = [];
        for dm = 1:length(statData(sd).all_wells);
            mean2pointDist{dm, 1} = statData(sd).all_wells(dm); %data point
            mean2pointDist{dm, 2} = abs(dataMean -(statData(sd).all_wells(dm))); %data point's distance to mean point
            mean2pointDist{dm, 3} = dm; %data point's index
            mean2pointDist{dm, 4} = statData(sd).groups; %name of experimental group
            assignin('base','mean2pointDist', mean2pointDist);
        end;
        
        %while active_outlier == 1;
            [curFarPoint, I] = max(cell2mat((mean2pointDist(:, 2)))) %finding the data point farthest away from the data mean
            if curFarPoint > cutoff %notifying user of existence of outliers
                mean2pointDist{I, 1}
                outlier_msg = 'You might have some outlier(s). Better inspect them, possibly remove them!'
                %mean2pointDist(I,:) = [];
                %assignin('base','mean2pointDist', mean2pointDist);
            else
                outlier_msg = 'This dataset currently has no outliers'
                %active_outlier = 0;       
            end;
        %end;
    end;