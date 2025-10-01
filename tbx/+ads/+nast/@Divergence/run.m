function [BinFolder] = run(obj,feModel,opts)
arguments
    obj ads.nast.Divergence
    feModel ads.fe.Component
    opts.BinFolder string = '';
    
    opts.StopOnFatal = false;
    opts.NumAttempts = 3;
    opts.cmdLineArgs struct = struct.empty;
end
%% create BDFs
BinFolder = obj.BuildBDFs(feModel,opts.BinFolder);

%create main BDF file
bdfFile = fullfile(pwd,BinFolder,'Source','sol144_div.bdf');
obj.write_main_bdf(bdfFile,[modelFile]);

%% Run Analysis
obj.executeNastran(BinFolder,opts.StopOnFatal,opts.NumAttempts,opts.cmdLineArgs);
end

