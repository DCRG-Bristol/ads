function BinFolder = run(obj,feModel,opts,sol144Opts)
arguments
    obj
    feModel

    opts.StopOnFatal = false;
    opts.NumAttempts = 3;
    opts.BinFolder string = '';
    opts.cmdLineArgs struct = struct.empty;

    sol144Opts.trimObjs = ads.nast.TrimParameter.empty;
    sol144Opts.OutputAeroMatrices logical = false;
end
obj.OutputAeroMatrices = sol144Opts.OutputAeroMatrices;

% add control surfaces to trim parameters
for i = 1:length(feModel.ControlSurfaces)
    cs = feModel.ControlSurfaces(i);
    sol144Opts.trimObjs(end+1) = ads.nast.TrimParameter(cs.Name,cs.Deflection,"Control Surface");
end
obj.trimObjs = sol144Opts.trimObjs;

% run analysis
optsCell = namedargs2cell(opts);
BinFolder = run@ads.nast.BaseSol(obj,feModel,optsCell{:});
end

