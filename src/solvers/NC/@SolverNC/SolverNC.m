classdef SolverNC < NetworkSolver
    % A solver based on normalizing constant methods.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods
        function self = SolverNC(model,varargin)
            % SELF = SOLVERNC(MODEL,VARARGIN)
            
            self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
        end
        
        runtime = run(self, options)
        Pnir = getProb(self, node, state)
        Pnir = getProbAggr(self, node, state_a)
        Pn   = getProbSys(self)        
        Pn   = getProbSysAggr(self)
        
        [lNormConst] = getProbNormConstAggr(self)
    end
    
    methods (Static)
        function featSupported = getFeatureSet()
            % FEATSUPPORTED = GETFEATURESET()
            
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Sink','Source',...
                'ClassSwitch','DelayStation','Queue',...
                'APH','Coxian','Erlang','Exponential','HyperExp',...
                'StatelessClassSwitcher','InfiniteServer',...
                'SharedServer','Buffer','Dispatcher',...
                'Server','JobSink','RandomSource','ServiceTunnel',...
                'SchedStrategy_INF','SchedStrategy_PS','SchedStrategy_RAND',...
                'RoutingStrategy_PROB','RoutingStrategy_RAND',...
                'SchedStrategy_FCFS','ClosedClass'});
        end
        
        function [bool, featSupported] = supports(model)
            % [BOOL, FEATSUPPORTED] = SUPPORTS(MODEL)
            
            featUsed = model.getUsedLangFeatures();
            featSupported = SolverNC.getFeatureSet();
            bool = SolverFeatureSet.supports(featSupported, featUsed);
        end

        function checkOptions(options)
            % CHECKOPTIONS(OPTIONS)            
            solverName = mfilename;
            if isfield(options,'timespan') && isfinite(options.timespan(2))
                error('Finite timespan not supported in %s',solverName);
            end
        end
        
        function options = defaultOptions()
            % OPTIONS = DEFAULTOPTIONS()
            options = lineDefaults('NC');
        end
    end
end
