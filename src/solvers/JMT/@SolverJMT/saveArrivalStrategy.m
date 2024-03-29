function [simDoc, section] = saveArrivalStrategy(self, simDoc, section, currentNode)
% [SIMDOC, SECTION] = SAVEARRIVALSTRATEGY(SIMDOC, SECTION, CURRENTNODE)

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

strategyNode = simDoc.createElement('parameter');
strategyNode.setAttribute('array', 'true');
strategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategy');
strategyNode.setAttribute('name', 'ServiceStrategy');

numOfClasses = length(self.model.classes);
for i=1:numOfClasses
    currentClass = self.model.classes{i,1};
    switch currentClass.type
        case 'closed'
            refClassNode2 = simDoc.createElement('refClass');
            refClassNode2.appendChild(simDoc.createTextNode(currentClass.name));
            strategyNode.appendChild(refClassNode2);
            
            serviceTimeStrategyNode = simDoc.createElement('subParameter');
            serviceTimeStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategies.ServiceTimeStrategy');
            serviceTimeStrategyNode.setAttribute('name', 'ServiceTimeStrategy');
            subParValue = simDoc.createElement('value');
            subParValue.appendChild(simDoc.createTextNode('null'));
            serviceTimeStrategyNode.appendChild(subParValue);
            strategyNode.appendChild(serviceTimeStrategyNode);
            section.appendChild(strategyNode);
        case 'open'
            refClassNode2 = simDoc.createElement('refClass');
            refClassNode2.appendChild(simDoc.createTextNode(currentClass.name));
            strategyNode.appendChild(refClassNode2);
            
            serviceTimeStrategyNode = simDoc.createElement('subParameter');
            serviceTimeStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategies.ServiceTimeStrategy');
            serviceTimeStrategyNode.setAttribute('name', 'ServiceTimeStrategy');
            
            distributionObj = currentNode.input.sourceClasses{i}{3};
            %if isempty(distributionObj.javaParClass) % Disabled distribution
            if isa(distributionObj,'Disabled')
                subParValue = simDoc.createElement('value');
                subParValue.appendChild(simDoc.createTextNode('null'));
                serviceTimeStrategyNode.appendChild(subParValue);
            elseif (isa(distributionObj,'Coxian') && distributionObj.getNumParams == 2)|| isa(distributionObj,'APH') || (isa(distributionObj,'HyperExp') && distributionObj.getNumberOfPhases > 2)
                distributionNode = simDoc.createElement('subParameter');
                distributionNode.setAttribute('classPath', 'jmt.engine.random.PhaseTypeDistr');
                distributionNode.setAttribute('name', 'Phase-Type');
                distrParNode = simDoc.createElement('subParameter');
                distrParNode.setAttribute('classPath', 'jmt.engine.random.PhaseTypePar');
                distrParNode.setAttribute('name', 'distrPar');
                
                subParNodeAlpha = simDoc.createElement('subParameter');
                subParNodeAlpha.setAttribute('array', 'true');
                subParNodeAlpha.setAttribute('classPath', 'java.lang.Object');
                subParNodeAlpha.setAttribute('name', 'alpha');
                subParNodeAlphaVec = simDoc.createElement('subParameter');
                subParNodeAlphaVec.setAttribute('array', 'true');
                subParNodeAlphaVec.setAttribute('classPath', 'java.lang.Object');
                subParNodeAlphaVec.setAttribute('name', 'vector');
                PH=distributionObj.getRepresentation;
                alpha = map_pie(PH);
                for k=1:distributionObj.getNumberOfPhases
                    subParNodeAlphaElem = simDoc.createElement('subParameter');
                    subParNodeAlphaElem.setAttribute('classPath', 'java.lang.Double');
                    subParNodeAlphaElem.setAttribute('name', 'entry');
                    subParValue = simDoc.createElement('value');
                    subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',alpha(k))));
                    subParNodeAlphaElem.appendChild(subParValue);
                    subParNodeAlphaVec.appendChild(subParNodeAlphaElem);
                end
                
                subParNodeT = simDoc.createElement('subParameter');
                subParNodeT.setAttribute('array', 'true');
                subParNodeT.setAttribute('classPath', 'java.lang.Object');
                subParNodeT.setAttribute('name', 'T');
                T = PH{1};
                for k=1:distributionObj.getNumberOfPhases
                    subParNodeTvec = simDoc.createElement('subParameter');
                    subParNodeTvec.setAttribute('array', 'true');
                    subParNodeTvec.setAttribute('classPath', 'java.lang.Object');
                    subParNodeTvec.setAttribute('name', 'vector');
                    for j=1:distributionObj.getNumberOfPhases
                        subParNodeTElem = simDoc.createElement('subParameter');
                        subParNodeTElem.setAttribute('classPath', 'java.lang.Double');
                        subParNodeTElem.setAttribute('name', 'entry');
                        subParValue = simDoc.createElement('value');
                        subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',T(k,j))));
                        subParNodeTElem.appendChild(subParValue);
                        subParNodeTvec.appendChild(subParNodeTElem);
                    end
                    subParNodeT.appendChild(subParNodeTvec);
                end
                subParNodeAlpha.appendChild(subParNodeAlphaVec);
                distrParNode.appendChild(subParNodeAlpha);
                distrParNode.appendChild(subParNodeT);
                serviceTimeStrategyNode.appendChild(distributionNode);
                serviceTimeStrategyNode.appendChild(distrParNode);
            else
                switch class(distributionObj)
                    case 'Det'
                        javaClass = 'jmt.engine.random.DeterministicDistr';
                        javaParClass = 'jmt.engine.random.DeterministicDistrPar';
                    case 'Coxian'
                        javaClass = 'jmt.engine.random.CoxianDistr';
                        javaParClass = 'jmt.engine.random.CoxianPar';
                    case 'Erlang'
                        javaClass = 'jmt.engine.random.Erlang';
                        javaParClass = 'jmt.engine.random.ErlangPar';
                    case 'Exp'
                        javaClass = 'jmt.engine.random.Exponential';
                        javaParClass = 'jmt.engine.random.ExponentialPar';
                    case 'Gamma'
                        javaClass = 'jmt.engine.random.GammaDistr';
                        javaParClass = 'jmt.engine.random.GammaDistrPar';
                    case 'HyperExp'
                        javaClass = 'jmt.engine.random.HyperExp';
                        javaParClass = 'jmt.engine.random.HyperExpPar';
                    case 'Pareto'
                        javaClass = 'jmt.engine.random.Pareto';
                        javaParClass = 'jmt.engine.random.ParetoPar';
                    case 'Uniform'
                        javaClass = 'jmt.engine.random.Uniform';
                        javaParClass = 'jmt.engine.random.UniformPar';
                    case 'MMPP2'
                        javaClass = 'jmt.engine.random.MMPP2Distr';
                        javaParClass = 'jmt.engine.random.MMPP2Par';
                    case 'Replayer'
                        javaClass = 'jmt.engine.random.Replayer';
                        javaParClass = 'jmt.engine.random.ReplayerPar';
                end
                distributionNode = simDoc.createElement('subParameter');
                distributionNode.setAttribute('classPath', javaClass);
                distributionNode.setAttribute('name', distributionObj.name);
                serviceTimeStrategyNode.appendChild(distributionNode);
                distrParNode = simDoc.createElement('subParameter');
                distrParNode.setAttribute('classPath', javaParClass);
                distrParNode.setAttribute('name', 'distrPar');
                
                for k=1:distributionObj.getNumParams()
                    subParNode = simDoc.createElement('subParameter');
                    subParNode.setAttribute('classPath', distributionObj.getParam(k).paramClass);
                    subParNode.setAttribute('name', distributionObj.getParam(k).paramName);
                    subParValue = simDoc.createElement('value');
                    switch distributionObj.getParam(k).paramClass
                        case {'java.lang.Double'}
                            subParValue.appendChild(simDoc.createTextNode(sprintf('%f',distributionObj.getParam(k).paramValue)));
                        case {'java.lang.Long'}
                            subParValue.appendChild(simDoc.createTextNode(sprintf('%d',distributionObj.getParam(k).paramValue)));
                        case 'java.lang.String'
                            subParValue.appendChild(simDoc.createTextNode(distributionObj.getParam(k).paramValue));
                    end
                    subParNode.appendChild(subParValue);
                    distrParNode.appendChild(subParNode);
                end
                serviceTimeStrategyNode.appendChild(distrParNode);
            end
    end
    strategyNode.appendChild(serviceTimeStrategyNode);
    section.appendChild(strategyNode);
end
end
