function run(obj,BinFolder,opts)
    arguments
        obj ads.nast.BaseSol
        BinFolder string
        opts.StopOnFatal = true;
        opts.NumAttempts = 1;
        opts.cmdLineArgs struct = struct.empty;
        opts.BDFName = obj.Name;
    end
    %% Run Analysis
attempt = 1;
bdfname = opts.BDFName;
while attempt<opts.NumAttempts+1
    ads.Log.debug(['Computing ',bdfname]);
    % run NASTRAN
    current_folder = pwd;
    cd(fullfile(BinFolder,'Source'))
    % create command
    command = ads.nast.buildCommand([bdfname,'.bdf'],...
        cmdLineArgs=opts.cmdLineArgs,Silent=true);
    % save the command to a bat file for repeat execution
    writelines(command,[bdfname,'.bat']);
    % execute the command
    ads.Log.trace(['Nastran Started at: ',datestr(now, 'HH:MM:SS')]);
    tic;
    system(command);
    t = toc;
    ads.Log.debug(['Nastran completed in ',num2str(t),' seconds']);
    cd(current_folder);

    %get Results
    f06_filename = fullfile(BinFolder,'bin',[bdfname,'.f06']);
    f06_file = mni.result.f06(f06_filename);
    if f06_file.isEmpty
        if opts.StopOnFatal
            error('ADS:Nastran','Fatal error detected in f06 file %s...',f06_filename)
        else
            attempt = attempt + 1;
            str = [sprintf('%s is empty on attempt %.0f...',f06_filename,attempt),'\n'];
            ads.Log.warn(str);
            continue           
        end
    elseif f06_file.isfatal
        if opts.StopOnFatal
            error('ADS:Nastran','Fatal error detected in f06 file %s...',f06_filename)
        else
            attempt = attempt + 1;
            str = [sprintf('Fatal error detected on attempt %.0f in f06 file %s...',attempt,f06_filename),'\n'];
            ads.Log.warn(str);
            continue
        end
    else
        break % successful run
    end
end
if attempt > opts.NumAttempts
    if opts.StopOnFatal
        str = sprintf('Failed after %.0f attempts %s... STOPPING\n',opts.NumAttempts,f06_filename);
        ads.Log.error(str);
        error('ADS:Nastran','Failed after %.0f attempts %s...',opts.NumAttempts,f06_filename);
    else
        str = sprintf('Failed after %.0f attempts %s... CONTINUING\n',opts.NumAttempts,f06_filename);
        ads.Log.warn(str);
    end
end