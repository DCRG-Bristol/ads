classdef BaffOpts
    properties
        SplitBeamsAtChildren = true;
        GenerateAeroPanels = true;
        GenCoordSys = true;
        ChildAttachmentMethod = ads.baff.ChildAttachmentMethod.Closest;
        SeperateSplineForControlSurfaces = false;
    end
end