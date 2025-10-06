classdef Log < handle
    properties (Constant)
        instance = ads.Log()
        Symbols = [[".","~","#","#","#","#"]; [" ","-","=","#","#","#"]; [" ",":","-","#","#","#"]];
    end
    properties
        level ads.util.LogLevel = ads.util.LogLevel.Trace
        subLevel double = ads.util.LogSubLevel.Low
    end
    methods(Static)
        function [val,subVal] = getLevel()
            val = ads.Log.instance.level;
            subVal = ads.Log.instance.subLevel;
        end
        function setLevel(level,subLevel)
            arguments
                level (1,1) ads.util.LogLevel
                subLevel (1,1) ads.util.LogSubLevel = ads.util.LogSubLevel.Low
            end
            obj = ads.Log.instance;
            obj.level = level;
            obj.subLevel = subLevel;
        end
        function message(level,message,subLevel,Symbol)
            arguments
                level ads.util.LogLevel
                message string
                subLevel ads.util.LogSubLevel = ads.util.LogSubLevel.High
                Symbol string = string.empty
            end
            obj = ads.Log.instance;
            if isempty(Symbol)
                Symbol = ads.Log.Symbols(3-double(subLevel), double(level)/10 + 1);
            end
            if obj.level + obj.subLevel <= level + subLevel
                ads.util.printing.title(message,Symbol=Symbol);
            end
        end
        function trace(message,subLevel,symbol)
            arguments
                message
                subLevel = ads.util.LogSubLevel.High
                symbol = string.empty
            end
            ads.Log.message(ads.util.LogLevel.Trace,message,subLevel,symbol);
        end
        function debug(message,subLevel,symbol)
            arguments
                message
                subLevel = ads.util.LogSubLevel.High
                symbol = string.empty
            end
            ads.Log.message(ads.util.LogLevel.Debug,message,subLevel,symbol);
        end
        function info(message,subLevel,symbol)
            arguments
                message
                subLevel = ads.util.LogSubLevel.High
                symbol = string.empty
            end
            ads.Log.message(ads.util.LogLevel.Info,message,subLevel,symbol);
        end
        function warn(message,subLevel,symbol)
            arguments
                message
                subLevel = ads.util.LogSubLevel.High
                symbol = string.empty
            end
            ads.Log.message(ads.util.LogLevel.Warn,message,subLevel,symbol);
        end
        function error(message,subLevel,symbol)
            arguments
                message
                subLevel = ads.util.LogSubLevel.High
                symbol = string.empty
            end
            ads.Log.message(ads.util.LogLevel.Error,message,subLevel,symbol);
        end
        function fatal(message,subLevel,symbol)
            arguments
                message
                subLevel = ads.util.LogSubLevel.High
                symbol = string.empty
            end
            ads.Log.message(ads.util.LogLevel.Fatal,message,subLevel,symbol);
        end
    end
end