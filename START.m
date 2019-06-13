%BCAA study 2009. Principal inversitigator is Heikki Kainulainen.
%This matlab script and associated functions aim to read, process, statistically analyze and display the data collected from the 12-well images with Image J.
%Writen by Vasco Fachada. 

if exist('data', 'var')~=1; %Only runs if there is no variable with the name "data" in the base workspace.

    clear; %Clearing any other unrelated variables in workspace that could interfere with the program
    
    %Prompt #1. Asking where the data to be analyzed is located
    main_folder = uigetdir(path,'Select the path containing all your plate folders, or select a "READY" folder for single plate analysis. It will work only if all plates have the same number of wells!');
    main_folder_cont = dir (main_folder);

    wells_tot_num = 0;
    n=1;
    for j=1:numel(main_folder_cont);
        if strfind(main_folder_cont(j).name, 'READY') > 0;
            plate{n} = main_folder_cont(j).name;
            n = n +1;
            if wells_tot_num == 0;
                curr_folder = [main_folder '\' main_folder_cont(j).name];
                curr_folder_cont = dir(curr_folder);
                for jj=1:numel(curr_folder_cont);
                    if strfind(curr_folder_cont(jj).name, 'BIN') > 0;
                        wells_tot_num = wells_tot_num+1; %Identifying how many wells per plate
                    end;
                end;
            end;
        end;
    end;
    
    if wells_tot_num == 1;
        'under construction'
    elseif wells_tot_num == 2;
        'under construction'
    elseif wells_tot_num == 4;
        'under construction'
    elseif wells_tot_num == 6;
        'under construction'
    elseif wells_tot_num == 12;
        wells(1,:)= {'WellID', 'X_Coord', 'Y_Coord'};
        wells(2:13,1)= {'A1', 'A2', 'A3', 'A4', 'B1', 'B2', 'B3', 'B4', 'C1', 'C2', 'C3', 'C4'};             %ID of wells to match their position in image
        wells(2:13,2)= {[6, 6, 28, 28, 6], [31, 31, 51, 51, 31], [52, 52, 72, 72, 52], [75, 75, 95, 95, 75], [6, 6, 28, 28, 6], [31, 31, 51, 51, 31], [52, 52, 72, 72, 52], [75, 75, 95, 95, 75], [6, 6, 28, 28, 6], [31, 31, 51, 51, 31], [52, 52, 72, 72, 52], [75, 75, 95, 95, 75]}; %X coordinates defining a saquare area corresponding to well position
        wells(2:13,3)= {[6, 36, 36, 6, 6], [6, 36, 36, 6, 6], [6, 36, 36, 6, 6], [6, 36, 36, 6, 6], [41, 66, 66, 41, 41], [41, 66, 66, 41, 41], [41, 66, 66, 41, 41], [41, 66, 66, 41, 41], [68, 94, 94, 68, 68], [68, 94, 94, 68, 68], [68, 94, 94, 68, 68], [68, 94, 94, 68, 68]}; %Y coordinates defining a saquare area corresponding to well position
    elseif wells_tot_num == 24;
        'under construction'
    elseif wells_tot_num == 96;
        'under construction'
    else
        'unknown well plate configuration'
    end;
    
    %Prompt #2. Asking how many experimental groups one has.
    prompt = {'How many experimental groups (including controls) do you have in total?'};
    title = 'Welcome to Viveca´s well-plate analyzer :)';
    dims = [1 70];
    definput = {'4'};
    answer = inputdlg(prompt, title, dims, definput);
    exp_grp_num = str2num(answer{1,1});
    
                
    %Prompt #3. Asking to which wells do those experimental groups correspond  
    first_GUI (wells, exp_grp_num, wells_tot_num, plate);
    
    %Building the main structure with the selected text/raw data produced
    %by Fiji
    i=1; %index for mainStruct and statStruct
    ix = 1; %index for labels/data_stddev etc
    for j=1:numel(main_folder_cont); %Finding the plate folder
        if strfind(main_folder_cont(j).name, 'READY') > 0;
            plate_mapping.ID{i} = main_folder_cont(j).name;
            mainStruct(i).plate_ID = plate_mapping.ID{i}; %Starting to fill in the main structure with current plate data
            curr_folder = [main_folder '\' main_folder_cont(j).name];
            curr_folder_cont = dir(curr_folder);
             
            w=1;
            for jj=1:numel(curr_folder_cont);
                if strfind(curr_folder_cont(jj).name, '.tsv') > 0;
                    mainStruct(i).wells(w).well_ID = wells{w+1}; %Starting to fill in the structure with current well data
                    %mainStruct(i).wells(w).ExpGroup = 'see "statStruct"';
                    
                    %Finding the number and name of the variables from the header of one of the tsv data files
                    fop = fopen([curr_folder '\' curr_folder_cont(jj).name]);
                    fileHeader = textscan(fop, '%s','Delimiter', {'\n'});
                    fileHeader = fileHeader{1,1}(1);
                    fileVars = textscan(fileHeader{1},'%s','delimiter','\t');
                    fileVars = fileVars{1}(3:2:length(fileVars{1}));
                    
                    subvarCount = 9;
                    for fv=1:length(fileVars);
                        
                        %Data measured by tiles (16 tiles per well)
                        tile_nr=1;
                        for jjj=1:length(dlmread([curr_folder '\' curr_folder_cont(jj).name], '\t', 'B3..B:'));
                            mainStruct(i).wells(w).(fileVars{fv})(jjj).tile_number = tile_nr;
                            mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} '_Mean']) = dlmread([curr_folder '\' curr_folder_cont(jj).name], '\t', [(1+jjj) subvarCount-8 (1+jjj) subvarCount-8]);
                            mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} '_Stdev']) = dlmread([curr_folder '\' curr_folder_cont(jj).name], '\t', [(1+jjj) subvarCount-7 (1+jjj) subvarCount-7]);
                            mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} '_Mode']) = dlmread([curr_folder '\' curr_folder_cont(jj).name], '\t', [(1+jjj) subvarCount-6 (1+jjj) subvarCount-6]);
                            mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} '_Median']) = dlmread([curr_folder '\' curr_folder_cont(jj).name], '\t', [(1+jjj) subvarCount-5 (1+jjj) subvarCount-5]);
                            mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} '_Fraction']) = dlmread([curr_folder '\' curr_folder_cont(jj).name], '\t', [(1+jjj) subvarCount-4 (1+jjj) subvarCount-4]);
                            mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} '_Number']) = dlmread([curr_folder '\' curr_folder_cont(jj).name], '\t', [(1+jjj) subvarCount-3 (1+jjj) subvarCount-3]);
                            mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} '_Size']) = dlmread([curr_folder '\' curr_folder_cont(jj).name], '\t', [(1+jjj) subvarCount-2 (1+jjj) subvarCount-2]);
                            mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} '_binFraction']) = dlmread([curr_folder '\' curr_folder_cont(jj).name], '\t', [(1+jjj) subvarCount-1 (1+jjj) subvarCount-1]);
                            
                            tile_nr = tile_nr+1;
                        end;
                        
                        %Data measured by wells (averaged from the 16
                        %wells)
                        mainStruct(i).wells(w).([(fileVars{fv}) '_Mean']) = mean([mainStruct(i).wells(w).(fileVars{fv})(:).([fileVars{fv} '_Mean'])]);
                        mainStruct(i).wells(w).([(fileVars{fv}) '_Stdev']) = mean([mainStruct(i).wells(w).(fileVars{fv})(:).([fileVars{fv} '_Stdev'])]);
                        mainStruct(i).wells(w).([(fileVars{fv}) '_Mode']) = mean([mainStruct(i).wells(w).(fileVars{fv})(:).([fileVars{fv} '_Mode'])]);
                        mainStruct(i).wells(w).([(fileVars{fv}) '_Median']) = mean([mainStruct(i).wells(w).(fileVars{fv})(:).([fileVars{fv} '_Median'])]);
                        mainStruct(i).wells(w).([(fileVars{fv}) '_Fraction']) = mean([mainStruct(i).wells(w).(fileVars{fv})(:).([fileVars{fv} '_Fraction'])]);
                        mainStruct(i).wells(w).([(fileVars{fv}) '_Number']) = mean([mainStruct(i).wells(w).(fileVars{fv})(:).([fileVars{fv} '_Number'])]);
                        mainStruct(i).wells(w).([(fileVars{fv}) '_Size']) = mean([mainStruct(i).wells(w).(fileVars{fv})(:).([fileVars{fv} '_Size'])]);
                        mainStruct(i).wells(w).([(fileVars{fv}) '_binFraction']) = mean([mainStruct(i).wells(w).(fileVars{fv})(:).([fileVars{fv} '_binFraction'])]);                        
                        
                        subvarCount = subvarCount+8;
                    end;
                    
                    %Normalizations by intensity, fraction and number of other
                    %variables
                    tile_nr=1; %first by tiles
                    for fv=1:length(fileVars);
                        for fvv=1:length(fileVars);
                            if fv ~= fvv; %This makes sure that a variable won't be normalized by itself, and only by the remaining ones
                                for jjj=1:length(dlmread([curr_folder '\' curr_folder_cont(jj).name], '\t', 'B3..B:'));
                                    mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} 'Mean_norm' fileVars{fvv} 'Int']) = mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} '_Mean'])/mainStruct(i).wells(w).(fileVars{fvv})(jjj).([fileVars{fvv} '_Mean']);
                                    mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} 'Mean_norm' fileVars{fvv} 'Num']) = mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} '_Mean'])/mainStruct(i).wells(w).(fileVars{fvv})(jjj).([fileVars{fvv} '_Number']);
                                    mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} 'Mean_norm' fileVars{fvv} 'Fract']) = mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} '_Mean'])/mainStruct(i).wells(w).(fileVars{fvv})(jjj).([fileVars{fvv} '_Fraction']);
                                    
                                    mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} 'Median_norm' fileVars{fvv} 'Int']) = mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} '_Median'])/mainStruct(i).wells(w).(fileVars{fvv})(jjj).([fileVars{fvv} '_Mean']);
                                    mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} 'Median_norm' fileVars{fvv} 'Num']) = mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} '_Median'])/mainStruct(i).wells(w).(fileVars{fvv})(jjj).([fileVars{fvv} '_Number']);
                                    mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} 'Median_norm' fileVars{fvv} 'Fract']) = mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} '_Median'])/mainStruct(i).wells(w).(fileVars{fvv})(jjj).([fileVars{fvv} '_Fraction']);
                                    
                                    mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} 'Number_norm' fileVars{fvv} 'Num']) = mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} '_Number'])/mainStruct(i).wells(w).(fileVars{fvv})(jjj).([fileVars{fvv} '_Number']);
                                    mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} 'Number_norm' fileVars{fvv} 'Fract']) = mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} '_Number'])/mainStruct(i).wells(w).(fileVars{fvv})(jjj).([fileVars{fvv} '_Fraction']);

                                    tile_nr = tile_nr+1;
                                end;
                                %then by wells
                                mainStruct(i).wells(w).([fileVars{fv} 'Mean_norm' fileVars{fvv} 'Int']) = mean([mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} 'Mean_norm' fileVars{fvv} 'Int'])]);
                                mainStruct(i).wells(w).([fileVars{fv} 'Mean_norm' fileVars{fvv} 'Num']) = mean([mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} 'Mean_norm' fileVars{fvv} 'Num'])]);
                                mainStruct(i).wells(w).([fileVars{fv} 'Mean_norm' fileVars{fvv} 'Fract']) = mean([mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} 'Mean_norm' fileVars{fvv} 'Fract'])]);
                                mainStruct(i).wells(w).([fileVars{fv} 'Median_norm' fileVars{fvv} 'Int']) = mean([mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} 'Median_norm' fileVars{fvv} 'Int'])]);
                                mainStruct(i).wells(w).([fileVars{fv} 'Median_norm' fileVars{fvv} 'Num']) = mean([mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} 'Median_norm' fileVars{fvv} 'Num'])]);
                                mainStruct(i).wells(w).([fileVars{fv} 'Median_norm' fileVars{fvv} 'Fract']) = mean([mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} 'Median_norm' fileVars{fvv} 'Fract'])]);
                                mainStruct(i).wells(w).([fileVars{fv} 'Number_norm' fileVars{fvv} 'Num']) = mean([mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} 'Number_norm' fileVars{fvv} 'Num'])]);
                                mainStruct(i).wells(w).([fileVars{fv} 'Number_norm' fileVars{fvv} 'Fract']) = mean([mainStruct(i).wells(w).(fileVars{fv})(jjj).([fileVars{fv} 'Number_norm' fileVars{fvv} 'Fract'])]);
                            end;
                        end;    
                    end;
                    
                    %Colocalization
                    if w<2; %run this only once, during the first time and write all the colocalization variables at once
                        wW=1;
                        for jb=1:numel(curr_folder_cont);
                            if strfind(curr_folder_cont(jb).name, 'coloc') > 0;
                                %Reading the file and breaking it into pieces, getting
                                %the values out and cleaning the data from commas,
                                %strings etc
                                colDat = fopen(([curr_folder '\' curr_folder_cont(jb).name]));
                                fileHeader = textscan(colDat, '%s','Delimiter', {'\n'});
                                varsValue = fileHeader{1,1}(3);
                                varsValue = textscan(varsValue{1},'%s','delimiter','\t');
                                varsValue = varsValue{1}(3:length(varsValue{1}));
                                varsValue=strrep(varsValue,',','.');
                                varsValue=strrep(varsValue,'%','');
                                varsName = fileHeader{1,1}(3);
                                varsName = textscan(varsName{1},'%s','delimiter','\t');
                                varsName = varsName{1}(1);
                                varsName=strrep(varsName,'&','');
                                varsName=strrep(varsName,'coloc-','');
                                %varsName=strrep(varsName,' ','');
                                varsName = textscan(varsName{1},'%s','delimiter',' ');
                                var_A = varsName{1}(1);
                                var_A = var_A{1};
                                var_B = varsName{1}(3);
                                var_B = var_B{1};

                                %writting the data for the respective well
                                mainStruct(i).wells(wW).([var_A 'vs' var_B '_tManders']) = str2num(varsValue{4});
                                mainStruct(i).wells(wW).([var_B 'vs' var_A '_tManders']) = str2num(varsValue{5});
                                mainStruct(i).wells(wW).([var_A 'vs' var_B '_IntPerc']) = abs(str2num(varsValue{12}));
                                mainStruct(i).wells(wW).([var_B 'vs' var_A '_IntPerc']) = abs(str2num(varsValue{13})); 
                                wW=wW+1;
                            end;
                        end;
                    end;
                    
                    %Function that goes through the "grouping" and "mainStruct" structures and reorganizes the data by experimental groups for data analysis
                    [groupName, groupContent, gN, gC] = groupMapping(mainStruct, grouping, w, i); 
                    if groupName ~= 0;
                        statStruct(i).Plate_ID = plate_mapping.ID{i}; %Starting to fill in the structure for statistics
                        statStruct(i).Content(gN).ExperimGroup = groupName; %Giving group name to statistical sub-structure
                        statStruct(i).Content(gN).wells(gC-1) = groupContent;      %Giving content to specific structure
                    end;
                    w=w+1; 
                end;   
            end;
           
            statStruct(i).Content = statStruct(i).Content(~cellfun(@isempty,{statStruct(i).Content.wells})); %Getting ride of empty spaces in the structure
            
            if w>1;              
                cur_var = ([(fileVars{fv}) '_Mean']);
                for ii=1:length(statStruct(i).Content);
                    data(ix) = mean([statStruct(i).Content(ii).wells(:).(cur_var)]);
                    labels(ix) = ({statStruct(i).Content(ii).ExperimGroup});
                    stddev(ix) = std([statStruct(i).Content(ii).wells(:).(cur_var)]);
                    ix = ix+1;
                end;                                  
            end; 
            i=i+1;
        end;    
    end; 
 end;   



cur_test = 'No statistics preformed.';
cur_case = 'wells';
stats_res = sprintf(['Current variable: ' cur_var '.\n' cur_test '.\n']);


%The following arrays are meant for the scroll down options within the graphic output 
statsArray = {'no stats for now', 'Check distribution','2 sample T-student', 'Mann-Whitney U', 'One-way ANOVA', 'Kruskal-Wallis H'};
groupsArray = labels(:);
varsArray = fieldnames(statStruct(1).Content(1).wells);
varsArray = varsArray(3:length(varsArray));
caseArray = { 'wells', 'tiles', 'plates', 'cells', 'particles'};

scrnsz=get(0,'ScreenSize');
set(0, 'DefaultUIControlPosition',[1,1,scrnsz(3)*.65,scrnsz(4)], 'DefaultUIControlFontsize', 11); %Main Figure window
fHand = figure('Name', mainStruct(1).plate_ID,'NumberTitle','off'); 


%Left small panel for experimental group ticking selection
groups_panel = uipanel(fHand,'Visible','on',...
                  'Units', 'normalized',...
                  'Position',[.005 .705 .245 0.3]);
                 
      uicontrol(groups_panel, 'Style', 'text',...
                   'String', {'Experimental groups to include:'},...
                   'Units', 'normalized',...
                   'Position', [.1 .73 .6 .2]); 
               for gA=1:length(groupsArray);
      groupsAns(gA) = uicontrol(groups_panel, 'Style', 'checkbox',...
                   'String', groupsArray(gA),...
                   'Value', 1,...
                   'Units', 'normalized',...
                   'Position', [.1 (.75/length(groupsArray)*0.8)*gA .6 .1],'background','green',...
                   'ForegroundColor',[1 0 .3],...
                   'BackgroundColor',[.85 .85 .85],...
                   'HandleVisibility','on'); 
               end;
              
              

%Left big panel for scroll down options
option_panel = uipanel(fHand,'Visible','on',...
                  'Units', 'normalized',...
                  'Position',[.005 .1 .245 0.6]);
              
    %optPanAxis = axes('Parent', option_panel);
    
    
    
                    uicontrol(option_panel, 'Style', 'text',...
                   'String', {'Preform statistics:'},...
                   'Units', 'normalized',...
                   'Position', [.1 .155 .6 .2]);
         statsAns = uicontrol(option_panel, 'Style', 'popup',...
                   'String', statsArray,...
                   'Units', 'normalized',...
                   'Position', [.1 .16 .6 .1],'background','green',...
                   'ForegroundColor',[1 0 .3],...
                   'Tag', 'statsArray(statsAns.Value)',...
                   'BackgroundColor',[.85 .85 .85],...
                   'HandleVisibility','on');
 
               
                    uicontrol(option_panel, 'Style', 'text',...
                   'String', {'Statistical cases:'},...
                   'Units', 'normalized',...
                   'Position', [.1 .455 .6 .2]);               
         caseAns = uicontrol(option_panel, 'Style', 'popup',...
                   'String', caseArray,...
                   'Units', 'normalized',...
                   'Position', [.1 .46 .6 .1],'background','green',...
                   'ForegroundColor',[1 0 .3],...
                   'Tag', 'statTest',...
                   'BackgroundColor',[.85 .85 .85],...
                   'HandleVisibility','on');  
          
               
                    uicontrol(option_panel, 'Style', 'text',...
                   'String', {'Choose Variable:'},...
                   'Units', 'normalized',...
                   'Position', [.1 .755 .6 .2]);               
         varsAns = uicontrol(option_panel, 'Style', 'popup',...
                   'String', varsArray,...   
                   'Units', 'normalized',...
                   'Position', [.1 .76 .6 .1],'background','green',...
                   'ForegroundColor',[1 0 .3],...
                   'Tag', 'statTest',...
                   'BackgroundColor',[.85 .85 .85],...
                   'HandleVisibility','on');              
  
               
               
%Right bottom panel for graphic output
graph_panel = uipanel(fHand,'Visible','on',...
                  'Position',[.25 0 .75 .85],...
                  'Units', 'normalized');
              
              %Make figure
r = 4;
t = sum(data);
d = abs(data(1)-data(2));
Hi = (max(data) + (max(stddev)));
Lo = (Hi - (r*d));

aHand = axes('parent', graph_panel);
hold(aHand, 'on');
colors = hsv(numel(data));
for q = 1:numel(data)
    bar(q, data(q), 'parent', aHand, 'facecolor', colors(q,:));
end;
set(gca, 'XTick', 1:numel(data), 'XTickLabel', labels);
errorbar(data,stddev,'.black');
%aHand('Border','tight');


%Right upper panel for statistical output
stats_panel = uipanel(fHand,'Visible','on',...
                  'Position',[.25 .85 .75 .15],...
                  'Units', 'normalized');
      stats_disp = uicontrol(stats_panel, 'Style', 'text',...
                   'String', {stats_res},...
                   'Units', 'normalized',...
                   'Position', [.01 0 .5 1]);
      outlier_disp = uicontrol(stats_panel, 'Style', 'text',...
                   'String', 'Start by checking the sample distribtion',...
                   'Units', 'normalized',...
                   'Position', [.5 0 .5 1]);
      outliers_ans = uibuttongroup(stats_panel,'Visible','on',...
                  'Position',[.51 .1 .4 .45],...
                  'SelectionChangedFcn',@bselection);
      
      
      oo1 = uicontrol(outliers_ans, 'Style', 'checkbox',...
                    'FontSize', 6,...
                    'String', 'remove outliers (IQR method)',...
                    'Units', 'normalized',...
                    'Position', [.05 .02 1 .3],...
                    'HandleVisibility','on');
                
      oo2 = uicontrol(outliers_ans, 'Style', 'checkbox',...
                    'FontSize', 7,...
                    'String', 'remove outliers (Z-score method)',...
                    'Units', 'normalized',...
                    'Position', [.05 .5 1 .4],...
                    'HandleVisibility','on');



%Left button panel for runnig statistical analysis
button_panel = uipanel(fHand,'Visible','on',...
                  'Units', 'normalized',...
                  'Position',[.005 0 .245 0.1]);
                  uicontrol(button_panel, 'Style', 'pushbutton',...
                   'FontSize', 14,...
                   'String', 'Run',...
                   'Units', 'normalized',...
                   'Position', [.3 .3 .2 .5],...
                   'ForegroundColor',[.5 .5 .5],...
                   'Tag', 'statTest',...
                   'BackgroundColor',[.85 .85 .85],...
                   'HandleVisibility','off',... 
                   'Callback', {@second_GUI, statStruct, groupsAns, groupsArray, varsAns, varsArray, caseAns, caseArray, statsAns, statsArray, aHand, graph_panel, stats_disp, outlier_disp, stats_panel, fileVars, outliers_ans, oo1, oo2});
              
              

           


