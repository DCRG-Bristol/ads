classdef Sol146 < handle
    %FLUTTERSIM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % generic aero parameters
        Name = 'Default SOL146: ';
        LoadFactor = 1;
        DoFs = [];
        V = 0;
        rho = 0;
        Mach = 0;
        AEQR = 1;
        ACSID = [];

        RefChord = 1;
        RefSpan = 1;
        RefArea = 1;
        RefDensity = 1.225;
        LModes = 0;

        % freqeuency & Structural Damping Info
        FreqRange = [0.01,50];
        NFreq = 500;
        ModalDampingPercentage = 0;
        GustFreq = [];

        DispIDs = [];
        ForceIDs = [];

        % gust data
        Gusts = ads.nast.GustSettings.empty;
        GustDuration = 5;
        GustTstep = 0.01;

        SDAMP_ID = 4;
        FREQ_ID = 5;
        TSTEP_ID = 6;
        EigR_ID = 7;
        DAREA_ID = 8;
        SPC_ID = 9;

        SPCs = [];
        ReducedFreqs = [0.01,0.05,0.1,0.2,0.5,0.75,1,2,4];

        %CoM and constraint Paramters
        CoM_gp = 1;
        CoM_GID = 99999999;
        CoM_Cp = [];
        CoM = [0;0;0];
    end
    
    methods
        function obj = Sol146(CoM_GID)
            obj.CoM_GID = CoM_GID;
        end
        function ids = UpdateID(obj,ids)
                obj.SDAMP_ID = ids.SID;
                obj.FREQ_ID = ids.SID + 1;
                obj.TSTEP_ID = ids.SID + 2;
                obj.EigR_ID = ids.SID + 3;
                obj.SPC_ID = ids.SID + 4;
                obj.DAREA_ID = ids.SID + 5;
                ids.SID = ids.SID + 6;
                ids = obj.Gusts.UpdateID(ids);
        end
        function str = config_string(obj)
            str = '';
        end
        function set_trim_steadyLevel(obj,V,rho,Mach)
            obj.V = V;
            obj.rho = rho;
            obj.Mach = Mach;
            obj.ANGLEA.Value = NaN;
            obj.URDD3.Value = 0;
            obj.DoFs = 35;
        end
        function set_trim_locked(obj,V,rho,Mach)
            obj.V = V;
            obj.rho = rho;
            obj.Mach = Mach;
            obj.ANGLEA.Value = 0;
            obj.DoFs = [];
        end
    end
end

