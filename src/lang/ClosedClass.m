classdef ClosedClass < JobClass
    % A class of jobs that perpetually cycle inside the model.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        population;
    end
    
    methods
        
        %Constructor
        function self = ClosedClass(model, name, njobs, refstat, prio)
            % SELF = CLOSEDCLASS(MODEL, NAME, NJOBS, REFSTAT, PRIO)
            
            self@JobClass('closed', name);
            
            self.type = 'closed';
            self.population = njobs;
            self.priority = 0;
            if exist('prio','var')
                self.priority = prio;
            end
            model.addJobClass(self);
            if ~isa(refstat, 'Station')
                error('The reference station for class %s needs to be a station, not a node.', name);
            end
            setReferenceStation(self, refstat);
            % set default scheduling for this class at all nodes
            for i=1:length(model.nodes)
                if ~isempty(model.nodes{i}) && ~isa(model.nodes{i},'Source') && ~isa(model.nodes{i},'Sink') && ~isa(model.nodes{i},'Join')&& ~isa(model.nodes{i},'CacheNode')
                    model.nodes{i}.setScheduling(self, SchedStrategy.FCFS);
                end
                if isa(model.nodes{i},'Join')
                    model.nodes{i}.setStrategy(self,JoinStrategy.Standard);
                    model.nodes{i}.setRequired(self,-1);
                end
                if ~isempty(model.nodes{i})
                    %                    && (isa(model.nodes{i},'Queue') || isa(model.nodes{i},'Router'))
                    model.nodes{i}.setRouting(self, RoutingStrategy.DISABLED);
                end
            end
        end
        
        function setReferenceStation(class, source)
            % SETREFERENCESTATION(CLASS, SOURCE)
            
            setReferenceStation@JobClass(class, source);
        end
    end
    
end

