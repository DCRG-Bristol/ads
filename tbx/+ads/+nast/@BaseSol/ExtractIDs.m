function ExtractIDs(obj,feModel)
%EXTRACTIDS Extract the relevant IDs from the provided feModel

%extract constraint IDs
if ~isempty(feModel.Constraints)
    obj.SPCs = [feModel.Constraints.ID];
else
    obj.SPCs = [];
end
%extract Forces
obj.ForceIDs = [];
if ~isempty(feModel.Forces)
    obj.ForceIDs = [obj.ForceIDs,reshape([feModel.Forces.ID],1,[])];
end
if ~isempty(feModel.Moments)
    obj.ForceIDs = [obj.ForceIDs,reshape([feModel.Moments.ID],1,[])];
end
end