function [statsMsg] = Mannu_test(statData, graph_panel, cur_grps, stats_panel)

    delete(get(graph_panel,'Children'));
    delete(findobj(stats_panel, 'tag', 'stats_table'));

    if length(statData) ~= 2;
        statsMsg = ['You need 2 groups in order to preform an Mann-Whitney U test. You have now selected ' num2str(length(statData)) ' group(s).'];
    else
        %Preform test
        [p,h, stats] = ranksum(statData(1).all_wells, statData(2).all_wells);
        stats;

        %Build table
%         tbl{:,1} = fieldnames(stats);
%         tbl{:,2} = num2cell(struct2cell(stats));
%         tbl(1,3) = {'conf.int.'};
%         tbl(2,3) = {cur_grps(1,1)};
%         tbl(3,3)= {num2cell(ci(1))};
%         tbl(1,4) = {'conf.int.'};
%         tbl(2,4) = {cur_grps(2,1)}; 
%         tbl(3,4)= {num2cell(ci(2))};
%         assignin('base','tbl', tbl);
%         tb=cell2table(tbl);
%         uitable('Data',tb{:,:}, 'RowName',tb.Properties.RowNames, 'units', 'normalized', 'parent', stats_panel, 'Position',[.5 0 .5 1], 'tag', 'stats_table');
        
        
        %Build normal data graph
        Y = [mean(statData(1).all_wells) mean(statData(2).all_wells)]; %Data

        stddev=[std(statData(1).all_wells),std(statData(2).all_wells)];
        error_matrix = vec2mat(stddev,2);

        xx=axes('parent', graph_panel,'Position', [.05 0.05 .905 .905]);
        hold 'on';
        colors = hsv(numel(Y));
        for i = 1:numel(Y)
            bar(i, Y(i), 'parent', xx, 'facecolor', colors(i,:));
        end;
        set(gca, 'XTick', 1:numel(Y), 'XTickLabel', cur_grps(:,1))
        errorbar(Y,error_matrix,'.black');
    
        if p<0.005 
            statsMsg = (['WOW! P-Value of ' num2str(p) '!   VERY SIGNIFICANT! Nobel prize?']); %'';''; ['\bf' GRP{1,1} '\rm' '  \itmean=' num2str(mean(GRP{1,2})) '; SD=' num2str(std(GRP{1,2})) '\rm'] ; ['\bf' GRP{2,1} '\rm' '  \itmean=' num2str(mean(GRP{2,2})) '; SD=' num2str(std(GRP{2,2})) '\rm']}, test, 'none', Opt);                             
        elseif p<0.05
            statsMsg = (['P-Value of ' num2str(p) '!   Probably SIGNIFICANT!']); %'';''; ['\bf' GRP{1,1} '\rm' '  \itmean=' num2str(mean(GRP{1,2})) '; SD=' num2str(std(GRP{1,2})) '\rm'] ; ['\bf' GRP{2,1} '\rm' '  \itmean=' num2str(mean(GRP{2,2})) '; SD=' num2str(std(GRP{2,2})) '\rm']}, test, 'none', Opt);
        else
            statsMsg = (['P-Value of ' num2str(p) '!   Looks like no differences :(']); %'';''; ['\bf' GRP{1,1} '\rm' '  \itmean=' num2str(mean(GRP{1,2})) '; SD=' num2str(std(GRP{1,2})) '\rm'] ; ['\bf' GRP{2,1} '\rm' '  \itmean=' num2str(mean(GRP{2,2})) '; SD=' num2str(std(GRP{2,2})) '\rm']}, test, 'none', Opt);          
        end;
    end;
end