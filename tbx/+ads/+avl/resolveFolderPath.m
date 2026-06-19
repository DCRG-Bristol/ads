function folder = resolveFolderPath(folder)
%RESOLVEFOLDERPATH  Convert a relative folder to an absolute path.

arguments
    folder (1,1) string
end

if ~java.io.File(char(folder)).isAbsolute()
    folder = string(fullfile(pwd, folder));
end

end