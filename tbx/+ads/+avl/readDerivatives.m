function derivs = readDerivatives(BinFolder, opts)
%READDERIVATIVES  Parse AVL stability derivative output into a struct.
%
%   derivs = ads.avl.readDerivatives(BinFolder)
%   derivs = ads.avl.readDerivatives(BinFolder, Name='model')
%
%   Reads the file <BinFolder>/bin/<Name>_st.txt that was written by
%   AvlModel.run() and returns a struct containing all stability and
%   control derivatives reported by AVL.
%
%   The returned struct has fields like:
%     derivs.CLa   - dCL/d(alpha)  [1/rad]
%     derivs.CLb   - dCL/d(beta)   [1/rad]
%     derivs.CYa, CYb
%     derivs.Cla, Clb   (roll moment)
%     derivs.Cma, Cmb   (pitch moment)
%     derivs.Cna, Cnb   (yaw moment)
%     derivs.CLp, CLq, CLr, CYp, CYq, CYr, Clp, Clq, Clr, Cmp, Cmq, Cmr, Cnp, Cnq, Cnr
%     derivs.CLd1, CYd1, Cld1, Cmd1, Cnd1, ... (control derivatives)
%     derivs.CL, CD, CM     (total forces at the run condition)
%     derivs.alpha, derivs.beta  (run condition angles, deg)
%
%   Example:
%     folder = avlMdl.build('ex_uw_avl');
%     avlMdl.run(folder, alpha=5);
%     derivs = ads.avl.readDerivatives(folder);
%     fprintf('CLa = %.4f\n', derivs.CLa);
%
%   See also: ads.avl.AvlModel, ads.avl.baff2avl

arguments
    BinFolder (1,1) string
    opts.Name (1,1) string = "model";
end

BinFolder = ads.avl.resolveFolderPath(BinFolder);
stFile    = fullfile(BinFolder, 'bin', [char(opts.Name), '_st.txt']);
ftFile    = fullfile(BinFolder, 'bin', [char(opts.Name), '_ft.txt']);

%% Read stability derivatives from ST file
derivs = struct();
if exist(stFile, 'file')
    derivs = parseAvlText(stFile, derivs);
else
    warning('ads:avl:readDerivatives', ...
        'Stability derivative file not found: %s', stFile);
end

%% Also read total forces from FT file if present
if exist(ftFile, 'file')
    derivs = parseAvlText(ftFile, derivs);
end

end % readDerivatives
