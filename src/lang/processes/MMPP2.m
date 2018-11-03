classdef MMPP2 < MarkovModulated
    % Copyright (c) 2018, Imperial College London
    % All rights reserved.
    
    methods
        %Constructor
        function self = MMPP2(lambda0,lambda1,sigma0,sigma1)
            self = self@MarkovModulated('MMPP2',4);
            setParam(self, 1, 'lambda0', lambda0, 'java.lang.Double');
            setParam(self, 2, 'lambda1', lambda1, 'java.lang.Double');
            setParam(self, 3, 'sigma0', sigma0, 'java.lang.Double');
            setParam(self, 4, 'sigma1', sigma1, 'java.lang.Double');
            self.javaClass = 'jmt.engine.random.MMPP2Distr';
            self.javaParClass = 'jmt.engine.random.MMPP2Par';
        end
        
        function meant = getMeanT(self,t)
            lambda0 =  self.getParam(1).paramValue;
            lambda1 =  self.getParam(2).paramValue;
            sigma0 =  self.getParam(3).paramValue;
            sigma1 =  self.getParam(4).paramValue;
            lambda = (lambda0*sigma1 + lambda1*sigma0) / (sigma0+sigma1);
            meant = lambda * t;
        end
        
        function vart = getVarT(self,t)
            lambda0 =  self.getParam(1).paramValue;
            lambda1 =  self.getParam(2).paramValue;
            sigma0 =  self.getParam(3).paramValue;
            sigma1 =  self.getParam(4).paramValue;
            MAP = getRenewalProcess;
            D0 = MAP{1};
            D1 = MAP{2};
            e = [1;1];
            pie = map_pie(MAP);
            I = eye(2);
            lambda = (lambda0*sigma1 + lambda1*sigma0) / (sigma0+sigma1);
            vart = lambda*t;
            vart = vart + 2*t*(lambda^2-pie*D1*inv(D0+D1+pie*e)*D1*e);
            vart = vart + 2*pi*D1*(expm((D0+D1)*t)-I)*inv(D0+D1+pie*e)^2*D1*e;
        end
        
        % inter-arrival time properties
        function mean = getMean(self)
            lambda0 =  self.getParam(1).paramValue;
            lambda1 =  self.getParam(2).paramValue;
            sigma0 =  self.getParam(3).paramValue;
            sigma1 =  self.getParam(4).paramValue;
            lambda = (lambda0*sigma1 + lambda1*sigma0) / (sigma0+sigma1);
            mean = 1 / lambda;
        end
        
        function scv = getSCV(self)
            lambda0 =  self.getParam(1).paramValue;
            lambda1 =  self.getParam(2).paramValue;
            sigma0 =  self.getParam(3).paramValue;
            sigma1 =  self.getParam(4).paramValue;
            scv = (2*lambda0^2*sigma0*sigma1 + lambda0*lambda1*sigma0^2 - 2*lambda0*lambda1*sigma0*sigma1 + lambda0*lambda1*sigma1^2 + lambda0*sigma0^2*sigma1 + 2*lambda0*sigma0*sigma1^2 + lambda0*sigma1^3 + 2*lambda1^2*sigma0*sigma1 + lambda1*sigma0^3 + 2*lambda1*sigma0^2*sigma1 + lambda1*sigma0*sigma1^2)/((sigma0 + sigma1)^2*(lambda0*lambda1 + lambda0*sigma1 + lambda1*sigma0));
        end
        
        function id = getID(self) % asymptotic index of dispersion
            lambda0 =  self.getParam(1).paramValue;
            lambda1 =  self.getParam(2).paramValue;
            sigma0 =  self.getParam(3).paramValue;
            sigma1 =  self.getParam(4).paramValue;
            id = 1 + 2*(lambda0-lambda1)^2*sigma0*sigma1/(sigma0+sigma1)^2/(lambda0*sigma1+lambda1*sigma0);
        end
        
        function PH = getRenewalProcess(self)
			PH = map_renewal(self.getProcess(self));
		end
		
        function MAP = getProcess(self)
            lambda0 =  self.getParam(1).paramValue;
            lambda1 =  self.getParam(2).paramValue;
            sigma0 =  self.getParam(3).paramValue;
            sigma1 =  self.getParam(4).paramValue;
            D0 = [-sigma0,sigma0;sigma1,-sigma1];
            D1 = [lambda0,0;0,lambda1];
            MAP = {D0,D1};
        end
        
        function n = getNumberOfPhases(self)
            n = 2;
        end
        
        function bool = isImmmediate(self)
            bool = self.getMean() == 0;
        end
    end    
end