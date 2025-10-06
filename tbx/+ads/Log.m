classdef Log < handle
    properties (Constant)
        instance = ads.Log()
    end
    properties
        level ads.util.LogLevel = ads.util.LogLevel.Trace
    end
    methods (Access = private)
        function obj = Log()
        end
    end
    methods(Static)
        function val = getLevel()
            val = ads.Log.instance.level;
        end
        function setLevel(level)
            arguments
                level (1,1) ads.util.LogLevel
            end
            obj = ads.Log.instance;
            obj.level = level;
        end
        function trace(message,Symbol)
            arguments
                message string
                Symbol string = " "
            end
            obj = ads.Log.instance;
            if obj.level <= ads.util.LogLevel.Trace
                ads.util.printing.title(message,Symbol=Symbol);
            end
        end
        function debug(message,Symbol)
            arguments
                message string
                Symbol string = "-"
            end
            obj = ads.Log.instance;
            if obj.level <= ads.util.LogLevel.Debug
                ads.util.printing.title(message,Symbol=Symbol);
            end
        end
        function info(message,Symbol)
            arguments
                message string
                Symbol string = "="
            end
            obj = ads.Log.instance;
            if obj.level <= ads.util.LogLevel.Info
                ads.util.printing.title(message,Symbol=Symbol);
            end
        end
        function warn(message,Symbol)
            arguments
                message string
                Symbol string = "~"
            end
            obj = ads.Log.instance;
            if obj.level <= ads.util.LogLevel.Warn
                ads.util.printing.title(message,Symbol=Symbol);
            end
        end
        function error(message,Symbol)
            arguments
                message (1,1) string
                Symbol (1,1) string = "%"
            end
            obj = ads.Log.instance;
            if obj.level <= ads.util.LogLevel.Error
                ads.util.printing.title(message,Symbol=Symbol);
            end
        end
        function fatal(message)
            obj = ads.Log.instance;
            if obj.level <= ads.util.LogLevel.Fatal
                ads.util.printing.title(message,Symbol="X",Padding=1);
            end
        end
    end
end