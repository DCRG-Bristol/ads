classdef AvlOpts
    %AVLOPTS Options for converting a baff.Model to an AVL VLM model.
    %
    %   AVL uses a right-handed coordinate system:
    %     X = downstream (drag direction)
    %     Y = starboard (right wing)
    %     Z = up (lift direction)
    %
    %   The baff model may use any global coordinate frame. Use
    %   CoordTransform to provide a 3x3 rotation matrix that maps from
    %   the baff global frame to the AVL frame.
    %
    %   Example:
    %     opts = ads.avl.AvlOpts(Symmetry=true, Nchord=8);
    properties
        % --- Geometry ---
        %Symmetry: if true, mirror the model about Y=0 using AVL's header
        %symmetry flag.
        Symmetry (1,1) logical = true;

        %IncludeBodies: if true, baff.BluffBody elements are converted to
        %AVL BODY sections. Set false to ignore them (default: true).
        IncludeBodies (1,1) logical = true;

        %CoordTransform: 3x3 rotation matrix mapping the baff global frame
        %to the AVL frame (X=fwd, Y=right, Z=up). Default is identity.
        CoordTransform (3,3) double = eye(3);

        % --- Reference quantities ---
        %Sref, Cref, Bref: reference area, chord, span used to normalise
        %aerodynamic coefficients.  Set NaN to auto-compute from geometry.
        Sref (1,1) double = NaN;
        Cref (1,1) double = NaN;
        Bref (1,1) double = NaN;

        %Xref, Yref, Zref: reference point (moment centre / CG location).
        %Set NaN to auto-compute (uses the global LE of the root section).
        Xref (1,1) double = NaN;
        Yref (1,1) double = NaN;
        Zref (1,1) double = NaN;

        % --- Freestream ---
        %Mach: default Mach number for Prandtl-Glauert correction.
        Mach (1,1) double = 0;

        % --- Discretisation ---
        %Nchord: number of chordwise horseshoe vortices per surface.
        Nchord (1,1) double = 8;

        %Cspace: chordwise vortex spacing parameter.
        %  1.0 = cosine (recommended),  0.0 / 3.0 = uniform.
        Cspace (1,1) double = 1.0;

        %Nspan: number of spanwise vortices per surface.
        %  Empty [] means the per-section Nspan set by SspacePerSection
        %  will be used instead.  Set a positive integer to override.
        Nspan (:,1) double = [];

        %Sspace: spanwise vortex spacing parameter.
        % -2.0 = -sine (cosine across full span, recommended for straight
        %        wings defined root→tip).
        %  1.0 = cosine.
        Sspace (1,1) double = -2.0;

        %NspanPerSection: number of spanwise vortices in each section
        %interval (used when Nspan is empty).
        NspanPerSection (1,1) double = 10;

        % --- Execution ---
        %AvlExePath: path to the AVL executable.  'avl' assumes it is on
        %the system PATH.
        AvlExePath (1,1) string = "avl";

        %ShowGeometryPlot: if true, run a separate AVL instance on the
        %.avl file before the batch analysis so the geometry plot can be
        %inspected interactively.
        ShowGeometryPlot (1,1) logical = false;

        % --- Optional outputs ---
        %WriteMassFile: if true, AvlModel.build() also writes a .mass file
        %from baff.Mass elements and distributed aerodynamic mass.
        WriteMassFile (1,1) logical = false;
    end

    methods
        function obj = AvlOpts(opts)
            arguments
                opts.?ads.avl.AvlOpts
            end
            for prop = string(fieldnames(opts))'
                obj.(prop) = opts.(prop);
            end
        end
    end
end
