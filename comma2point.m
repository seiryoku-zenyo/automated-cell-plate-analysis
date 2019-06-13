                        
% This function reads into the text file which is using commas as decimal separators 
% and reinterprets the same data as having points/dots instead of commas, 
% conserving the original files as they were

function [data] = comma2point(filename)

    fin = fopen(filename);
    %fout = fopen(dyst_lamp_file,'r+');

    while ~feof(fin);
        s = fgetl(fin);
        s = strrep(s, '%','');
        %fprintf(fout,'%s',s);
        disp(s);
    end;

    fclose(fin);
    filedata=textscan(s, '%s');
    data = strrep(filedata{1,1}(6:24), ',', '.');
    
end
