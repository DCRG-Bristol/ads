function BinFolder = build(obj, BinFolder)
%BUILD  Write AVL input files to disk.
%
%   BinFolder = build(avlModel, BinFolder)
%
%   Creates the folder structure:
%     <BinFolder>/
%       Source/
%         <Name>.avl
%       bin/            (empty, AVL writes results here)
%
%   Returns the absolute path to BinFolder.

arguments
    obj  ads.avl.AvlModel
    BinFolder (1,1) string = "";
end

%% Create folder structure
if BinFolder == ""
    BinFolder = string(fullfile(pwd, ['avl_', char(obj.Name)]));
end
BinFolder = ads.avl.resolveFolderPath(BinFolder);
sourceDir = fullfile(BinFolder, 'Source');
binDir    = fullfile(BinFolder, 'bin');
if ~exist(sourceDir, 'dir'), mkdir(sourceDir); end
if ~exist(binDir,    'dir'), mkdir(binDir);    end

%% Assemble .avl file text
lines = string.empty;

% --- Header ---
ref = obj.RefQuantities;
lines(end+1) = obj.Name;
lines(end+1) = "!";
lines(end+1) = sprintf("%.6g", obj.Opts.Mach);
iYsym = 0;
if obj.Opts.Symmetry
    iYsym = 1;
end
lines(end+1) = sprintf("%d     0     0.0", iYsym);
lines(end+1) = sprintf("%-12.6g  %-12.6g  %-12.6g  ! Sref  Cref  Bref", ...
    ref.Sref, ref.Cref, ref.Bref);
lines(end+1) = sprintf("%-12.6g  %-12.6g  %-12.6g  ! Xref  Yref  Zref", ...
    ref.Xref, ref.Yref, ref.Zref);
lines(end+1) = "";

% --- Surfaces ---
for i = 1:numel(obj.Surfaces)
    lines(end+1) = obj.Surfaces(i).Text;
    lines(end+1) = "";
end

% --- Bodies ---
if obj.Opts.IncludeBodies
    for i = 1:numel(obj.Bodies)
        lines(end+1) = obj.Bodies(i).Text;
        lines(end+1) = "";
    end
end

%% Write .avl file
avlFile = fullfile(sourceDir, [char(obj.Name), '.avl']);
fid = fopen(avlFile, 'w');
if fid < 0
    error('ads:avl:build', 'Cannot open file for writing: %s', avlFile);
end
for i = 1:numel(lines)
    fprintf(fid, '%s\n', char(lines(i)));
end
fclose(fid);

%% Optionally write .mass file
if obj.Opts.WriteMassFile && isfield(obj, 'MassText') && ~isempty(obj.MassText)
    massFile = fullfile(sourceDir, [char(obj.Name), '.mass']);
    fid = fopen(massFile, 'w');
    fprintf(fid, '%s\n', char(obj.MassText));
    fclose(fid);
end

end
