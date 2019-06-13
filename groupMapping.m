function [groupName, groupContent, gN, gC] = groupMapping (mainStruct, grouping, w, i)
    for g=1:length({grouping.Description});
        for gg=2:numel(grouping(g).Wells(:,4));             
            if strcmp(grouping(g).Plate_ID, mainStruct(i).plate_ID) == 1 && strcmp(grouping(g).Wells(gg,4), mainStruct(i).wells(w).well_ID) == 1;
                groupName = grouping(g).Description;
                groupContent = mainStruct(i).wells(w);
                
                %"gN" and "gC" need to be created within this "if" and sent to the main script
                %because the index variables "g" and "gg" keep running
                %outside this "if" and when sent to the main script they
                %return the max index value instead of the corresponding
                %value found by the "if" statement
                gN = g;
                gC = gg;
            end;
        end;
    end;
     if exist ('groupName', 'var') == 0;
        groupName = 0;
        groupContent = 0;
        gN = 0;
        gC = 0;
     end;
end