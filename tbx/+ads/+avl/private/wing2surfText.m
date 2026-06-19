function txt = wing2surfText(wingStruct, avlOpts, ~)
%WING2SURFTEXT  Convert a baff.Wing to an AVL SURFACE text block.
%
%   txt = wing2surfText(wingStruct, avlOpts, ref)
%
%   wingStruct has fields:
%     .wing  (baff.Wing)
%     .A_g   (3x3) global rotation matrix (wing-local → baff global)
%     .O_g   (3x1) global origin of wing root (baff global frame)
%
%   avlOpts  ads.avl.AvlOpts
%   ref      struct: Sref, Cref, Bref, Xref, Yref, Zref
%
%   AVL SURFACE block format (X=fwd, Y=right, Z=up):
%
%     SURFACE
%     <name>
%     Nchord  Cspace  [Nspan  Sspace]
%     SECTION
%     Xle  Yle  Zle   Chord  Ainc  [Nspan  Sspace]
%     [NACA xxxx  OR  CLAF value]
%     [CONTROL ...]
%     ...

w  = wingStruct.wing;
A_g = wingStruct.A_g;   % rotation: local → global (baff)
O_g = wingStruct.O_g;   % global origin of wing root
T   = avlOpts.CoordTransform;  % baff global → AVL frame

st  = w.AeroStations;          % baff.station.Aero
etas = st.Eta;                 % (1,N) normalised station positions

% Merge control surface eta breaks into station list so hinge lines
% fall on exact section boundaries.
if ~isempty(w.ControlSurfaces)
    csEtas = reshape([w.ControlSurfaces.Etas], 1, []);
    allEtas = unique([etas, csEtas]);
else
    allEtas = etas;
end
% Re-interpolate aero station properties at merged etas
st_all = st.interpolate(allEtas);

lines = string.empty;

%% --- SURFACE header ---
lines(end+1) = "SURFACE";
lines(end+1) = w.Name;

nchord = avlOpts.Nchord;
cspace = avlOpts.Cspace;

if ~isempty(avlOpts.Nspan)
    lines(end+1) = sprintf("%d  %.4g  %d  %.4g", ...
        nchord, cspace, avlOpts.Nspan(1), avlOpts.Sspace);
else
    lines(end+1) = sprintf("%d  %.4g", nchord, cspace);
end

lines(end+1) = "";

%% --- SECTION blocks ---
for k = 1:st_all.N
    eta = st_all.Eta(k);
        chord = st_all.Chord(k);

    % Beam position in wing-local frame.
    X_beam_local = w.GetPos(eta);        % (3,1)

    % Leading-edge offset from beam in wing-local frame
    X_le_local = st_all.GetPos(eta, 0); % (3,1) relative to beam

    % Total LE position in wing-local frame
    X_le_winglocal = X_beam_local + X_le_local;

    % Transform: wing-local → baff global → AVL frame
    %   baff Wing: local frame has y along beam axis, x along chord
    %   GetGlobalA() / A_g rotates column vectors from local to global
    X_le_global = A_g * X_le_winglocal + O_g;
    X_le_avl    = T * X_le_global;       % (3,1) in AVL frame

    Xle = X_le_avl(1);
    Yle = X_le_avl(2);
    Zle = X_le_avl(3);

    % Incidence (twist) — AVL convention: + rotation about span axis = nose up
    twist = st_all.Twist(k);   % degrees, from baff

    % Span-count per section interval (if per-section mode)
    if isempty(avlOpts.Nspan) && k < st_all.N
        nspan_sec = avlOpts.NspanPerSection;
        sspace_sec = avlOpts.Sspace;
        sectionSpanStr = sprintf("  %d  %.4g", nspan_sec, sspace_sec);
    else
        sectionSpanStr = "";
    end

    lines(end+1) = "SECTION";
    lines(end+1) = sprintf("%-12.6g  %-12.6g  %-12.6g  %-12.6g  %-10.6g%s", ...
        Xle, Yle, Zle, chord, twist, char(sectionSpanStr));

    % NACA thickness if available (symmetric 4-digit)
    tc = st_all.ThicknessRatio(k);
    if tc > 0
        naca_xx = round(tc * 100);
        lines(end+1) = sprintf("NACA");
        lines(end+1) = sprintf("00%02d", naca_xx);
    end

    % CLAF (lift-curve-slope scaling: CLaf = Clα / (2π))
    Cla = st_all.LiftCurveSlope(k);
    CLaf = Cla / (2*pi);
    if abs(CLaf - 1.0) > 0.01
        lines(end+1) = "CLAF";
        lines(end+1) = sprintf("%.6g", CLaf);
    end

    % CONTROL surfaces active at this station
    for ci = 1:numel(w.ControlSurfaces)
        cs    = w.ControlSurfaces(ci);
        etaIn  = cs.Etas(1);
        etaOut = cs.Etas(2);

        % Include CONTROL card at inboard AND outboard bounding sections
        % (and any intermediate merged sections within the span)
        if eta >= etaIn - 1e-9 && eta <= etaOut + 1e-9
            % Hinge x/c location measured from LE (positive = TE flap)
            % baff pChord is measured from TE: hinge_xc = 1 - pChord
            pC_in  = cs.pChord(1);
            Xhinge = 1.0 - pC_in;   % fraction of chord from LE

            % Hinge vector: spanwise direction at this station (AVL frame)
            % Use finite difference of LE positions across two nearby etas
            eta_lo = max(eta - 0.01, etas(1));
            eta_hi = min(eta + 0.01, etas(end));
            X_a_local = w.GetPos(eta_lo) + st.GetPos(eta_lo, 0);
            X_b_local = w.GetPos(eta_hi) + st.GetPos(eta_hi, 0);
            dX = T * (A_g * (X_b_local - X_a_local));
            if norm(dX) > 0
                hvec = dX / norm(dX);
            else
                hvec = [0;1;0];
            end

            % SgnDup: +1 for elevator/flap (same deflection on mirror),
            % -1 for aileron (opposite on mirror).
            % Convention: default to +1; user can rename to 'aileron' later.
            sgnDup = 1.0;

            lines(end+1) = "CONTROL";
            lines(end+1) = sprintf("%-12s  1.0  %.6g  %.6g %.6g %.6g  %.4g", ...
                char(cs.Name), Xhinge, hvec(1), hvec(2), hvec(3), sgnDup);
        end
    end

    lines(end+1) = "";
end

txt = strjoin(lines, newline);

end % wing2surfText
