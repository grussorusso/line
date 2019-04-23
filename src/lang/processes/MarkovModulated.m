classdef MarkovModulated < PointProcess
    % An abstract class for Markov-modulated processes
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods (Hidden)
        %Constructor
        function self = MarkovModulated(name, numParam)
            % SELF = MARKOVMODULATED(NAME, NUMPARAM)
            
            self@PointProcess(name, numParam);
        end
    end
    
    methods
        function X = sample(self, n)
            % X = SAMPLE(SELF, N)
            
            if ~exist('n','var'), n = 1; end
            X = map_sample(self.getRepresentation,n);
        end
    end
    
    methods %(Abstract) % implemented with errors for Octave compatibility
        function phases = getNumberOfPhases(self)
            % PHASES = GETNUMBEROFPHASES(SELF)
            
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function MAP = getRepresentation(self)
            % MAP = GETREPRESENTATION(SELF)
            
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
    end
    
    methods (Static)
        function cx = fit(MEAN, SCV)
            % CX = FIT(MEAN, SCV)
            
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
    end
    
end

