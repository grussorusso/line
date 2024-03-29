function RD = getCdfRespT(self, R)
% RD = GETCDFRESPT(R)

if ~exist('R','var')
    R = self.model.getAvgRespTHandles();
end
RD = cell(self.model.getNumberOfStations, self.model.getNumberOfClasses);
QN = self.getAvgQLen(); % steady-state qlen
qn = self.getStruct;
n = QN;
for r=1:qn.nclasses
    if isinf(qn.njobs(r))
        n(:,r) = floor(QN(:,r));
    else
        n(:,r) = floor(QN(:,r));
        if sum(n(:,r)) < qn.njobs(r)
            imax = maxpos(n(:,r)); % put jobs on the bottleneck
            n(imax,r) = n(imax,r) + qn.njobs(r) - sum(n(:,r));
        end
    end
end
cdfmodel = self.model.copy;
cdfmodel.resetNetwork;
cdfmodel.initFromMarginal(n);
isNodeClassLogged = false(cdfmodel.getNumberOfNodes, cdfmodel.getNumberOfClasses);
for i= 1:cdfmodel.getNumberOfStations
    for r=1:cdfmodel.getNumberOfClasses
        if ~R{i,r}.disabled
            ni = self.model.getNodeIndex(cdfmodel.getStationNames{i});
            isNodeClassLogged(ni,r) = true;
        end
    end
end
Plinked = self.model.getLinkedRoutingMatrix();
isNodeLogged = max(isNodeClassLogged,[],2);
logpath = tempdir;
cdfmodel.linkAndLog(Plinked, isNodeLogged, logpath);
SolverJMT(cdfmodel, self.getOptions).getAvg(); % log data
logData = SolverJMT.parseLogs(cdfmodel, isNodeLogged, Metric.RespT);
% from here convert from nodes in logData to stations
for i= 1:cdfmodel.getNumberOfStations
    ni = cdfmodel.getNodeIndex(cdfmodel.getStationNames{i});
    for r=1:cdfmodel.getNumberOfClasses
        if isNodeClassLogged(ni,r)
            if ~isempty(logData{ni,r})
                [F,X] = ecdf(logData{ni,r}.RespT);
                RD{i,r} = [F,X];
            end
        end
    end
end
end