function write_main_bdf(obj,filename,includes,feModel)
arguments
    obj
    filename string
    includes (:,1) string
    feModel ads.fe.Component
end
fid = fopen(filename,"w");
mni.printing.bdf.writeFileStamp(fid)
%% Case Control Section
mni.printing.bdf.writeComment(fid,'This file contain the main cards + case control for a 101 solution')
mni.printing.bdf.writeHeading(fid,'Case Control');
mni.printing.bdf.writeColumnDelimiter(fid,'8');
println(fid,'NASTRAN NLINES=999999');
println(fid,'SOL 101');

println(fid,'CEND');
mni.printing.bdf.writeHeading(fid,'Case Control')
println(fid,'ECHO=NONE');

% write output requests.
obj.Outputs.WriteToFile(fid);
println(fid,'GROUNDCHECK=NO');

fprintf(fid,'SPC=%.0f\n',obj.SPC_ID);
fprintf(fid,'LOAD=%.0f\n',obj.Load_ID);
% extra case control lines
if ~isempty(obj.ExtraCaseControl)
    for i = 1:length(obj.ExtraCaseControl)
        println(fid,obj.ExtraCaseControl(i));
    end
end
mni.printing.bdf.writeHeading(fid,'Begin Bulk')
%% Bulk Data
println(fid,'BEGIN BULK')
% include files
for i = 1:length(includes)
    mni.printing.cards.INCLUDE(includes(i)).writeToFile(fid);
end
% genric options
mni.printing.cards.PARAM('WTMASS','r',1).writeToFile(fid);
mni.printing.cards.PARAM('SNORM','r',20).writeToFile(fid);
mni.printing.cards.PARAM('AUTOSPC','s','YES').writeToFile(fid);
mni.printing.cards.PARAM('PRTMAXIM','s','YES').writeToFile(fid);
mni.printing.cards.PARAM('GRDPNT','i',0).writeToFile(fid);
mni.printing.cards.PARAM('BAILOUT','i',-1).writeToFile(fid);
mni.printing.cards.PARAM('OPPHIPA','i',1).writeToFile(fid);
mni.printing.cards.PARAM('AUNITS','r',0.1019716).writeToFile(fid);
mni.printing.cards.MDLPRM('HDF5','i',0).writeToFile(fid);
%extra cards
if ~isempty(obj.ExtraCards)
    mni.printing.bdf.writeComment(fid,'Extra Cards')
end
for i = 1:length(obj.ExtraCards)
    obj.ExtraCards(i).writeToFile(fid);
end

% Write Boundary Conditions
mni.printing.bdf.writeComment(fid, 'SPCs')
mni.printing.cards.SPCADD(obj.SPC_ID,obj.SPCs).writeToFile(fid);
% Write Main Load Card
% get IDs of extra forces
IDs = [];
if ~isempty(feModel.Forces)
    IDs = [IDs,reshape([feModel.Forces.ID],1,[])];
end
if ~isempty(feModel.Moments)
    IDs = [IDs,reshape([feModel.Moments.ID],1,[])];
end
%write gravity card
mni.printing.bdf.writeComment(fid,'Gravity Card')
mni.printing.bdf.writeColumnDelimiter(fid,'8');
mni.printing.cards.LOAD(obj.Load_ID,1,[obj.Grav_ID,IDs],[1,ones(size(IDs))]).writeToFile(fid);
mni.printing.cards.GRAV(obj.Grav_ID,obj.g*obj.LoadFactor,obj.Grav_Vector)...
    .writeToFile(fid);
fclose(fid);
end
