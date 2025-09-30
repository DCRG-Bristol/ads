function [binFolder] = run(obj,feModel,opts)
arguments
    obj
    feModel ads.fe.Component
    opts.BinFolder string = '';
    opts.StopOnFatal = false;
    opts.NumAttempts = 3;
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
%extract Forces
obj.ForceIDs = [];
if ~isempty(feModel.Forces)
    obj.ForceIDs = [obj.ForceIDs,reshape([feModel.Forces.ID],1,[])];
end
if ~isempty(feModel.Moments)
    obj.ForceIDs = [obj.ForceIDs,reshape([feModel.Moments.ID],1,[])];
end
%create main BDF file
bdfFile = fullfile(pwd,binFolder,'Source','sol101.bdf');
obj.write_main_bdf(bdfFile,[modelFile]);

%% Run Analysis
obj.executeNastran('sol101',opts.StopOnFatal,opts.NumAttempts,opts.cmdLineArgs);

end

