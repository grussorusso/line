classdef Queue < Station
    % A service station with queueing
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        schedPolicy;
        schedStrategy;
        schedStrategyPar;
        serviceProcess;
    end
    
    methods
        %Constructor
        function self = Queue(model, name, schedStrategy)
            % SELF = QUEUE(MODEL, NAME, SCHEDSTRATEGY)
            
            self@Station(name);
            
            classes = model.classes;
            self.input = Buffer(classes);
            self.output = Dispatcher(classes);
            self.schedPolicy = SchedStrategyType.PR;
            self.schedStrategy = SchedStrategy.PS;
            self.serviceProcess = {};
            self.server = Server(classes);
            self.numberOfServers = 1;
            self.schedStrategyPar = zeros(1,length(model.classes));
            self.setModel(model);
            self.model.addNode(self);
            
            if exist('schedStrategy','var')
                self.schedStrategy = schedStrategy;
                switch schedStrategy
                    case {SchedStrategy.PS, SchedStrategy.DPS,SchedStrategy.GPS}
                        self.schedPolicy = SchedStrategyType.PR;
                        self.server = SharedServer(classes);
                    case {SchedStrategy.FCFS, SchedStrategy.LCFS, SchedStrategy.RAND, SchedStrategy.SEPT, SchedStrategy.LEPT, SchedStrategy.SJF, SchedStrategy.LJF}
                        self.schedPolicy = SchedStrategyType.NP;
                        self.server = Server(classes);
                    case SchedStrategy.INF
                        self.schedPolicy = SchedStrategyType.NP;
                        self.server = InfiniteServer(classes);
                        self.numberOfServers = Inf;
                    case SchedStrategy.HOL
                        self.schedPolicy = SchedStrategyType.NP;
                        self.server = Server(classes);
                    otherwise
                        error(sprintf('The specified scheduling strategy (%s) is unsupported.',schedStrategy));
                end
            end
        end
        
        function setNumberOfServers(self, value)
            % SETNUMBEROFSERVERS(VALUE)
            
            self.setNumServers(value);
        end
        
        function setNumServers(self, value)
            % SETNUMSERVERS(VALUE)
            
            switch self.schedStrategy
                case {SchedStrategy.DPS, SchedStrategy.GPS}
                    if value ~= 1
                        error('Cannot use multi-server stations with %s scheduling.', self.schedStrategy);
                    end
                otherwise
                    self.numberOfServers = value;
            end
        end
        
        function self = setStrategyParam(self, class, weight)
            % SELF = SETSTRATEGYPARAM(CLASS, WEIGHT)
            
            self.schedStrategyPar(class.index) = weight;
        end
        
        function distribution = getService(self, class)
            % DISTRIBUTION = GETSERVICE(CLASS)
            
            % return the service distribution assigned to the given class
            if ~exist('class','var')
                for s = 1:length(self.model.classes)
                    distribution{s} = self.server.serviceProcess{1, self.model.classes{s}}{3};
                end
                
            else
                try
                    distribution = self.server.serviceProcess{1, class.index}{3};
                catch ME
                    distribution = [];
                    warning('No distribution is available for the specified class');
                end
            end
        end
        
        function setService(self, class, distribution, weight)
            % SETSERVICE(CLASS, DISTRIBUTION, WEIGHT)
            if ~exist('weight','var')
                weight=1.0;
            end
            
            resetInitState = false;
            if length(self.server.serviceProcess) >= class.index
                if length(self.server.serviceProcess{1,class.index})>= 3
                    resetInitState = true; % must be carried out at the end
                end
            end
            
            self.serviceProcess{class.index} = distribution;
            self.server.serviceProcess{1, class.index}{2} = ServiceStrategy.LI;
            if distribution.isImmediate()
                self.server.serviceProcess{1, class.index}{3} = Immediate();
            else
                self.server.serviceProcess{1, class.index}{3} = distribution;
            end
            if length(self.classCap) < class.index
                self.classCap((length(self.classCap)+1):class.index) = Inf;
            end
            self.setStrategyParam(class, weight);
            if resetInitState
                self.model.initDefault(self.model.getNodeIndex(self));
            end
        end
        
        function sections = getSections(self)
            % SECTIONS = GETSECTIONS()
            
            sections = {self.input, self.server, self.output};
        end
        
        function distrib = getServiceProcess(self, oclass)
            distrib = self.serviceProcess{oclass};
        end
        
    end
end
