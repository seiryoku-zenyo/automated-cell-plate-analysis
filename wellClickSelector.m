function demoOnImageClick (wells, plate_IMG, descr_ans, plates_ans, plate, ep, wells_tot_num, exp_grp_num, exp_grp_fig)


    hAxes = axes();
    imageHandle = plate_IMG;
    click_count = 1;
    circ = [];
    set(imageHandle,'ButtonDownFcn',@ImageClickCallback);

    
function ImageClickCallback (objectHandle , eventData)
    
    axesHandle  = get(objectHandle,'Parent');
    coordinates = get(axesHandle,'CurrentPoint'); 
    coordinates = coordinates(1,1:2);

    relXCoord = (coordinates(1)*100)/axesHandle.XLim(2); %Relative positions. Will allow coordinates to be readable indenpendently of the image size.
    relYCoord = (coordinates(2)*100)/axesHandle.YLim(2); %Relative positions. Will allow coordinates to be readable indenpendently of the image size.

% the hard part - assign points to base
    if evalin('base', 'exist(''grouping'',''var'')')
        grouping = evalin('base','grouping');
    else
        for i=1:exp_grp_num;
            grouping(i).Description = 'empty';
            grouping(i).Plate_ID = 'empty';                % add the plate ID with a function
            grouping(i).Wells{1,1} = 'Experimental Group'; % add headers
            grouping(i).Wells{1,2} = 'X';                  % add headers
            grouping(i).Wells{1,3} = 'Y';                  % add headers
            grouping(i).Wells{1,4} = 'Well_ID';            % add headers
            %grouping(i).Wells{2,1} = 'empty';              % add the experimental group number
            %grouping(i).Wells{2,2} = 'empty';              % add the X coordinate
            %grouping(i).Wells{2,3} = 'empty';              % add the Y coordinate
            %grouping(i).Wells{2,4} = 'empty';              % add the well ID with a function
        end;
    end

    
    circ{click_count} = viscircles(axesHandle,[coordinates(1) coordinates(2)],75); % draws a circle on the well figure 
    
     for pl = 1:length(plate);
         if plates_ans(pl).Value == 1;
             plateID = plate{pl};
         end;
     end;
    
    grouping(ep).Description = descr_ans.String;                         % add the experimental group description 
    grouping(ep).Plate_ID = plateID;                                     % add the Plate ID
    grouping(ep).Wells{click_count+1,1} = plateID;                       % add the experimental group number
    grouping(ep).Wells{click_count+1,2} = relXCoord;                     % add the X coordinate
    grouping(ep).Wells{click_count+1,3} = relYCoord;                     % add the Y coordinate
    grouping(ep).Wells{click_count+1,4} = checkID;                       % add the well ID with a function

    assignin('base','grouping', grouping);                               % save to base

    
    function [wellID] = checkID % This function finds the well ID to which the user selected by clicking it
        click_count = click_count + 1; %Click counter
        for id=2:wells_tot_num+1;
            in = inpolygon(relXCoord, relYCoord,[wells{id,2}],[wells{id,3}]); %returns 1 if point (relXCoord, relYCoord) is contained in respective well
            if in == 1;
                wellID = wells{id,1};
            end;
        end;
        if exist('wellID', 'var') == 0;
            wellID = 'IDless';
            'Seems you are not clicking within any well. Improve your aim or contact a doctor, Parkinson´s is common nowadays'
            undo;
        end
    end
    
    
    set (0, 'DefaultUIControlFontSize', 12-(0.8*exp_grp_num));
              %SUBMIT button
              undo_button = uicontrol(exp_grp_fig,'Style','pushbutton',...
                  'String','undo',...
                  'Units', 'normalized',...
                  'Position',[.05 .5 .1 .9/(exp_grp_num)],...
                  'ForegroundColor',[.5 .5 .5],...
                  'Tag', 'submit',...
                  'HandleVisibility','off',...
                  'Callback', {@undo});
              
    set (0, 'DefaultUIControlFontSize', 12-(0.8*exp_grp_num));
              %SUBMIT button
              clear_button = uicontrol(exp_grp_fig,'Style','pushbutton',...
                  'String','Clear',...
                  'Units', 'normalized',...
                  'Position',[.05 .2 .1 .9/(exp_grp_num)],...
                  'ForegroundColor',[.5 .5 .5],...
                  'Tag', 'submit',...
                  'HandleVisibility','off',...
                  'Callback', {@clearAll});
        
     
    
    function undo (hObject,eventdata) %This function deletes of the previous drawn circle from the figure and deletes of the respective point data from the grouping.Wells array 
        if click_count > 1;
            click_count = click_count-1;
            delete (circ{click_count});
            grouping(ep).Wells(click_count+1,:) = [];  % delete whole row of array
            assignin('base','grouping', grouping);         % save to base
        end;
    end

    function clearAll (hObject,eventdata) %This function deletes all the drawn circles from the figure and deletes of the respective point data from the grouping.Wells array
        for z=1:length(circ);
            delete(circ{z})
        end;
        grouping(ep).Wells(:,:) = [];
        click_count = 1; %click count needs to be equal to at least 1 at the start of the function
        assignin('base','grouping', grouping); % save to base
        assignin('base','circ', circ);
    end
    
    
end

axis off ;
end