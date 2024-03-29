function [result, parsed] = getResultsJSIM(self)
% [RESULT, PARSED] = GETRESULTSJSIM()

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

%try
fileName = strcat(self.getFilePath(),'jsimg',filesep,self.getFileName(),'.jsimg-result.jsim');
if exist(fileName,'file')
    Pref.Str2Num = 'always';
    parsed = xml_read(fileName,Pref);
else
    error('JMT did not output a result file, the simulation has likely failed.');
end
%catch me
%me.p
%    error('Unknown error upon parsing JMT result file. ');
%end
self.result.('solver') = self.getName();
self.result.('model') = parsed.ATTRIBUTE;
self.result.('metric') = {parsed.measure.ATTRIBUTE};

result = self.result;
end
