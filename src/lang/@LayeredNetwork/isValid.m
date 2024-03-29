function bool = isValid(self)
% BOOL = ISVALID()

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
bool = true;
lqnGraph = self.getGraph();
refTasks = findstring(lqnGraph.Nodes.Type, 'R');
for r=refTasks(:)'
    numEntriesInRefTask = intersect(findstring(lqnGraph.Nodes.Type, 'E'), findstring(lqnGraph.Nodes.Task, lqnGraph.Nodes.Name{r}));
    if length(numEntriesInRefTask)>1
        warning('Reference task %d should have a single entry, load balancing with equal probabilities across entries.', r);
    end
end
end
