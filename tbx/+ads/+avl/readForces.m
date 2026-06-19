function forces = readForces(BinFolder, opts)
%READFORCES  Parse AVL total-force output into a struct.
%
%   forces = ads.avl.readForces(BinFolder)
%   forces = ads.avl.readForces(BinFolder, Name='model')
%
%   Reads the file <BinFolder>/bin/<Name>_ft.txt that was written by
%   AvlModel.run() and returns a struct containing the total force and
%   moment coefficients reported by AVL.
%
%   Typical fields include CL, CD, CM and, depending on AVL output,
%   possibly CX, CY, CZ, Cl, Cm, Cn, alpha, beta, and similar totals.
%
%   See also: ads.avl.AvlModel, ads.avl.readDerivatives

arguments
    BinFolder (1,1) string
    opts.Name (1,1) string = "model";
end

BinFolder = ads.avl.resolveFolderPath(BinFolder);
ftFile    = fullfile(BinFolder, 'bin', [char(opts.Name), '_ft.txt']);

forces = struct();
if exist(ftFile, 'file')
    forces = parseAvlText(ftFile, forces);
    forces = normalizeForceFields(forces);
else
    warning('ads:avl:readForces', ...
        'Total-force file not found: %s', ftFile);
end

end

% -------------------------------------------------------------------------
function forces = normalizeForceFields(forces)
%NORMALIZEFORCEFIELDS  Map common AVL total-force aliases onto canonical names.

aliasMap = [ ...
    "CLtot", "CL"; ...
    "CDtot", "CD"; ...
    "CYtot", "CY"; ...
    "Cltot", "Cl"; ...
    "Cmtot", "Cm"; ...
    "Cntot", "Cn"; ...
    "CXtot", "CX"; ...
    "CYtot", "CY"; ...
    "CZtot", "CZ"; ...
    "CDi",  "CDi"; ...
    "CDvis", "CDvis"; ...
    "CDff",  "CDff" ];

for i = 1:size(aliasMap, 1)
    alias = aliasMap(i, 1);
    canon = aliasMap(i, 2);
    if isfield(forces, alias) && ~isfield(forces, canon)
        forces.(canon) = forces.(alias);
    end
end

end