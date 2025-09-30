function val = executeNastran(obj,name,StopOnFatal,NumAttempts,cmdLineArgs)
    arguments
        obj ads.nast.BaseSol
        name char
        StopOnFatal = false;
        NumAttempts = 3;
        cmdLineArgs struct = struct.empty;
    end
    %% Run Analysis
attempt = 1;
while attempt<NumAttempts+1
    ads.Log.info(['Computing ',obj.Name']);
    % run NASTRAN
    current_folder = pwd;
    cd(fullfile(binFolder,'Source'))
    % create command
    command = ads.nast.buildCommand([name,'.bdf'],...
        cmdLineArgs=cmdLineArgs,Silent=true);
    % save the command to a bat file for repeat execution
    writelines(command,[name,'.bat']);
    % execute the command    
    tic;
    system(command);
    t = toc;
    ads.Log.debug(['Completed in ',num2str(t),' seconds']);
    cd(current_folder);

    %get Results
    f06_filename = fullfile(binFolder,'bin',[name,'.f06']);
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