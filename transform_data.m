function [statData] = transform_data (statData, oo1, oo2)

if oo2.Value == 1
    %Check for outliers in the data using the Interquartile Range method
    for sd = 1:length(statData);
        dataMean = mean(statData(sd).all_wells);
        dataStd = std(statData(sd).all_wells);
        active_outlier = 1;
        while active_outlier == 1;
            
            
            %finding distances between each data point and the data mean. Creating an array
            %with these distances and the corresponding data points
            for dm = 1:length(statData(sd).all_wells);
                DataPoints{dm, 1} = statData(sd).all_wells(dm); %data point
                DataPoints{dm, 2} = dm; %data point's index
                DataPoints{dm, 3} = statData(sd).groups; %name of experimental group
                DataPoints{dm, 4} = abs(dataMean -(statData(sd).all_wells(dm))); %distance to mean value
                %assignin('base','mean2pointDist', mean2pointDist);
            end;
            
            [maxDataPoint, I] = max(cell2mat(DataPoints(:, 4)));
            outlierTestRes = abs((DataPoints{I, 1}-dataMean)/dataStd);
            DataPoints{I, 1};

            if outlierTestRes > 3;
                ['The data point ' num2str(DataPoints{I, 1}) ' from ' DataPoints{I, 3} ' is an outlier and is now removed from the dataset.']
                DataPoints(I, :) = [];
                statData(sd).all_wells = cell2mat(DataPoints(:, 1));
            else
                active_outlier = 0;
                DataPoints = [];
            end;
        end;
    end;
    
elseif oo1.Value == 1
        dp=1;
    %Check for outliers in the data using the Interquartile Range method
    for sd = 1:length(statData);
        active_outlier = 1;
        while active_outlier == 1;
            dataMean = mean(statData(sd).all_wells);
            quartiles{sd} = quantile(statData(sd).all_wells,[0.25,0.5,0.75]); %produce all 3 quartiles
            q1{sd} = quartiles{sd}(1); %Q1 or first quartile
            q3{sd} = quartiles{sd}(3); %Q3 or third quartile
            iqr{sd} = q3{sd}-q1{sd}; %Interquartile Range
            'outlier cutoff value is: '
            cutoff{sd} = 1.5*iqr{sd} %cutoff value. If there is a data value farther from the data mean than this, it is considered an outlier!

            %finding distances between each data point and the data mean. Creating an array
            %with these distances and the corresponding data points
            for dm = 1:length(statData(sd).all_wells);
                mean2pointDist{dm, 1} = statData(sd).all_wells(dm); %data point
                mean2pointDist{dm, 2} = abs(dataMean -(statData(sd).all_wells(dm))); %data point's distance to mean point
                mean2pointDist{dm, 3} = dm; %data point's index
                mean2pointDist{dm, 4} = statData(sd).groups; %name of experimental group
                %assignin('base','mean2pointDist', mean2pointDist);
            end;
        %while active_outlier == 1;
            [curFarPoint, I] = max(cell2mat((mean2pointDist(:, 2)))) %finding the data point farthest away from the data mean
            if curFarPoint > cutoff{sd} %deleting the data point in case it is in fact an outlier
                ['Data point ' num2str(mean2pointDist{I, 1}, 4) ' from ' mean2pointDist{I, 4} ' is an outlier and is now deleted']
                delDataPts(dp,:) = mean2pointDist(I,:);
                mean2pointDist(I,:) = [];
                statData(sd).all_wells = cell2mat(mean2pointDist(:, 1));
                assignin('base','mean2pointDist', mean2pointDist);
                assignin('base','delDataPts', delDataPts);
                dp = dp+1;
            else
                active_outlier = 0;
                mean2pointDist = [];
                assignin('base','mean2pointDist', mean2pointDist);
            end;
        end;
    end;
    'There are no more outliers'
    
    
end;