function [data,binFolder] = run(obj,feModel,opts)
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
binFolder = ads.nast.create_tmp_bin('BinFolder',opts.BinFolder);

%update boundary condition
if ~isempty(obj.CoM) 
    if obj.isFree
        obj.CoM.ComponentNumbers = ads.nast.inv_dof(obj.DoFs);
        obj.CoM.SupportNumbers = obj.DoFs;
    else
        obj.CoM.ComponentNumbers = 123456;
        obj.CoM.SupportNumbers = [];
    end
end

% export model
modelFile = string(fullfile(pwd,binFolder,'Source','Model','model.bdf'));
feModel.Export(modelFile);

% extract SPC IDs
if ~isempty(feModel.Constraints)
    obj.SPCs = [feModel.Constraints.ID];
else
    obj.SPCs = [];
end
%create main BDF file
bdfFile = fullfile(pwd,binFolder,'Source','sol103.bdf');
obj.write_main_bdf(bdfFile,[modelFile]);

% write the batch file if we were asked
if opts.createBat
    obj.writeJobSubmissionBat(binFolder);
end

%% Run Analysis
obj.executeNastran('sol103',opts.StopOnFatal,opts.NumAttempts,opts.cmdLineArgs);

h5_file = mni.result.hdf5(fullfile(binFolder,'bin','sol103.h5'));
if opts.IncludeEigenVec
    data = h5_file.read_modeshapes();
else
    data = h5_file.read_modes();
end
end

