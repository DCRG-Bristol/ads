function [BinFolder] = run(obj,feModel,opts)
arguments
    obj
    feModel ads.fe.Component
    opts.BinFolder string = '';
    
    opts.StopOnFatal = false;
    opts.NumAttempts = 3;
    opts.cmdLineArgs struct = struct.empty;
end
% update solution properties and boundary condition
obj.UpdateBCs();
obj.ExtractIDs(feModel);

% create Folder Structure
BinFolder = ads.nast.create_tmp_bin(opts.BinFolder);

% export model to BDF
modelFile = string(fullfile(pwd,BinFolder,'Source','Model','model.bdf'));
feModel.Export(modelFile);

% create main BDF file
bdfFile = fullfile(pwd,BinFolder,'Source',[obj.Name,'.bdf']);
obj.write_main_bdf(bdfFile,[modelFile]);

%% Run Analysis
obj.executeNastran(BinFolder,opts.StopOnFatal,opts.NumAttempts,opts.cmdLineArgs);
end

