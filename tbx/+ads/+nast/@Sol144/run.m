function [binFolder] = run(obj,feModel,opts)
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

% add control surfaces to trim parameters
for i = 1:length(feModel.ControlSurfaces)
    cs = feModel.ControlSurfaces(i);
    opts.trimObjs(end+1) = ads.nast.TrimParameter(cs.Name,cs.Deflection,"Control Surface");
end

% create flutter cards
trimFile = string(fullfile(pwd,binFolder,'Source','trim.bdf'));
obj.write_sol144_cards(trimFile,opts.trimObjs);

% extract SPC IDs
if ~isempty(feModel.Constraints)
    obj.SPCs = [feModel.Constraints.ID];
else
    obj.SPCs = [];
end
%extract Forces
obj.ForceIDs = [];
if ~isempty(feModel.Forces)
    obj.ForceIDs = [obj.ForceIDs,[feModel.Forces.ID]'];
end
if ~isempty(feModel.Moments)
    obj.ForceIDs = [obj.ForceIDs,[feModel.Moments.ID]'];
end
%create main BDF file
bdfFile = fullfile(pwd,binFolder,'Source','sol144.bdf');
obj.write_main_bdf(bdfFile,[modelFile,trimFile]);

% write the batch file if we were asked
if opts.createBat
    obj.writeJobSubmissionBat(binFolder);
end

%% Run Analysis
obj.executeNastran('sol144',opts.StopOnFatal,opts.NumAttempts,opts.cmdLineArgs);
end

function println(fid,string)
fprintf(fid,'%s\n',string);
end

