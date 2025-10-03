classdef (Abstract) BaseSol < handle
    %FLUTTERSIM Summary of this class goes here
    %   Detailed explanation goes here
    properties(Abstract)
        Name char
    end
    properties
        % generic parameters
        WriteToF06 = true; % if false minimises whats written to f06.

        % grav info
        LoadFactor = 1;
        g = 9.81;
        Grav_Vector = [0;0;1];

        SPCs = [];

        DispIDs = inf;       % IDs of displacements to output, if nan none output, if inf all output, if a list those IDs
        ForceIDs = inf;      % IDs of forces to output, if nan none output, if inf all output, if a list those IDs
        StressIDs = nan;     % IDs of stresses to output, if nan none output, if inf all output, if a list those IDs
        StrainIDs = nan;     % IDs of strains to output, if nan none output, if inf all output, if a list those IDs

        % CoM Info for Boundary Constraints
        isFree = false; % if is Free a Boundary condition will be applied to  the Centre of Mass
        CoM ads.fe.Constraint = ads.fe.Constraint.empty;
        DoFs = [];
    end

    
    methods(Abstract)
        ids = UpdateID(obj,ids)

        write_main_bdf(obj,filename,includes,feModel)
    end

    methods
        function str = config_string(obj)
            str = '';
        end
    end
end

