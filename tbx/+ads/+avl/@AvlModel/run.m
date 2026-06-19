function run(obj, BinFolder, opts)
%RUN  Execute AVL in batch mode and capture stability derivatives.
%
%   run(avlModel, BinFolder)
%   run(avlModel, BinFolder, alpha=5, beta=0)
%
%   Writes a command script to <BinFolder>/Source/<Name>.avl_cmd, then
%   calls AVL via the system shell with stdin redirected.
%
%   AVL output (forces & stability derivatives) is written to:
%     <BinFolder>/bin/<Name>_st.txt    (stability derivatives, ST command)
%
%   Prerequisites: the .avl file must already exist (call build first).
%
arguments
    obj      ads.avl.AvlModel
    BinFolder (1,1) string
    opts.alpha (1,1) double = 0;
    opts.beta  (1,1) double = 0;
end

BinFolder  = ads.avl.resolveFolderPath(BinFolder);
sourceDir  = fullfile(BinFolder, 'Source');
binDir     = fullfile(BinFolder, 'bin');
avlFile    = fullfile(sourceDir, [char(obj.Name), '.avl']);
cmdFile    = fullfile(sourceDir, [char(obj.Name), '.avl_cmd']);
stOutFile  = fullfile(binDir, [char(obj.Name), '_st.txt']);
ftOutFile  = fullfile(binDir, [char(obj.Name), '_ft.txt']);

if ~exist(avlFile, 'file')
    error('ads:avl:run', 'AVL input file not found: %s\nCall build() first.', avlFile);
end

% Remove stale output files to avoid AVL append/overwrite prompts in batch mode.
if exist(stOutFile, 'file')
    delete(stOutFile);
end
if exist(ftOutFile, 'file')
    delete(ftOutFile);
end

%% Write AVL command script
fid = fopen(cmdFile, 'w');
if fid < 0
    error('ads:avl:run', 'Cannot create command file: %s', cmdFile);
end

fprintf(fid, 'LOAD %s\n', avlFile);
fprintf(fid, 'OPER\n');
% set alpha
fprintf(fid, 'A A %g\n', opts.alpha);
% set beta
fprintf(fid, 'B B %g\n', opts.beta);
% initialise all control variables so AVL emits control derivatives (d1, d2, ...)
controlNames = localGetControlNames(obj);
for iCtrl = 1:numel(controlNames)
    fprintf(fid, 'D%d D%d 0\n', iCtrl, iCtrl);
end
% execute run case
fprintf(fid, 'X\n');
% write stability derivatives
fprintf(fid, 'ST\n');
fprintf(fid, '%s\n', stOutFile);
% write total forces
fprintf(fid, 'FT\n');
fprintf(fid, '%s\n', ftOutFile);
% exit menus
fprintf(fid, '\n');   % exit OPER
fprintf(fid, 'QUIT\n');
fclose(fid);

%% Run AVL
avlExe = char(obj.Opts.AvlExePath);
command = sprintf('"%s" < "%s"', avlExe, cmdFile);
[status, output] = system(command);

logFile = fullfile(binDir, [char(obj.Name), '_avl.log']);
fid = fopen(logFile, 'w');
fprintf(fid, '%s', output);
fclose(fid);

if status ~= 0
    error('ads:avl:run', ...
        'AVL returned non-zero exit code (%d). See log: %s', status, logFile);
end

end

% -------------------------------------------------------------------------
function controlNames = localGetControlNames(obj)
%LOCALGETCONTROLNAMES  Extract unique CONTROL names from AVL surface text.

controlNames = strings(0,1);
for iSurf = 1:numel(obj.Surfaces)
    txt = char(obj.Surfaces(iSurf).Text);
    tokens = regexp(txt, '(?m)^CONTROL\s*\n\s*([^\s]+)', 'tokens');
    if isempty(tokens)
        continue;
    end
    names = string(cellfun(@(t)t{1}, tokens, 'UniformOutput', false));
    controlNames = [controlNames; names(:)]; %#ok<AGROW>
end
controlNames = unique(controlNames, 'stable');

end
