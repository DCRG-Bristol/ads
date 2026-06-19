classdef AvlModel < handle
    %AVLMODEL Holds an AVL vortex-lattice model converted from a baff.Model.
    %
    %   Typical workflow (mirrors ads.nast.Sol103):
    %
    %     model   = UniformBaffWing();
    %     opts    = ads.avl.AvlOpts(Symmetry=true);
    %     avlMdl  = ads.avl.baff2avl(model, opts);
    %     folder  = avlMdl.build('ex_uw_avl');
    %     avlMdl.run(folder, alpha=5, beta=0);
    %     derivs  = ads.avl.readDerivatives(folder);
    %
    %   See also: ads.avl.baff2avl, ads.avl.AvlOpts, ads.avl.readDerivatives

    properties
        %Name: used as the base filename (e.g. 'model' → 'model.avl').
        Name (1,1) string = "model";

        %Opts: AvlOpts used when building this model.
        Opts ads.avl.AvlOpts = ads.avl.AvlOpts();

        %Surfaces: struct array, one entry per AVL SURFACE block.
        %  Each entry has fields: Name (string), Text (string).
        Surfaces struct = struct('Name', {}, 'Text', {});

        %Bodies: struct array, one entry per AVL BODY block.
        %  Each entry has fields: Name (string), Text (string).
        Bodies struct = struct('Name', {}, 'Text', {});

        %RefQuantities: struct with fields Sref, Cref, Bref, Xref, Yref, Zref.
        RefQuantities struct = struct('Sref', 1, 'Cref', 1, 'Bref', 1, ...
                                     'Xref', 0, 'Yref', 0, 'Zref', 0);
    end

    methods
        function obj = AvlModel(name, opts)
            %AvlModel constructor.
            arguments
                name (1,1) string = "model";
                opts ads.avl.AvlOpts = ads.avl.AvlOpts();
            end
            obj.Name  = name;
            obj.Opts  = opts;
        end

        function plotGeometry(obj, BinFolder)
            %PLOTGEOMETRY  Open AVL on the built geometry file.

            arguments
                obj ads.avl.AvlModel
                BinFolder (1,1) string
            end

            BinFolder = ads.avl.resolveFolderPath(BinFolder);
            avlFile = fullfile(BinFolder, 'Source', [char(obj.Name), '.avl']);

            if ~exist(avlFile, 'file')
                error('ads:avl:plotGeometry', ...
                    'AVL input file not found: %s\nCall build() first.', avlFile);
            end

            avlExe = char(obj.Opts.AvlExePath);
            if ispc
                system(sprintf('start "" "%s" "%s"', avlExe, avlFile));
            else
                system(sprintf('"%s" "%s" &', avlExe, avlFile));
            end
        end
    end
end
