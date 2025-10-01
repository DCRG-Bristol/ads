function restart(obj,BinFolder,cards,opts)
arguments
    obj ads.nast.Sol144
    BinFolder string
    cards mni.printing.cards.BaseCard = mni.printing.cards.BaseCard.empty;
    opts.Silent = true;
    opts.TruelySilent = false;
    opts.StopOnFatal = false;
    opts.NumAttempts = 3;
    opts.OutputAeroMatrices logical = false;
    opts.UseHdf5 = true;
    opts.cmdLineArgs struct = struct.empty;
end
obj.OutputAeroMatrices = opts.OutputAeroMatrices;
%% create BDFs
if ~isdir(BinFolder)
    error('ADS:Nastran','The provided BinFolder does not exist: %s',BinFolder)
end

% create restart file
filename = fullfile(BinFolder,'Source','sol144_restart.bdf');
fid = fopen(filename,"w");
mni.printing.bdf.writeFileStamp(fid);
mni.printing.bdf.writeHeading(fid,'This file contains the restart cards for a 144 solution');
println(fid,'RESTART, VERSION=1, KEEP');
obj.write_case_control(fid);
mni.printing.bdf.writeHeading(fid,'Begin Bulk');
println(fid,'BEGIN BULK');
for i = 1:length(cards)
    cards(i).writeToFile(fid);
end
fclose(fid);

%% Run Analysis
obj.executeNastran(BinFolder,opts.StopOnFatal,opts.NumAttempts,opts.cmdLineArgs,'sol144_restart');
end

