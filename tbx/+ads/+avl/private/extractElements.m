function [wings, bodies] = extractElements(baffModel, avlOpts)
%EXTRACTELEMENTS  Recursively walk a baff.Model tree and collect Wings/Bodies.
%
%   [wings, bodies] = extractElements(baffModel, avlOpts)
%
%   Returns:
%     wings  - struct array with fields:
%                .wing  (baff.Wing)
%                .A_g   (3x3) global rotation matrix (baff→global frame)
%                .O_g   (3x1) global origin (mm or m, same unit as model)
%     bodies - struct array with fields:
%                .body  (baff.BluffBody)
%                .A_g   (3x3)
%                .O_g   (3x1)

wings  = struct('wing', {}, 'A_g', {}, 'O_g', {});
bodies = struct('body', {}, 'A_g', {}, 'O_g', {});

for i = 1:numel(baffModel.Orphans)
    [wings, bodies] = walkElement(baffModel.Orphans(i), wings, bodies);
end

end % extractElements

% -------------------------------------------------------------------------
function [wings, bodies] = walkElement(elem, wings, bodies)
%WALKELEMENT  Recurse into a baff element and its children.

if isa(elem, 'baff.Wing')
    % GetGlobalA and GetGlobalPos(0) give the global transform
    A_g = elem.GetGlobalA();
    O_g = elem.GetGlobalPos(0);
    wings(end+1) = struct('wing', elem, 'A_g', A_g, 'O_g', O_g); %#ok<AGROW>

elseif isa(elem, 'baff.BluffBody')
    A_g = elem.GetGlobalA();
    O_g = elem.GetGlobalPos(0);
    bodies(end+1) = struct('body', elem, 'A_g', A_g, 'O_g', O_g); %#ok<AGROW>
end

% Recurse into children regardless of type (Wings can have child Wings, etc.)
for i = 1:numel(elem.Children)
    [wings, bodies] = walkElement(elem.Children(i), wings, bodies);
end

end % walkElement
