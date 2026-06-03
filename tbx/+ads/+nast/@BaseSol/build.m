function [BinFolder] = build(obj,feModel,BinFolder)
arguments
    obj
    feModel ads.fe.Component
    BinFolder string = '';
end
% update solution properties and boundary condition
obj.UpdateBCs();
obj.ExtractIDs(feModel);

% create Folder Structure
BinFolder = ads.nast.create_tmp_bin(BinFolder);

% Update Aero properties on feModel
feModel.AeroSettings.Velocity = obj.V(1);
feModel.AeroSettings.RefRho = obj.rho(1);

% export model to BDF
modelFile = string(fullfile(pwd,BinFolder,'Source','Model','model.bdf'));
feModel.Export(modelFile);

% create main BDF file
bdfFile = fullfile(pwd,BinFolder,'Source',[obj.Name,'.bdf']);
obj.write_main_bdf(bdfFile,[modelFile],feModel);
end
