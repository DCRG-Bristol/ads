function txt = body2text(bodyStruct, avlOpts)
%BODY2TEXT  Convert a baff.BluffBody to an AVL BODY text block.
%
%   txt = body2text(bodyStruct, avlOpts)
%
%   bodyStruct has fields:
%     .body  (baff.BluffBody)
%     .A_g   (3x3) global rotation matrix
%     .O_g   (3x1) global origin
%
%   The body cross-section is assumed circular (radius from BluffBody
%   stations). AVL represents the body shape as an "airfoil" side-view
%   profile where the diameter is the span between top and bottom.

b   = bodyStruct.body;
A_g = bodyStruct.A_g;
O_g = bodyStruct.O_g;
T   = avlOpts.CoordTransform;
L   = b.EtaLength;

% BluffBody shares baff.Beam stations; radius comes from body stations.
% Attempt to get radius; fall back to a nominal value if unavailable.
try
    st     = b.Stations;
    etas   = st.Eta;
    radii  = st.Radius;
catch
    warning('ads:avl:body2text', ...
        'Could not read Radius from BluffBody "%s"; using zero radius.', b.Name);
    etas  = [0, 1];
    radii = [0, 0];
end

Nbody  = max(numel(etas), 5);
Bspace = 1.0;  % cosine spacing

lines = string.empty;
lines(end+1) = "BODY";
lines(end+1) = b.Name;
lines(end+1) = sprintf("%d  %.4g", Nbody, Bspace);
lines(end+1) = "";
lines(end+1) = "AIRFOIL";

% Generate inline airfoil coordinates: top half followed by bottom half,
% parameterised as normalised x/c, y/c where c is body length and
% y/c is radius/length (i.e. the body is viewed from the side).
% AVL body model treats this as a circle in cross-section.
eta_pts = linspace(0, 1, Nbody);
r_pts   = interp1(etas, radii, eta_pts, 'linear', 'extrap');
X_pts   = zeros(3, Nbody);
for k = 1:Nbody
    X_local  = b.GetPos(eta_pts(k)) * L;
    X_global = A_g * X_local + O_g;
    X_avl    = T * X_global;
    X_pts(:,k) = X_avl;
end

% Use body length as the normalisation length for BFILE-style coordinates
body_len = max(norm(X_pts(:,end) - X_pts(:,1)), eps);
x0 = X_pts(1,1);  % start X in AVL frame

% Top half (positive y/c = positive Z = up)
for k = 1:Nbody
    xc = (X_pts(1,k) - x0) / body_len;
    yc = r_pts(k) / body_len;
    lines(end+1) = sprintf("%.8f   %.8f", xc, yc);
end
% Bottom half (back to start, negative radius)
for k = Nbody:-1:1
    xc = (X_pts(1,k) - x0) / body_len;
    yc = -r_pts(k) / body_len;
    lines(end+1) = sprintf("%.8f   %.8f", xc, yc);
end

% TRANSLATE to put origin at AVL x0, y=0, z=0 in the body's frame
lines(end+1) = "";
lines(end+1) = "TRANSLATE";
lines(end+1) = sprintf("%.6g  %.6g  %.6g", X_pts(1,1), X_pts(2,1), X_pts(3,1));

txt = strjoin(lines, newline);

end % body2text
