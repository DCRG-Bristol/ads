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
    mni.printing.bdf.writeComment(fid,'This file contain the main cards + case control for a 144 solution')
    obj.write_case_control(fid);
    %% Bulk Data
    mni.printing.bdf.writeHeading(fid,'Begin Bulk')
    println(fid,'BEGIN BULK')
    % include files
    for i = 1:length(includes)
        mni.printing.cards.INCLUDE(includes(i)).writeToFile(fid);
    end
    %write Boundary Conditions
    mni.printing.bdf.writeComment(fid, 'SPCs')
    mni.printing.cards.SPCADD(obj.SPC_ID,obj.SPCs).writeToFile(fid);
    % write GRAV + loads
    % get IDs of extra forces
    IDs = [];
    if ~isempty(feModel.Forces)
        IDs = [IDs,reshape([feModel.Forces.ID],1,[])];
    end
    if ~isempty(feModel.Moments)
        IDs = [IDs,reshape([feModel.Moments.ID],1,[])];
    end
    mni.printing.bdf.writeComment(fid,'Gravity Card')
    mni.printing.bdf.writeColumnDelimiter(fid,'8');
    mni.printing.cards.LOAD(obj.Load_ID,1,[obj.Grav_ID,IDs],[1,ones(1,numel(IDs))]).writeToFile(fid);
    mni.printing.cards.GRAV(obj.Grav_ID,obj.g*obj.LoadFactor,obj.Grav_Vector)...
        .writeToFile(fid);
    % genric options 
    mni.printing.cards.PARAM('POST','i',0).writeToFile(fid);
    mni.printing.cards.PARAM('AUTOSPC','s','YES').writeToFile(fid);
    mni.printing.cards.PARAM('GRDPNT','i',0).writeToFile(fid);
    mni.printing.cards.PARAM('BAILOUT','i',-1).writeToFile(fid);
    mni.printing.cards.PARAM('OPPHIPA','i',1).writeToFile(fid);
    mni.printing.cards.PARAM('AUNITS','r',0.1019716).writeToFile(fid);
    mni.printing.cards.MDLPRM('HDF5','i',0).writeToFile(fid);
    
    
    %create eigen solver and frequency bounds
    mni.printing.bdf.writeComment(fid,'Eigen Decomposition Method')
    mni.printing.bdf.writeColumnDelimiter(fid,'8');
    mni.printing.cards.EIGR(obj.EigR_ID,'MGIV','F1',0,...
         'F2',obj.FreqRange(2),'NORM','MAX')...
         .writeToFile(fid);
%     mni.printing.cards.EIGR(10,'MGIV','ND',42,'NORM','MAX')...
%         .writeToFile(fid);

    obj.write_sol144_cards(fid);
    println(fid,'ENDDATA')
    fclose(fid);
end
