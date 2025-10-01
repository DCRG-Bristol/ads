function [data,BinFolder] = run(obj,feModel,opts)
arguments
    obj
    feModel ads.fe.Component
    opts.StopOnFatal = false;
    opts.NumAttempts = 3;
    opts.BinFolder string = '';
    opts.IncludeEigenVec = true;
    opts.cmdLineArgs struct = struct.empty;
end

%% create BDFs
BinFolder = ads.nast.create_tmp_bin(opts.BinFolder);

%update boundary condition
obj.UpdateBCs();

% export model
modelFile = string(fullfile(pwd,BinFolder,'Source','Model','model.bdf'));
feModel.Export(modelFile);

% extract SPC IDs and Force IDs
obj.ExtractIDs(feModel);

%create main BDF file
bdfFile = fullfile(pwd,BinFolder,'Source','sol103.bdf');
obj.write_main_bdf(bdfFile,[modelFile]);
%% Run Analysis
obj.executeNastran(BinFolder,opts.StopOnFatal,opts.NumAttempts,opts.cmdLineArgs);

h5_file = mni.result.hdf5(fullfile(BinFolder,'bin','sol103.h5'));
if opts.IncludeEigenVec
    data = h5_file.read_modeshapes();
else
    data = h5_file.read_modes();
end
end

