classdef Sol144 < ads.nast.BaseSol
    %FLUTTERSIM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % generic aero parameters
        Name = 'SOL144';

        %trim Parameters
        ANGLEA = ads.nast.TrimParameter('ANGLEA',0,'Rigid Body');
        SIDES = ads.nast.TrimParameter('SIDES',0,'Rigid Body');
        PITCH = ads.nast.TrimParameter('PITCH',0,'Rigid Body');
        ROLL = ads.nast.TrimParameter('ROLL',0,'Rigid Body');
        YAW = ads.nast.TrimParameter('YAW',0,'Rigid Body');
        URDD1 = ads.nast.TrimParameter('URDD1',0,'Rigid Body');
        URDD2 = ads.nast.TrimParameter('URDD2',0,'Rigid Body');
        URDD3 = ads.nast.TrimParameter('URDD3',0,'Rigid Body');
        URDD4 = ads.nast.TrimParameter('URDD4',0,'Rigid Body');
        URDD5 = ads.nast.TrimParameter('URDD5',0,'Rigid Body');
        URDD6 = ads.nast.TrimParameter('URDD6',0,'Rigid Body');

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

        OutputAeroMatrices logical = false;

        % freqeuency & Structural Damping Info
        FreqRange = [0.01,50];
        NFreq = 500;
        ModalDampingPercentage = 0;

        EigR_ID = 1;
        Trim_ID = 2;
        SPC_ID = 3;
        Grav_ID = 4;
        Load_ID = 5;
    end
    
    methods
        function ids = UpdateID(obj,ids)
                obj.EigR_ID = ids.SID;
                obj.Trim_ID = ids.SID + 1;
                obj.SPC_ID = ids.SID + 2;
                obj.Grav_ID = ids.SID + 3;
                obj.Load_ID = ids.SID + 4;
                ids.SID = ids.SID + 5;
        end
        function set_trim_steadyLevel(obj,V,rho,Mach,CoM)
            arguments
                obj
                V
                rho
                Mach
                CoM ads.fe.Constraint
            end
            obj.isFree = true;
            obj.CoM = CoM;
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

