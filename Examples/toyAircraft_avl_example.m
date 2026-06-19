clear all
fus_rad = 0.055;
span = 1.5;
beam_loc = 0.25;
Chord = 0.12;

%empenage setting
hSpan = 0.4;
hChord = 0.07;
vSpan = 0.15;
vChord = 0.07;

%% create fuselage
cockpit = baff.BluffBody.SemiSphere(0.15,0.055);

fus_body = baff.BluffBody.Cylinder(0.652-0.082,0.055);

fus_tail = baff.BluffBody.Cone(0.14,0.055,0.02);
[fus_tail.Stations.EtaDir] = deal([0.14;0;0.005-0.02-0.005]./0.14);

fuselage = cockpit + fus_body + fus_tail;
fuselage.DistributeMass(1,5);
% fuselage.Stations.EtaDir(1,:) = -fuselage.Stations.EtaDir(1,:);
% fuselage.Stations.StationDir = repmat([0;0;1],1,fuselage.Stations.N);

%% create Wing
Wing = baff.Wing.UniformWing(span,0.1,0.1,...
    baff.Material.Stiff,Chord,beam_loc,"NAeroStations",11);
Wing.Name = "MainWing";
Wing.A = dcrg.rotzd(-90)*dcrg.rotxd(180);
Wing.Eta = 0.5;
Wing.Offset = [0;span*0.5;fus_rad*0.66];
Wing.DistributeMass(0.5,9);
fuselage.add(Wing);

% Add Control Surface
Wing.ControlSurfaces(1) =  baff.ControlSurface("Ail_R",[0.8 0.95],[0.25 0.25]);
Wing.ControlSurfaces(2) =  baff.ControlSurface("Ail_L",[0.05 0.2],[0.25 0.25]);

%% create htp
Htp = baff.Wing.UniformWing(hSpan,0.1,0.1,...
    baff.Material.Stiff,hChord,beam_loc,"NAeroStations",11);
Htp.Name = "HTP";
Htp.A = dcrg.rotzd(-90)*dcrg.rotxd(180);
Htp.Eta = 0.93;
Htp.Offset = [0;hSpan*0.5;-fus_rad*0.25];
Htp.DistributeMass(0.2,5);
fuselage.add(Htp);

Htp.ControlSurfaces(1) =  baff.ControlSurface("Ele_R",[0.6 0.95],[0.3 0.3]);
Htp.ControlSurfaces(2) =  baff.ControlSurface("Ele_L",[0.05 0.4],[0.3 0.3]);

%% create vtp
Vtp = baff.Wing.UniformWing(vSpan,0.1,0.1,...
    baff.Material.Stiff,vChord,beam_loc,"NAeroStations",11);
Vtp.Name = "VTP";
Vtp.A = dcrg.rotyd(90)*dcrg.rotxd(-90);
Vtp.Eta = 0.93;
Vtp.Offset = [0;0;-fus_rad*0.25];
Vtp.DistributeMass(0.1,5);
fuselage.add(Vtp);

Vtp.ControlSurfaces(1) =  baff.ControlSurface("Rud_R",[0.3 0.95],[0.25 0.25]);

%% create model
delete test.h5
baff.Model.GenTempHdf5('test.h5');

tic;
model = baff.Model;
model.AddElement(fuselage);
model.UpdateIdx();
model.ToBaff('test.h5');
toc;

f = figure(1);
clf;
hold on
model.draw(f,Type="surf")
csPatches = findobj(f, 'Tag', 'Control Surfaces');
set(csPatches, 'FaceColor', [0.9 0.2 0.2], 'FaceAlpha', 0.75, ...
    'EdgeColor', [0.6 0.0 0.0], 'LineWidth', 1.2);
ax = gca;
ax.Clipping = false;
% ax.ZAxis.Direction = "reverse";
axis equal

%% 2.1 Set AVL moment reference to baff model COM
[com_baff, totalMass] = model.GetCoM();
if ~isfinite(totalMass) || totalMass <= 0 || any(~isfinite(com_baff))
    warning('ads:avl:toyExample:InvalidMassOrCom', ...
        ['Model mass/COM is invalid (mass=%.6g, COM=[%.6g %.6g %.6g]). ', ...
         'Falling back to AVL reference point [0 0 0].'], ...
        totalMass, com_baff(1), com_baff(2), com_baff(3));
    totalMass = 0;
    com_baff = [0;0;0];
end
fprintf('\nModel mass properties:\n');
fprintf('  Mass = %.4f kg\n', totalMass);
fprintf('  COM  = [%.4f, %.4f, %.4f] m\n', com_baff(1), com_baff(2), com_baff(3));


%% 2. Set AVL options
opts = ads.avl.AvlOpts( ...
    Symmetry         = false, ...  % full aircraft is already modelled explicitly
    IncludeBodies    = false, ...  % no fuselage in this model
    Xref             = com_baff(1), ... % AVL moment reference from baff COM
    Yref             = com_baff(2), ...
    Zref             = com_baff(3), ...
    Nchord           = 8, ...      % chordwise vortex panels
    Cspace           = 1.0, ...    % cosine chordwise spacing
    NspanPerSection  = 4, ...      % spanwise vortices per section interval
    Sspace           = -2.0, ...   % cosine-across-span spanwise spacing
    AvlExePath       = "C:\Program Files\AVL\avl352.exe");     % assumes AVL is on PATH

% Coordinate transform: baff global → AVL frame (X=fwd, Y=right, Z=up)
% This toy aircraft is built directly in the AVL frame convention, so the
% identity transform is used.
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

% In AVL, control surfaces are easiest to see after a temporary deflection.
controlPreviewDeg = 8;
controlNames = [];
for wi = 1:length(model.Wing)
    if isempty(model.Wing(wi).ControlSurfaces)
        continue;
    end
    controlNames = [controlNames; string({model.Wing(wi).ControlSurfaces.Name})']; %#ok<AGROW>
end
controlNames = unique(controlNames, 'stable');

fprintf('\n--- AVL geometry control-surface preview ---\n');
fprintf('In the AVL window type:\n');
fprintf('  OPER\n');
for i = 1:numel(controlNames)
    fprintf('  D%d D%d %+g   %% %s\n', i, i, controlPreviewDeg, controlNames(i));
end
fprintf('  G\n');
fprintf('Then close AVL (or type QUIT) and press Enter here to continue.\n');
input('Press Enter to continue with batch run... ', 's');

%% 6. Run AVL (requires AVL executable)
alpha_deg = 5;
beta_deg  = 0;

avlMdl.run(BinFolder, alpha=alpha_deg, beta=beta_deg);

%% 7. Read stability derivatives
derivs = ads.avl.readDerivatives(BinFolder, Name=avlMdl.Name);
forces = ads.avl.readForces(BinFolder, Name=avlMdl.Name);

if isempty(fieldnames(derivs))
    error('ads:avl:toyExample:NoDerivatives', ...
        ['No AVL derivatives were parsed. Check AVL log for run/build errors: %s'], ...
        fullfile(BinFolder, 'bin', [char(avlMdl.Name), '_avl.log']));
end

fprintf('\n--- Stability derivatives (alpha=%.1f deg, beta=%.1f deg) ---\n', ...
    alpha_deg, beta_deg);
fprintf('  CLa = %8.4f  1/rad\n', derivs.CLa);
fprintf('  Cma = %8.4f  1/rad\n', derivs.Cma);
fprintf('  CLb = %8.4f  1/rad\n', derivs.CLb);
fprintf('  Clb = %8.4f  1/rad (dihedral effect)\n', derivs.Clb);
fprintf('  Cnb = %8.4f  1/rad (weathercock)\n',     derivs.Cnb);

fprintf('\n--- Neutral point and static margin ---\n');
if isfield(derivs, 'Xnp')
    Xnp = derivs.Xnp;
    fprintf('  Xnp = %8.4f m   (from AVL ST output)\n', Xnp);
else
    if abs(derivs.CLa) < 1e-12
        warning('ads:avl:toyExample:InvalidCLa', ...
            'CLa is too small to compute neutral point from Cma/CLa.');
        Xnp = NaN;
    else
        Xnp = avlMdl.RefQuantities.Xref - (derivs.Cma / derivs.CLa) * avlMdl.RefQuantities.Cref;
        fprintf('  Xnp = %8.4f m   (computed from Xref - (Cma/CLa)*Cref)\n', Xnp);
    end
end

if isfinite(Xnp)
    Xcg = com_baff(1);
    SM = (Xnp - Xcg) / avlMdl.RefQuantities.Cref;
    fprintf('  Xcg = %8.4f m   (baff COM x-location)\n', Xcg);
    fprintf('  Static margin = %8.4f  (%.2f %% MAC)\n', SM, 100*SM);
end

fprintf('\n--- Control-surface derivatives (from ST file) ---\n');
derivFieldNames = string(fieldnames(derivs));
isControlDeriv = ~cellfun(@isempty, regexp(cellstr(derivFieldNames), ...
    '^(CL|CD|CY|CX|CZ|Cl|Cm|Cn)d\d+$', 'once'));
controlDerivFields = derivFieldNames(isControlDeriv);
if isempty(controlDerivFields)
    fprintf('  no control derivatives found (expected forms like CLd1, Cmd2, Cnd3)\n');
else
    for i = 1:numel(controlDerivFields)
        fName = controlDerivFields(i);
        fprintf('  %-8s = %10.5f\n', fName, derivs.(fName));
    end
end

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