function println(fid,string)
%PRINTLN Print a string to a file
% calls fprintf(fid,'%s\n',string);
fprintf(fid,'%s\n',string);
end