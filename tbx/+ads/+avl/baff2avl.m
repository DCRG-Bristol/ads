function avlModel = baff2avl(baffModel, avlOpts)
%BAFF2AVL  Convert a baff.Model to an ads.avl.AvlModel for VLM analysis.
%
%   avlModel = ads.avl.baff2avl(baffModel)
%   avlModel = ads.avl.baff2avl(baffModel, opts)
%
%   Arguments:
%     baffModel  - baff.Model object
%     opts       - ads.avl.AvlOpts  (optional, uses defaults if omitted)
%
%   Returns:
%     avlModel   - ads.avl.AvlModel ready to call build() on
%
%   Example:
%     model    = UniformBaffWing();
%     opts     = ads.avl.AvlOpts(Symmetry=true, Nchord=8);
%     avlMdl   = ads.avl.baff2avl(model, opts);
%     folder   = avlMdl.build('ex_uw_avl');
%     avlMdl.run(folder, alpha=5);
%     derivs   = ads.avl.readDerivatives(folder);
%
%   See also: ads.avl.AvlOpts, ads.avl.AvlModel, ads.avl.readDerivatives

arguments
    baffModel baff.Model
    avlOpts   ads.avl.AvlOpts = ads.avl.AvlOpts();
end

%% Walk the element tree and collect Wings (and BluffBodies)
[wings, bodies] = extractElements(baffModel, avlOpts);

%% Compute reference quantities
ref = computeRefQuantities(wings, avlOpts);

%% Build AvlModel
avlModel      = ads.avl.AvlModel(baffModel.Name, avlOpts);
avlModel.RefQuantities = ref;

%% Convert each Wing to a SURFACE text block
surfaceNames = strings(0,1);
renamedPairs = strings(0,1);
for i = 1:numel(wings)
    baseName = string(wings(i).wing.Name);
    if baseName == ""
        baseName = "Surface";
    end

    name = baseName;
    suffix = 2;
    while any(surfaceNames == name)
        name = sprintf('%s_%d', baseName, suffix);
        suffix = suffix + 1;
    end
    surfaceNames(end+1,1) = name;

    if name ~= baseName
        renamedPairs(end+1,1) = sprintf('%s -> %s', baseName, name);
    end

    txt = wing2surfText(wings(i), avlOpts, ref);
    % Replace only the SURFACE name line (line after the SURFACE keyword).
    txt = regexprep(txt, '(?m)^(SURFACE\s*\R).+$', ['$1', char(name)], 'once');

    avlModel.Surfaces(end+1) = struct('Name', name, 'Text', txt);
end

if ~isempty(renamedPairs)
    warning('ads:avl:baff2avl:DuplicateSurfaceNames', ...
        'Duplicate wing names detected and renamed for AVL SURFACE blocks: %s', ...
        strjoin(renamedPairs, ', '));
end

%% Convert each BluffBody to a BODY text block (optional)
if avlOpts.IncludeBodies
    for i = 1:numel(bodies)
        txt = body2text(bodies(i), avlOpts);
        avlModel.Bodies(end+1) = struct('Name', bodies(i).body.Name, 'Text', txt);
    end
end

end
