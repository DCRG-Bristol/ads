function [binFolder] = run(obj,feModel,opts)
arguments
    obj ads.nast.Sol144
    feModel ads.fe.Component
    opts.Silent = true;
    opts.StopOnFatal = false;
    opts.NumAttempts = 3;
    opts.BinFolder string = '';
    opts.OutputAeroMatrices logical = false;
end

%% create BDFs
binFolder = ads.nast.create_tmp_bin('BinFolder',opts.BinFolder);
% export model
modelFile = string(fullfile(pwd,binFolder,'Source','Model','model.bdf'));
feModel.Export(modelFile);
% create flutter cards
trimFile = string(fullfile(pwd,binFolder,'Source','trim.bdf'));
obj.write_sol144_cards(trimFile);

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
obj.write_main_bdf(bdfFile,[modelFile,trimFile],'OutputAeroMatrices',opts.OutputAeroMatrices);

%% Run Analysis
attempt = 1;
while attempt<opts.NumAttempts+1
    % run NASTRAN
    current_folder = pwd;
    cd(fullfile(binFolder,'Source'))
    fprintf('Computing sol144 for Model %s: %.0f velocities ...',...
        obj.Name,length(obj.V));
    nastran_exe = 'C:\MSC.Software\MSC_Nastran\2022.1\bin\nastran.exe';
    % nastran_exe = 'C:\MSC.Software\MSC_Nastran\20181\bin\nastran.exe';
    command = [nastran_exe,...
        ' ','sol144.bdf',...
        ' ',sprintf('out=..%s%s%s',filesep,'bin',filesep)];
    if opts.Silent
        command = [command,' ','1>NUL 2>NUL'];
    end
    tic;
    system(command);
    toc;
    cd(current_folder);
    %get Results
    f06_filename = fullfile(binFolder,'bin','sol144.f06');
    f06_file = mni.result.f06(f06_filename);
    if f06_file.isEmpty
        attempt = attempt + 1;
        fprintf('%s is empty on attempt %.0f...\n',f06_filename,attempt)
        continue
    elseif f06_file.isfatal
        if opts.StopOnFatal
            error('Fatal error detected in f06 file %s...',f06_filename)
        else
            attempt = attempt + 1;
            fprintf('Fatal error detected on attempt %.0f in f06 file %s... \n',attempt,f06_filename)
            continue
        end
    else
        break
    end
end
if attempt > opts.NumAttempts
    fprintf('Failed after %.0f attempts %s... STOPPING\n',opts.NumAttempts,f06_filename)
    error('Failed after %.0f attempts %s...',opts.NumAttempts,f06_filename)
end
% data = f06_file.read_disp;
% p_data = f06_file.read_aeroP;
% f_data = f06_file.read_aeroF;
end

