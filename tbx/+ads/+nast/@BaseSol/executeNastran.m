function executeNastran(obj,BinFolder,StopOnFatal,NumAttempts,cmdLineArgs,Name)
    arguments
        obj ads.nast.BaseSol
        BinFolder string
        StopOnFatal = false;
        NumAttempts = 3;
        cmdLineArgs struct = struct.empty;
        Name = obj.Name;
    end
    %% Run Analysis
attempt = 1;
while attempt<NumAttempts+1
    ads.Log.debug(['Computing ',Name]);
    % run NASTRAN
    current_folder = pwd;
    cd(fullfile(BinFolder,'Source'))
    % create command
    command = ads.nast.buildCommand([Name,'.bdf'],...
        cmdLineArgs=cmdLineArgs,Silent=true);
    % save the command to a bat file for repeat execution
    writelines(command,[Name,'.bat']);
    % execute the command    
    ads.Log.trace(['Nastran Started at: ',datestr(now, 'HH:MM:SS')]);
    tic;
    system(command);
    t = toc;
    ads.Log.trace(['Nastran completed in ',num2str(t),' seconds']);
    cd(current_folder);

    %get Results
    f06_filename = fullfile(BinFolder,'bin',[Name,'.f06']);
    f06_file = mni.result.f06(f06_filename);
    if f06_file.isEmpty
        if StopOnFatal
            error('ADS:Nastran','Fatal error detected in f06 file %s...',f06_filename)
        else
            attempt = attempt + 1;
            str = sprintf('%s is empty on attempt %.0f...\n',f06_filename,attempt);
            ads.Log.warn(str);
            continue           
        end
    elseif f06_file.isfatal
        if StopOnFatal
            error('ADS:Nastran','Fatal error detected in f06 file %s...',f06_filename)
        else
            attempt = attempt + 1;
            str = sprintf('Fatal error detected on attempt %.0f in f06 file %s... \n',attempt,f06_filename);
            ads.Log.warn(str);
            continue
        end
    else
        break % successful run
    end
end
if attempt > NumAttempts
    if StopOnFatal
        str = sprintf('Failed after %.0f attempts %s... STOPPING\n',NumAttempts,f06_filename);
        ads.Log.error(str);
        error('ADS:Nastran','Failed after %.0f attempts %s...',NumAttempts,f06_filename);
    else
        str = sprintf('Failed after %.0f attempts %s... CONTINUING\n',NumAttempts,f06_filename);
        ads.Log.warn(str);
    end
end