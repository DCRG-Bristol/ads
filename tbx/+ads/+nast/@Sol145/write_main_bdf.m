function write_main_bdf(obj,filename,includes)
arguments
    obj
    filename string
    includes (:,1) string
end
    fid = fopen(filename,"w");
    mni.printing.bdf.writeFileStamp(fid)
    %% Case Control Section
    mni.printing.bdf.writeComment(fid,'This file contain the main cards + case control for a 145 solution')
    mni.printing.bdf.writeHeading(fid,'Case Control');
    mni.printing.bdf.writeColumnDelimiter(fid,'8');
    println(fid,'NASTRAN NLINES=999999');
    println(fid,'SOL 145');
    println(fid,'TIME 10000');
    println(fid,'CEND');
    mni.printing.bdf.writeHeading(fid,'Case Control')
    println(fid,'ECHO=NONE');
    println(fid,'VECTOR(SORT1,REAL)=ALL');
    println(fid,sprintf('SDAMP = %.0f',obj.SDAMP_ID));
    println(fid,sprintf('FMETHOD = %.0f',obj.FlutterID));
    println(fid,sprintf('METHOD = %.0f',obj.EigR_ID));
    fprintf(fid,'SPC=%.0f\n',obj.SPC_ID);
    if ~isempty(obj.DispIDs)
        if any(isnan(obj.DispIDs))
            println(fid,'DISPLACEMENT(SORT1,REAL)= NONE');
        else
            mni.printing.cases.SET(1,obj.DispIDs).writeToFile(fid);
            println(fid,'DISPLACEMENT(SORT1,REAL)= 1');
        end
    else
        println(fid,'DISPLACEMENT(SORT1,REAL)= ALL');
    end
    if ~isempty(obj.ForceIDs)
        if any(isnan(obj.ForceIDs))
            println(fid,'FORCE(SORT1,REAL)= NONE');
        else
            mni.printing.cases.SET(2,obj.ForceIDs).writeToFile(fid);
            println(fid,'FORCE(SORT1,REAL)= 2');
        end
    else
        println(fid,'FORCE(SORT1,REAL)= ALL');
    end
    println(fid,'MONITOR = ALL');  

    println(fid,'GROUNDCHECK=YES');
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

    fclose(fid);
end
function println(fid,string)
fprintf(fid,'%s\n',string);
end
