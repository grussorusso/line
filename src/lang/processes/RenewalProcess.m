classdef RenewalProcess < PointProcess
    % Copyright (c) 2018, Imperial College London
    % All rights reserved.
    
    properties
        distrib;
    end
    
    methods (Hidden)
        %Constructor
        function self = RenewalProcess(distrib)
            self = self@PointProcess('RenewalProcess',1);
            setParam(self, 1, 'distrib', distrib, 'java.lang.Double');
        end
    end
    
    methods        
        function mt = getMeanT(self, t, steps)
            distrib =  self.getParam(1).paramValue;
            if ~exist('steps','var')
                steps = t/distrib.getMean()*20;
            end
            tmax = max(t);
            tmax = tmax + tmax/steps; % add one step for evalCDFInterval
            trange = unique([0:tmax/steps:tmax,t(:)']);
            
            mt = zeros(1,length(trange)-1);
            for ti=1:(length(trange)-1)
                mt(ti) = distrib.evalCDF(trange(ti));
                for si=1:(ti-1)
                    mt(ti) = mt(ti) +  mt(ti-si)*(distrib.evalCDFInterval(trange(si),trange(si+1)));
                end
            end
        end
        
        function vart = getVarT(self,t)
            
        end
        
        function mean = getMean(self)
            distrib =  self.getParam(1).paramValue;
            mean = distrib.getMean;
        end
    end
end
