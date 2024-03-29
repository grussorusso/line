classdef LayeredNetwork < Model & Ensemble
    % A layered queueing network model.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    properties
        objects = struct();    % cell arrays of objects
        processors = cell(0,4);      % list of processors
        lqnGraph; % digraph representation of all dependencies
        taskGraph; % digraph representation of task dependencies
        layerGraph;
        clientTask;
        nodeNames;
        nodeDep; % (i,1) = procId, (i,2) = taskId, (i,3) = entryId, NaN is n/a
        endNodes;
        nodeMult;
        edgeWeight;
        param; % Avg performance metrics are input parameters in LQNs
        
        syncCall = cell(1,0);
        asyncCall = cell(1,0);
        isCall = cell(1,0);
        syncSource = cell(1,0);
        asyncSource = cell(1,0);
        syncDest = cell(1,0);
        asyncDest = cell(1,0);
        chains = cell(1,0);
        serverName = cell(1,0);
        
        usedFeatures; % cell with structures of booleans listing the used classes
        % it must be accessed via getUsedLangFeatures
    end
    
    methods
        %public methods, including constructor
        
        % constructor
        function self = LayeredNetwork(name, filename)
            % SELF = LAYEREDNETWORK(NAME, FILENAME)
            
            self@Ensemble({})
            if ~exist('name','var')
                [~,name]=fileparts(tempname);
            end
            self@Model(name);
            self.lqnGraph = [];
            self.taskGraph = [];
            self.ensemble = {};
            self.objects.processors = {};
            self.objects.tasks = {};
            self.objects.entries = {};
            self.objects.activities = {};
            self.param.Nodes.RespT = [];
            self.param.Nodes.Tput = [];
            self.param.Nodes.Util = [];
            self.param.Edges.RespT = [];
            self.param.Edges.Tput = [];
            
            if exist('filename','var')
                self = LayeredNetwork.parseXML(filename, false);
                self.init;
            end
        end
        
        function self = init(self)
            % SELF = INIT()
            
            self.generateGraph;
            self.initDefault;
            self.param.Nodes.RespT = [];
            self.param.Nodes.Tput = [];
            self.param.Nodes.Util = [];
            self.param.Nodes.QLen = [];
            self.param.Edges.RespT = [];
            self.param.Edges.Tput = [];
            self.param.Edges.QLen = [];
        end
        
        ensemble = updateEnsemble(self, isBuild, deepUpdate)
        
        self = generateGraph(self);
        [lqnGraph,taskGraph] = getGraph(self)
        self = setGraph(self,lqnGraph,taskGraph)
        [subgraphs, levels] = getGraphLayers(self, lqnGraph, taskGraph)
        
        function G = summary(self)
            % G = SUMMARY()
            
            G = self.getGraph;
        end
        
        bool = isValid(self)
        self = update(self)
        self = updateParam(self, AvgTable)
        self = initDefault(self)
        plot(self)
    end
    
    methods
        % these methods access the graph functions
        [entry, entryFullName] = findEntryOfActivity(self,activity)
        idx = findEdgeIndex(self,source,dest)
        entries = listEntriesOfTask(self,task);
        acts = listActivitiesOfEntry(self,entry);
        
        % these methods extract node data from lqnGraph.Nodes
        idx = getNodeIndex(self,node) %converted
        idx = getNodeIndexInTaskGraph(self,node)
        fullName = getNodeFullName(self,node)
        name = getNodeName(self,node,useNode)
        obj = getNodeObject(self,node)
        proc = getNodeProcessor(self,node)
        task = getNodeTask(self,nodeNameOrIdx)
        type = getNodeType(self,nodeNameOrIdx)
        
        writeSRVN(self,filename);
        writeXML(self,filename);
    end
    
    methods
        function E = getNumberOfLayers(self)
            % E = GETNUMBEROFLAYERS()
            
            E = self.getNumberOfModels();
        end
        function E = getNumberOfModels(self)
            % E = GETNUMBEROFMODELS()
            
            if isempty(self.ensemble)
                self.ensemble = self.getEnsemble();
            end
            E = length(self.ensemble);
        end
        
        function layers = getLayers(self)
            % LAYERS = GETLAYERS()
            
            layers = self.getEnsemble();
        end
        
        % setUsedFeatures : records that a certain language feature has been used
        function self = setUsedFeatures(self,e,className)
            % SELF = SETUSEDFEATURES(SELF,E,CLASSNAME)
            
            self.usedFeatures{e}.setTrue(className);
        end
        
        function self = initUsedFeatures(self)
            % SELF = INITUSEDFEATURES()
            
            for e=1:self.getNumberOfModels()
                self.usedFeatures{e} = SolverFeatureSet;
            end
        end
        
        function usedFeatures = getUsedLangFeatures(self)
            % USEDFEATURES = GETUSEDLANGFEATURES()
            
            E = self.getNumberOfLayers();
            usedFeatures = cell(1,E);
            for e=1:E
                usedFeatures{e} = self.ensemble{e}.getUsedLangFeatures;
            end
            self.usedFeatures = usedFeatures;
        end
    end
    
    methods (Static)
        myLN = parseXML(filename, verbose)
    end
end
