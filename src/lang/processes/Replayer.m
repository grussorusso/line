classdef Replayer < TimeSeries
    % Empirical time series from a trace
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        data;
    end
    
    methods
        %Constructor
        function self = Replayer(fileName)
            % SELF = REPLAYER(FILENAME)
            
            self@TimeSeries('Replayer',1);
            setParam(self, 1, 'fileName', fileName, 'java.lang.String');
            if ischar(fileName)
                self.data = [];
                % JMT requires full file
                javaFileObj = java.io.File(fileName);
                if ~javaFileObj.isAbsolute()
                    fileName = fullfile(pwd,fileName); %#ok<NASGU>
                end
                %                self.javaClass = 'jmt.engine.random.Replayer';
                %                self.javaParClass = 'jmt.engine.random.ReplayerPar';
            end
        end
        
        function load(self)
            % LOAD(SELF)
            
            fileName = self.getParam(1).paramValue;
            self.data = load(fileName);
            self.data = self.data(:);
        end
        
        function unload(self)
            % UNLOAD(SELF)
            
            self.data = [];
        end
        
        function ex = getMean(self)
            % EX = GETMEAN(SELF)
            
            % Get distribution mean
            if isempty(self.data)
                self.load();
            end
            ex = mean(self.data);
        end
        
        function SCV = getSCV(self)
            % SCV = GETSCV(SELF)
            
            % Get distribution squared coefficient of variation (SCV = variance / mean^2)
            if isempty(self.data)
                self.load();
            end
            SCV = var(self.data)/mean(self.data)^2;
        end
        
        function SKEW = getSkewness(self)
            % SKEW = GETSKEWNESS(SELF)
            
            % Get distribution skewness
            if isempty(self.data)
                self.load();
            end
            SKEW = skewness(self.data);
        end
        
        function distr = fitExp(self)
            % DISTR = FITEXP(SELF)
            
            distr = Exp.fitMean(self.getMean);
        end
        
        function distr = fitAPH(self)
            % DISTR = FITAPH(SELF)
            
            distr = APH.fitCentral(self.getMean, self.getVariance, self.getSkewness);
        end
        
        function distr = fitCoxian(self)
            % DISTR = FITCOXIAN(SELF)
            
            distr = Cox2.fitCentral(self.getMean, self.getVariance, self.getSkewness);
        end
    end
end

