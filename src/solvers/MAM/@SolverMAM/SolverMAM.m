classdef SolverMAM < NetworkSolver
    % A solver based on matrix-analytic methods.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods
        function self = SolverMAM(model,varargin)
            % SELF = SOLVERMAM(MODEL,VARARGIN)
            
            self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
        end
        
        runtime = run(self, options);
        RD = getCdfRespT(self, R);
    end
    
    methods (Static)
        function featSupported = getFeatureSet()
            % FEATSUPPORTED = GETFEATURESET()
            
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Sink','Source',...
                'DelayStation','Queue',...
                'APH','Coxian','Erlang','Exponential','HyperExp',...
                'StatelessClassSwitcher','InfiniteServer',...
                'ClassSwitch', ...
                'SharedServer','Buffer','Dispatcher',...
                'Server','JobSink','RandomSource','ServiceTunnel',...
                'SchedStrategy_INF','SchedStrategy_PS','SchedStrategy_HOL',...
                'SchedStrategy_FCFS',...
                'RoutingStrategy_PROB','RoutingStrategy_RAND',...
                'OpenClass'});       
                %'Fork',...
                %'Join',...
                %'Forker',...
                %'Joiner',...
        end
        
        function [bool, featSupported] = supports(model)
            % [BOOL, FEATSUPPORTED] = SUPPORTS(MODEL)
            
            featUsed = model.getUsedLangFeatures();
            featSupported = SolverMAM.getFeatureSet();
            bool = SolverFeatureSet.supports(featSupported, featUsed);
        end
        
        function checkOptions(options)
            % CHECKOPTIONS(OPTIONS)
            
            solverName = mfilename;
            if isfield(options,'timespan')  && isfinite(options.timespan(2))
                error('Finite timespan not supported in %s',solverName);
            end
        end
        
        function options = defaultOptions()
            % OPTIONS = DEFAULTOPTIONS()
            options = lineDefaults('MAM');
        end
    end
end
