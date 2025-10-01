function [res,BinFolder] = run(obj,feModel,opts)
arguments
    obj
    feModel ads.fe.Component
    opts.StopOnFatal = false;
    opts.NumAttempts = 3;
    opts.BinFolder string = '';
    opts.UseHdf5 = true;
    opts.cmdLineArgs struct = struct.empty;
end

%% create BDFs
BinFolder = ads.nast.create_tmp_bin(opts.BinFolder);

%update boundary condition
obj.UpdateBCs();

% export model
modelFile = string(fullfile(pwd,BinFolder,'Source','Model','model.bdf'));
feModel.Export(modelFile);

% create flutter cards
flutFile = string(fullfile(pwd,BinFolder,'Source','flutter.bdf'));
obj.write_flutter(flutFile);

% extract SPC IDs and Force IDs
obj.ExtractIDs(feModel);

%create main BDF file
bdfFile = fullfile(pwd,BinFolder,'Source','sol145.bdf');
obj.write_main_bdf(bdfFile,[modelFile,flutFile]);

%% Run Analysis
obj.executeNastran(BinFolder,opts.StopOnFatal,opts.NumAttempts,opts.cmdLineArgs);

if opts.UseHdf5
    h5_file = mni.result.hdf5(fullfile(BinFolder,'bin','sol145.h5'));
    res = h5_file.read_flutter_summary();
    res_vec = h5_file.read_flutter_eigenvector();
else
    f06_file = mni.result.f06(fullfile(BinFolder,'bin','sol145.f06'));
    res = f06_file.read_flutter();
    res_vec = f06_file.read_flutter_eigenvector();
end
%assign eigen vectors to modes if they equate
for i = 1:length(res_vec)
    [~,I] = min(abs([res.CMPLX]-res_vec(i).EigenValue));
    res(I).IDs = res_vec(i).IDs;
    res(I).EigenVector = res_vec(i).EigenVector;
end
end

