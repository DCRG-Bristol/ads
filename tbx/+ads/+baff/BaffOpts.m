classdef BaffOpts
    properties
        SplitBeamsAtChildren = true;
        GenerateAeroPanels = true;
        GenCoordSys = true;
        ChildAttachmentMethod = ads.baff.ChildAttachmentMethod.Closest;
        SeperateSplineForControlSurfaces = false;
        IncludeAeroAddedMass = false;
        AirDensity = 1.225;
        AddedMassStations = 100;
    end
    methods
        function obj = BaffOpts(opts)
            arguments
                opts.?ads.baff.BaffOpts
            end
            for prop = string(fieldnames(opts))'
                obj.(prop) = opts.(prop);
            end
        end
    end
end