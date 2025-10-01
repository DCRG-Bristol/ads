function [BinFolder] = run(obj,feModel,opts)
arguments
    obj
    feModel ads.fe.Component
    opts.StopOnFatal = false;
    opts.NumAttempts = 1;
    opts.BinFolder string = '';
    opts.cmdLineArgs struct = struct.empty;
end

%% create BDFs
BinFolder = ads.nast.create_tmp_bin(opts.BinFolder);

%update boundary condition
obj.UpdateBCs();

% set Aero properties on feModel
feModel.AeroSettings.Velocity = obj.V;
feModel.AeroSettings.RefRho = obj.rho;
% export model
modelFile = string(fullfile(pwd,BinFolder,'Source','Model','model.bdf'));
feModel.Export(modelFile);
% create gust cards
gustFile = string(fullfile(pwd,BinFolder,'Source','gust.bdf'));
obj.write_gust(gustFile);

% extract SPC IDs and Force IDs
obj.ExtractIDs(feModel);

%create main BDF file
bdfFile = fullfile(pwd,BinFolder,'Source','sol146.bdf');
obj.write_main_bdf(bdfFile,[modelFile,gustFile]);

%% Run Analysis
obj.executeNastran(BinFolder,opts.StopOnFatal,opts.NumAttempts,opts.cmdLineArgs);
end

