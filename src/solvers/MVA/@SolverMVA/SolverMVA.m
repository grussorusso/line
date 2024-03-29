classdef SolverMVA < NetworkSolver
    % A solver implementing mean-value analysis (MVA) methods.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods
        function self = SolverMVA(model,varargin)
            % SELF = SOLVERMVA(MODEL,VARARGIN)
            
            self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
        end
        
        runtime = run(self, options);        
        [lNormConst] = getProbNormConstAggr(self);        
        [Pnir,logPnir] = getProbAggr(self, ist);        
        [Pnir,logPn] = getProbSysAggr(self);
        
    end
    
    methods(Static)
        function featSupported = getFeatureSet()
            % FEATSUPPORTED = GETFEATURESET()
            
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Sink','Source',...
                'ClassSwitch','DelayStation','Queue',...
                'APH','Coxian','Erlang','Exponential','HyperExp',...
                'Pareto','Uniform','Det', ...
                'StatelessClassSwitcher','InfiniteServer','SharedServer','Buffer','Dispatcher',...
                'Server','JobSink','RandomSource','ServiceTunnel',...
                'SchedStrategy_INF','SchedStrategy_PS',...
                'SchedStrategy_DPS','SchedStrategy_FCFS',...
                'RoutingStrategy_PROB','RoutingStrategy_RAND',...
                'ClosedClass','OpenClass','Replayer'});
        end
        
        function [bool, featSupported] = supports(model)
            % [BOOL, FEATSUPPORTED] = SUPPORTS(MODEL)
            
            featUsed = model.getUsedLangFeatures();
            featSupported = SolverMVA.getFeatureSet();
            bool = SolverFeatureSet.supports(featSupported, featUsed);
        end
        
        function checkOptions(options)
            % CHECKOPTIONS(OPTIONS)
            
            solverName = mfilename;
            if isfield(options,'timespan')  && isfinite(options.timespan(2))
                error('Finite timespan not supported in %s',solverName);
            end
        end
        
        function options = defaultOptions(self)
            % OPTIONS = DEFAULTOPTIONS()
            
            options = Solver.defaultOptions();
            options.iter_max = 10^3;
            options.iter_tol = 10^-6;
        end
    end
end
