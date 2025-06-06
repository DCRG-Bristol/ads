classdef Sol145 < handle
    %FLUTTERSIM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % generic aero parameters
        Name = 'SOL145';
        LoadFactor = 1;
        V (:,1) double {mustBeNonzero}= 1;
        rho = 0;
        Mach = 0;
        AEQR = 1;
        ACSID = [];

        RefChord = 1;
        RefSpan = 1;
        RefArea = 1;
        RefDensity = 1;
        LModes = 0;

        DispIDs = [];
        ForceIDs = [];

        % freqeuency & Structural Damping Info
        FreqRange = [0.01,50];
        NFreq = 500;
        ModalDampingPercentage = 0;

        FlutterMethod = 'PK';
        FlutterID = 4;
        Flfact_mach_id = 2;
        Flfact_v_id = 3;
        Flfact_rho_id = 1;
        EigR_ID = 5;
        SPC_ID = 6;
        SDAMP_ID = 7;
        SPCs = [];
        ReducedFreqs = [0.01,0.05,0.1,0.2,0.5,0.75,1,2,4];
        ReducedMachs = []; % mach numbers to calc aero matrices at, if empty will use linear interpolation from 'Mach'

        % CoM Info for Boundary Constraints
        isFree = false; % if is Free a Boundary condition will be applied to  the Centre of Mass
        CoM = ads.fe.Constraint.empty;
        DoFs = []; 
    end    
    methods
        function ids = UpdateID(obj,ids)
                obj.FlutterID = ids.SID;
                obj.Flfact_mach_id = ids.SID + 1;
                obj.Flfact_v_id = ids.SID + 2;
                obj.Flfact_rho_id = ids.SID + 3;
                obj.EigR_ID = ids.SID + 4;
                obj.SPC_ID = ids.SID + 5;
                obj.SDAMP_ID = ids.SID + 6;
                ids.SID = ids.SID + 7;
        end
        function str = config_string(obj)
            str = '';
        end
        function set_trim_steadyLevel(obj,V,rho,Mach)
            obj.V = V;
            obj.rho = rho;
            obj.Mach = Mach;
            obj.DoFs = 35;
            obj.isFree = true;
        end
        function set_trim_locked(obj,V,rho,Mach)
            obj.V = V;
            obj.rho = rho;
            obj.Mach = Mach;
            obj.DoFs = [];
            obj.isFree = true;
        end
    end
end

