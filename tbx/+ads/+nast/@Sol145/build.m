function BinFolder = build(obj,feModel,BinFolder)
arguments
    obj
    feModel
    BinFolder string = '';
end

% Update Aero properties on feModel
feModel.AeroSettings.Velocity = abs(obj.V(1));
feModel.AeroSettings.RefRho = obj.rho(1);

% run analysis
BinFolder = build@ads.nast.BaseSol(obj,feModel,BinFolder);
end

