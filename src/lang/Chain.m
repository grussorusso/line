classdef Chain < matlab.mixin.Copyable
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
    
    properties
        name;
        classes;
        classnames;
        visits;
        index; % index within model
		completes;
        njobs;
    end
    
    methods
        %Constructor
        function self = Chain(name)
            self.name = name;
        end
        
        function self = setName(self, name)
            self.name = name;
        end
        
        function self = setVisits(self, class, v)
            idx  = self.getClass(class.name);
            self.visits{idx} = v;
        end
                
        function self = addClass(self, class, v, index)
            if ~exist('v','var')
                v = [];
            end
            idx  = self.getClass(class.name);
            if idx>0
                self.classes{idx} = class;
                self.classnames{idx} = class.name;
                self.visits{idx} = v;
                self.index{idx} = index;
                self.completes{idx} = class.completes;
            else
                self.classes{end+1} = class;
                self.classnames{end+1} = class.name;
                self.visits{end+1} = v;
                self.index{end+1} = index;
                self.completes{end+1} = class.completes;
            end
        end
        
        function bool = hasClass(self, className)
            bool = true;
            if getClass(self, className) == -1
                bool = false;
            end
        end
        
        function idx = getClass(self, className)
            idx = -1;
            if ~isempty(self.classes)
                idx = find(cellfun(@(c) strcmpi(c.name,className), self.classes));
                if isempty(idx)
                    idx = -1;
                end
            end
        end
        
    end
    
end