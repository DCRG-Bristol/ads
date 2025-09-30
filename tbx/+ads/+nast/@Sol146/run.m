function [binFolder] = run(obj,feModel,opts)
arguments
    obj
    feModel ads.fe.Component
    opts.StopOnFatal = false;
    opts.NumAttempts = 1;
    opts.BinFolder string = '';
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

% set Aero properties on feModel
feModel.AeroSettings.Velocity = obj.V;
feModel.AeroSettings.RefRho = obj.rho;
% export model
modelFile = string(fullfile(pwd,binFolder,'Source','Model','model.bdf'));
feModel.Export(modelFile);
% create gust cards
gustFile = string(fullfile(pwd,binFolder,'Source','gust.bdf'));
obj.write_gust(gustFile);

% extract SPC IDs
if ~isempty(feModel.Constraints)
    obj.SPCs = [feModel.Constraints.ID];
else
    obj.SPCs = [];
end

%create main BDF file
bdfFile = fullfile(pwd,binFolder,'Source','sol146.bdf');
obj.write_main_bdf(bdfFile,[modelFile,gustFile]);

% write the batch file if we were asked
if opts.createBat
    obj.writeJobSubmissionBat(binFolder);
end

%% Run Analysis
obj.executeNastran('sol146',opts.StopOnFatal,opts.NumAttempts,opts.cmdLineArgs);
end

