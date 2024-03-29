%% getAvgHandles: add all mean performance indexes
% Q(i,r): mean queue-length of class r at node i
% U(i,r): mean utilization of class r at node i
% R(i,r): mean response time of class r at node i (summed across visits)
% T(i,r): mean throughput of class r at node i
% A(i,r): mean arrival rate of class r at node i
function [Q,U,R,T,A] = getAvgHandles(self)
% [Q,U,R,T,A] = GETAVGHANDLES()

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
Q = self.getAvgQLenHandles;
U = self.getAvgUtilHandles;
R = self.getAvgRespTHandles;
T = self.getAvgTputHandles;
A = self.getAvgArvRHandles;
end
