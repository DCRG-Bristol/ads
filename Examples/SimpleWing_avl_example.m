%% Example: AVL VLM Stability Derivatives from a baff Wing Model
% Converts a uniform cantilever wing (baff.Model) to an AVL vortex-lattice
% model, generates the .avl input file, runs AVL, and reads back the
% stability derivatives.
%
% Prerequisites:
%   - AVL executable accessible as 'avl' on the system PATH
%     (or set opts.AvlExePath to the full path).
%   - baff toolbox installed.
%   - ads toolbox on the MATLAB path.

fclose all;
clear all;

%% 1. Build the baff model
% UniformBaffWing() is defined in Examples/private/ and returns a baff.Model
% of a simple cantilever wing.
model = UniformBaffWing();

%% 2. Set AVL options
opts = ads.avl.AvlOpts( ...
    Symmetry         = true, ...   % mirror at Y=0 to create full wing
    IncludeBodies    = false, ...  % no fuselage in this model
    Nchord           = 8, ...      % chordwise vortex panels
    Cspace           = 1.0, ...    % cosine chordwise spacing
    NspanPerSection  = 12, ...     % spanwise vortices per aero station gap
    Sspace           = -2.0, ...   % cosine-across-span spanwise spacing
    AvlExePath       = "C:\Program Files\AVL\avl352.exe");     % assumes AVL is on PATH

% Coordinate transform: baff global → AVL frame (X=fwd, Y=right, Z=up)
% For UniformBaffWing the beam runs along the +Y direction in baff global
% coordinates.  AVL also uses +Y spanwise, so no rotation is needed here.
% opts.CoordTransform = eye(3);   % (default)

%% 3. Convert to AVL model
avlMdl = ads.avl.baff2avl(model, opts);
avlMdl.Name = 'test';

fprintf('Reference quantities:\n');
fprintf('  Sref = %.4f m^2\n', avlMdl.RefQuantities.Sref);
fprintf('  Bref = %.4f m\n',   avlMdl.RefQuantities.Bref);
fprintf('  Cref = %.4f m\n',   avlMdl.RefQuantities.Cref);

%% 4. Write the .avl input file to disk
BinFolder = avlMdl.build('ex_uw_avl');
fprintf('\nAVL input written to: %s\n', ...
    fullfile(BinFolder, 'Source', [char(avlMdl.Name), '.avl']));

%% 5. Open AVL geometry viewer in a separate call
avlMdl.plotGeometry(BinFolder);

%% 6. Run AVL (requires AVL executable)
alpha_deg = 5;
beta_deg  = 0;

avlMdl.run(BinFolder, alpha=alpha_deg, beta=beta_deg);

%% 7. Read stability derivatives
derivs = ads.avl.readDerivatives(BinFolder, Name=avlMdl.Name);
forces = ads.avl.readForces(BinFolder, Name=avlMdl.Name);

fprintf('\n--- Stability derivatives (alpha=%.1f deg, beta=%.1f deg) ---\n', ...
    alpha_deg, beta_deg);
fprintf('  CLa = %8.4f  1/rad\n', derivs.CLa);
fprintf('  Cma = %8.4f  1/rad\n', derivs.Cma);
fprintf('  CLb = %8.4f  1/rad\n', derivs.CLb);
fprintf('  Clb = %8.4f  1/rad (dihedral effect)\n', derivs.Clb);
fprintf('  Cnb = %8.4f  1/rad (weathercock)\n',     derivs.Cnb);

fprintf('\n--- AVL static force output (FT file) ---\n');
forceFields = string(fieldnames(forces));
if isempty(forceFields)
    fprintf('  no AVL force fields found in FT output\n');
else
    for i = 1:numel(forceFields)
        fieldName = forceFields(i);
        if isnumeric(forces.(fieldName)) && isscalar(forces.(fieldName))
            fprintf('  %-8s = %8.4f\n', fieldName, forces.(fieldName));
        end
    end
end

%% 8. Simple analytical static-force estimates for the untwisted symmetric wing
AR = avlMdl.RefQuantities.Bref^2 / avlMdl.RefQuantities.Sref;

% Rectangular unswept wings are not ideal; this is a rough efficiency
% estimate, not an exact correction factor.
e  = 1.78 * (1 - 0.045 * AR^0.68) - 0.64;
e  = min(max(e, 0.1), 1.0);

% Classical lifting-line estimate for finite-wing lift-curve slope.
a0 = 2*pi;
CLa_analytic = a0 / (1 + a0 / (pi * e * AR));
CL_analytic  = CLa_analytic * deg2rad(alpha_deg);
CDi_analytic = CL_analytic^2 / (pi * e * AR);

fprintf('\n--- Simple analytical force estimates ---\n');
fprintf('  AR = %8.4f\n', AR);
fprintf('  CL  ~ %8.4f        [matches FT coefficient CL] at alpha = %.1f deg\n', CL_analytic, alpha_deg);
fprintf('  CD  ~ %8.4f        [induced drag estimate for FT coefficient CD]\n', CDi_analytic);
fprintf('  CY  ~ %8.4f        [symmetry estimate for FT coefficient CY]\n', 0.0);
fprintf('  Cl  ~ %8.4f        [symmetry estimate for FT coefficient Cl]\n', 0.0);
fprintf('  Cn  ~ %8.4f        [symmetry estimate for FT coefficient Cn]\n', 0.0);
fprintf('  Cm depends on the chosen reference point, so a clean analytic estimate is reference-dependent.\n');
fprintf('  These are analytic estimates only and are not read from the AVL output file.\n');

fprintf('  CLa ~ %8.4f  1/rad   (lifting-line, e=%.3f)\n', CLa_analytic, e);
