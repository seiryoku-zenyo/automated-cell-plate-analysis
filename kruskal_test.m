      
%Kruskal-Wallis test
function [statsMsg] = kruskal_test(statData, graph_panel, cur_grps, stats_panel)


delete(get(graph_panel,'Children'));
delete(findobj(stats_panel, 'tag', 'stats_table'));

s=1;
for sd = 1:length(statData);
    %group{sd} = statData(sd).groups;
    for sdd = 1:length(statData(sd).all_wells);
        dat(s) = statData(sd).all_wells(sdd);
        group{s} = statData(sd).groups;
        s = s + 1;
    end;  
end;

[p,tbl,stats] =anova1(dat, group);


kruskal_fig = gcf;
copyobj(gca,graph_panel);
close(kruskal_fig);
close('One-way ANOVA');

tb=cell2table(tbl);
uitable('Data',tb{:,:}, 'RowName',tb.Properties.RowNames, 'units', 'normalized', 'parent', stats_panel, 'Position',[.5 0 .5 1], 'tag', 'stats_table');



    if p<0.005
        statsMsg =(['WOW! P-Value of ' num2str(p) '! VERY SIGNIFICANT! Nobel prize?']);                                 
    elseif p<0.05
        statsMsg =(['P-Value of ' num2str(p) '! Probably SIGNIFICANT!']);                                
    else
        statsMsg =(['P-Value of ' num2str(p) '! Looks like no differences:(']);                          
    end;    