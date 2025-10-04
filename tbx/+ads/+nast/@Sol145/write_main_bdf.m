function write_main_bdf(obj,filename,includes,feModel)
arguments
    obj
    filename string
    includes (:,1) string
    feModel ads.fe.Component
end
    fid = fopen(filename,"w");
    println(fid,'ECHOOFF');
    mni.printing.bdf.writeFileStamp(fid)
    %% Case Control Section
    mni.printing.bdf.writeComment(fid,'This file contain the main cards + case control for a 145 solution')
    mni.printing.bdf.writeHeading(fid,'Case Control');
    mni.printing.bdf.writeColumnDelimiter(fid,'8');
    println(fid,'NASTRAN NLINES=999999');
    println(fid,'SOL 145');
    println(fid,'TIME 10000');
    println(fid,'CEND');
    println(fid,'ECHOOFF');
    println(fid,'ECHO=NONE');
    mni.printing.bdf.writeHeading(fid,'Case Control')
    println(fid,sprintf('SDAMP = %.0f',obj.SDAMP_ID));
    println(fid,sprintf('FMETHOD = %.0f',obj.FlutterID));
    println(fid,sprintf('METHOD = %.0f',obj.EigR_ID));
    fprintf(fid,'SPC=%.0f\n',obj.SPC_ID);

    obj.Outputs.WriteToFile(fid);
    obj.writeGroundCheck(fid);

    println(fid,'MONITOR = ALL');
    println(fid,'AEROF=ALL');
    println(fid,'APRES=ALL');
    mni.printing.bdf.writeHeading(fid,'Begin Bulk')
    %% Bulk Data
    println(fid,'BEGIN BULK')
    % include files
    for i = 1:length(includes)
        mni.printing.cards.INCLUDE(includes(i)).writeToFile(fid);
    end
    % generic options 
    mni.printing.cards.PARAM('POST','i',0).writeToFile(fid);
    mni.printing.cards.PARAM('AUTOSPC','s','YES').writeToFile(fid);
    mni.printing.cards.PARAM('GRDPNT','i',0).writeToFile(fid);
    mni.printing.cards.PARAM('BAILOUT','i',-1).writeToFile(fid);
    mni.printing.cards.PARAM('OPPHIPA','i',1).writeToFile(fid);
    mni.printing.cards.PARAM('AUNITS','r',0.1019716).writeToFile(fid);
    mni.printing.cards.MDLPRM('HDF5','i',0).writeToFile(fid);

    %write Boundary Conditions
    mni.printing.bdf.writeComment(fid, 'SPCs')
    mni.printing.cards.SPCADD(obj.SPC_ID,obj.SPCs).writeToFile(fid);
    
    %create eigen solver and frequency bounds
    mni.printing.bdf.writeComment(fid,'Eigen Decomposition Method')
    mni.printing.bdf.writeColumnDelimiter(fid,'8');
    mni.printing.cards.EIGR(obj.EigR_ID,'MGIV','F1',0,...
         'F2',obj.FreqRange(2),'NORM','MAX')...
         .writeToFile(fid);
%     mni.printing.cards.EIGR(10,'MGIV','ND',42,'NORM','MAX')...
%         .writeToFile(fid);

    % define frequency / modes of interest
    mni.printing.bdf.writeComment(fid,'Frequencies and Modes of Interest')
    mni.printing.bdf.writeColumnDelimiter(fid,'8');
    mni.printing.cards.PARAM('LMODES','i',obj.LModes).writeToFile(fid);
    mni.printing.cards.PARAM('LMODESFL','i',obj.LModes).writeToFile(fid);
    mni.printing.cards.PARAM('LFREQ','r',obj.FreqRange(1)).writeToFile(fid);
    mni.printing.cards.PARAM('HFREQ','r',obj.FreqRange(2)).writeToFile(fid);
    mni.printing.cards.PARAM('LFREQFL','r',obj.FreqRange(1)).writeToFile(fid);
    mni.printing.cards.PARAM('HFREQFL','r',obj.FreqRange(2)).writeToFile(fid);

    % define Modal damping
    mni.printing.bdf.writeComment(fid,'Modal Damping')
    mni.printing.bdf.writeColumnDelimiter(fid,'8');
    mni.printing.cards.TABDMP1(obj.SDAMP_ID,'CRIT',obj.FreqRange,ones(1,2).*obj.ModalDampingPercentage).writeToFile(fid);
    

    mni.printing.bdf.writeComment(fid,'Flutter Card and Properties')
    mni.printing.bdf.writeColumnDelimiter(fid,'8');
    %create FLFACT cards
    fl_cards = [{mni.printing.cards.FLFACT(obj.Flfact_rho_id,...
        obj.rho/obj.RefDensity)},...
        {mni.printing.cards.FLFACT(obj.Flfact_mach_id,obj.Mach)},...
        {mni.printing.cards.FLFACT(obj.Flfact_v_id,obj.V)}]; 
    for i = 1:length(fl_cards)
        fl_cards{i}.writeToFile(fid)
    end

    %create flutter entry
    mni.printing.bdf.writeColumnDelimiter(fid,'8');
    f_card = mni.printing.cards.FLUTTER(obj.FlutterID,...
        obj.FlutterMethod,obj.Flfact_rho_id,...
        obj.Flfact_mach_id,obj.Flfact_v_id,[]);
    f_card.writeToFile(fid);
    if isempty(obj.ReducedMachs)
        Ms = unique(obj.Mach);
        if length(Ms)>5
            Ms = linspace(Ms(1),Ms(end),5);
        end
    else
        Ms = obj.ReducedMachs;
    end
    mni.printing.cards.MKAERO1(Ms,obj.ReducedFreqs).writeToFile(fid);
    println(fid,'ENDDATA')
    fclose(fid);
end
