function [BinFolder] = run(obj,feModel,opts)
arguments
    obj ads.nast.Sol144
    feModel ads.fe.Component
    opts.StopOnFatal = false;
    opts.NumAttempts = 3;
    opts.BinFolder string = '';
    opts.OutputAeroMatrices logical = false;
    opts.cmdLineArgs struct = struct.empty;
end
obj.OutputAeroMatrices = opts.OutputAeroMatrices;
%% create BDFs
BinFolder = ads.nast.create_tmp_bin(opts.BinFolder);

%update boundary condition
obj.UpdateBCs();

% export model
modelFile = string(fullfile(pwd,BinFolder,'Source','Model','model.bdf'));
feModel.Export(modelFile);

% add control surfaces to trim parameters
for i = 1:length(feModel.ControlSurfaces)
    cs = feModel.ControlSurfaces(i);
    opts.trimObjs(end+1) = ads.nast.TrimParameter(cs.Name,cs.Deflection,"Control Surface");
end

% create flutter cards
trimFile = string(fullfile(pwd,BinFolder,'Source','trim.bdf'));
obj.write_sol144_cards(trimFile,opts.trimObjs);

% extract SPC IDs and Force IDs
obj.ExtractIDs(feModel);

%create main BDF file
bdfFile = fullfile(pwd,BinFolder,'Source','sol144.bdf');
obj.write_main_bdf(bdfFile,[modelFile,trimFile]);

%% Run Analysis
obj.executeNastran(BinFolder,opts.StopOnFatal,opts.NumAttempts,opts.cmdLineArgs);
end

