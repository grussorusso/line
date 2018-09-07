function AvgTableNet = example_cacheModel_5_sub1(S,N,pHit)
network = Network('network');

mainDelay = DelayStation(network, 'MainDelay');
hitDelay = QueueingStation(network, 'HitQ', SchedStrategy.PS);
missDelay = QueueingStation(network, 'MissQ', SchedStrategy.PS);

jobClass1 = ClosedClass(network, 'InitClass1', N(1), mainDelay, 0);
jobClass2 = ClosedClass(network, 'InitClass2', N(2), mainDelay, 0);

mainDelay.setService(jobClass1, Exp.fitMean(S(1,1))); 
 hitDelay.setService(jobClass1, Exp.fitMean(S(2,1))); 
missDelay.setService(jobClass1, Exp.fitMean(S(3,1)));

mainDelay.setService(jobClass2, Exp.fitMean(S(1,2))); 
 hitDelay.setService(jobClass2, Exp.fitMean(S(2,2))); 
missDelay.setService(jobClass2, Exp.fitMean(S(3,2)));

P = {};
for r=1:network.getNumberOfClasses
    P{r} = [0,pHit(r),1-pHit(r); 1,0,0; 1,0,0];
end
P{:}
network.link(P);
AvgTableNet = SolverMVA(network,'method','exact').getAvgTable;
end