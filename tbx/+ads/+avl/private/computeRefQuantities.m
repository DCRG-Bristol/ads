function ref = computeRefQuantities(wings, avlOpts)
%COMPUTEREFQUANTITIES  Compute Sref, Cref, Bref, Xref from wing geometry.
%
%   ref = computeRefQuantities(wings, avlOpts)
%
%   Quantities are computed from the union of all wings passed in.
%   If avlOpts.Symmetry is true, Sref and Bref are doubled to reflect the
%   mirrored side.
%
%   Formulae (trapezoidal integration along span):
%     Sref = sum over wings of integral(c * ds)    [planform area]
%     Bref = max spanwise extent (doubled if symmetric)
%     Cref = (1/Sref) * sum over wings of integral(c^2 * ds)  [MAC]
%     Xref = global X of the leading edge at the root of the first wing

T = avlOpts.CoordTransform;   % 3x3

Sref_total = 0;
Cref_num   = 0;   % numerator of MAC = integral c^2 ds
Bref_max   = 0;   % maximum spanwise coordinate
Xref_root  = NaN;

for wi = 1:numel(wings)
    w  = wings(wi).wing;    % baff.Wing
    st = w.AeroStations;    % baff.station.Aero
    etas = st.Eta;          % (1,N) normalised stations

    for k = 1:(numel(etas) - 1)
        eta_a = etas(k);
        eta_b = etas(k+1);

        % Chords at inboard and outboard station
        c_a = interp1(st.Eta, st.Chord, eta_a);
        c_b = interp1(st.Eta, st.Chord, eta_b);

        % Physical panel span ds (Euclidean distance between beam positions)
        X_a = w.GetPos(eta_a);  % local beam pos (3x1)
        X_b = w.GetPos(eta_b);
        ds = norm(T * (X_b - X_a));

        % Trapezoidal integration
        Sref_total = Sref_total + 0.5 * (c_a + c_b) * ds;
        Cref_num   = Cref_num   + 0.5 * (c_a^2 + c_b^2) * ds;
    end

    % Spanwise extent: maximum Y (after transform) over all stations
    for k = 1:numel(etas)
        X_local = w.GetPos(etas(k));
        X_global = wings(wi).A_g * X_local + wings(wi).O_g;
        X_avl    = T * X_global;
        Bref_max = max(Bref_max, abs(X_avl(2)));  % Y coordinate
    end

    % Root LE position of the first wing
    if isnan(Xref_root) && wi == 1
        X_le_local  = w.GetPos(etas(1)) + st.GetPos(etas(1), 0);
        X_le_global = wings(1).A_g * X_le_local + wings(1).O_g;
        X_le_avl    = T * X_le_global;
        Xref_root   = X_le_avl(1);
        Zref_root   = X_le_avl(3);
    end
end

% Double for symmetric half-models
if avlOpts.Symmetry
    Sref_total = 2 * Sref_total;
    Bref_max   = 2 * Bref_max;
end

Cref_val = Cref_num / (Sref_total / (avlOpts.Symmetry + 1));

%% Apply user overrides
ref.Sref = pickval(avlOpts.Sref, Sref_total);
ref.Bref = pickval(avlOpts.Bref, Bref_max);
ref.Cref = pickval(avlOpts.Cref, Cref_val);
ref.Xref = pickval(avlOpts.Xref, Xref_root);
ref.Yref = pickval(avlOpts.Yref, 0);
ref.Zref = pickval(avlOpts.Zref, Zref_root);

end % computeRefQuantities

% -------------------------------------------------------------------------
function v = pickval(userVal, autoVal)
%PICKVAL  Return autoVal if userVal is NaN, otherwise return userVal.
if isnan(userVal)
    v = autoVal;
else
    v = userVal;
end
end
