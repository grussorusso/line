function runtime = run(self, options)
% RUNTIME = RUN()
% Run the solver

T0=tic;
if ~exist('options','var')
    options = self.getOptions;
end
QN = []; UN = [];
RN = []; TN = [];
CN = []; XN = [];
lG = NaN;

if ~self.supports(self.model)
    error('Line:FeatureNotSupportedBySolver','This model contains features not supported by the solver.');
end
Solver.resetRandomGeneratorSeed(options.seed);

[qn] = self.model.getStruct();

if (strcmp(options.method,'exact')||strcmp(options.method,'mva')) && ~self.model.hasProductFormSolution
    error('The exact method requires the model to have a product-form solution. This model does not have one. You can use Network.hasProductFormSolution() to check before running the solver.');
end
method = options.method;
if qn.nstations==2 && qn.nclasses==1 && qn.nclosedjobs == 0 % open single-class queueing system
    T0=tic;
    source_ist = qn.nodeToStation(qn.nodetype == NodeType.Source);
    queue_ist = qn.nodeToStation(qn.nodetype == NodeType.Queue);
    lambda = qn.rates(source_ist)*qn.visits{1}(queue_ist);
    k = qn.nservers(queue_ist);
    mu = qn.rates(queue_ist);
    ca = sqrt(qn.scv(source_ist));
    cs = sqrt(qn.scv(queue_ist));
    if strcmpi(method,'exact')
        if ca == 1 && cs == 1 && k==1
            method = 'mm1';
        elseif ca == 1 && cs == 1 && k>1
            method = 'mmk';
        elseif ca == 1 && k==1
            method = 'mg1';
        elseif cs == 1 && k==1
            method = 'gm1';
        else
            error('Line:MethodNotAvailable','MVA exact method unavailable for this model.');
        end
    end
    
    switch method
        case 'default'
            if k>1
                method = 'gigk';
            else
                method = 'gig1.klb';
            end
    end
    
    switch method
        case 'mm1'
            R = qsys_mm1(lambda,mu);
        case 'mmk'
            R = qsys_mmk(lambda,mu,k);
        case {'mg1', 'mgi1'}  % verified
            R = qsys_mg1(lambda,mu,cs);
        case {'gigk'}
            R = qsys_gigk_approx(lambda,mu,ca,cs,k);
        case {'gigk.kingman_approx'}
            R = qsys_gigk_approx_kingman(lambda,mu,ca,cs,k);
        case {'gig1', 'gig1.kingman'}  % verified
            R = qsys_gig1_ubnd_kingman(lambda,mu,ca,cs);
        case 'gig1.heyman'
            R = qsys_gig1_approx_heyman(lambda,mu,ca,cs);
        case 'gig1.allen'
            R = qsys_gig1_approx_allencunneen(lambda,mu,ca,cs);
        case 'gig1.kobayashi'
            R = qsys_gig1_approx_kobayashi(lambda,mu,ca,cs);
        case 'gig1.klb'
            R = qsys_gig1_approx_klb(lambda,mu,ca,cs);
            if strcmpi(options.method,'default')
                method = sprintf('default [%s]','gig1.klb');
            end
        case 'gig1.marchal' % verified
            R = qsys_gig1_approx_marchal(lambda,mu,ca,cs);
        case {'gm1', 'gim1'}
            % sigma = Load at arrival instants (Laplace transform of the inter-arrival times)
            LA = @(s) qn.lst{source_ist,1}(s);
            mu = qn.rates(queue_ist);
            sigma = fzero(@(x) LA(mu-mu*x)-x,0.5);
            R = qsys_gm1(sigma,mu);
        otherwise
            error('Line:UnsupportedMethod','Unsupported method for a model with 1 station and 1 class.');
    end
    RN(queue_ist,1) = R *qn.visits{1}(queue_ist);
    CN(queue_ist,1) = RN(1,1);
    XN(queue_ist,1) = lambda;
    UN(queue_ist,1) = lambda/mu/k;
    TN(source_ist,1) = lambda;
    TN(queue_ist,1) = lambda;
    QN(queue_ist,1) = XN(queue_ist,1) * RN(queue_ist,1);
    lG = 0;
    runtime=toc(T0);
else % queueing network
    T0=tic;
    switch method
        case 'aba.upper'
            if qn.nclasses==1 && qn.nclosedjobs >0 % closed single-class queueing network
                if any(qn.nservers(qn.schedid ~= SchedStrategy.ID_INF)>1)
                    error('Line:UnsupportedMethod','Unsupported method for a model with multi-server stations.');
                end
                V = qn.visits{1}(:);
                Z = sum(V(qn.schedid == SchedStrategy.ID_INF) ./ qn.rates(qn.schedid == SchedStrategy.ID_INF));
                D = V(qn.schedid ~= SchedStrategy.ID_INF) ./ qn.rates(qn.schedid ~= SchedStrategy.ID_INF);
                Dmax = max(D);
                N = qn.nclosedjobs;
                CN(1,1) = Z + N * sum(D);
                XN(1,1) = min( 1/Dmax, N / (Z + sum(D)));
                TN(:,1) = V .* XN(1,1);
                RN(:,1) = 1 ./ qn.rates * N;
                RN(qn.schedid == SchedStrategy.ID_INF,1) = 1 ./ qn.rates(qn.schedid == SchedStrategy.ID_INF,1);
                QN(:,1) = TN(:,1) .* RN(:,1);
                UN(:,1) = TN(:,1) ./ qn.rates;
                UN((qn.schedid == SchedStrategy.ID_INF),1) = QN((qn.schedid == SchedStrategy.ID_INF),1);
                lG = - N*log(XN(1,1)); % approx
            end
            runtime=toc(T0);
        case 'aba.lower'
            if qn.nclasses==1 && qn.nclosedjobs >0 % closed single-class queueing network
                if any(qn.nservers(qn.schedid ~= SchedStrategy.ID_INF)>1)
                    error('Line:UnsupportedMethod','Unsupported method for a model with multi-server stations.');
                end
                V = qn.visits{1}(:);
                Z = sum(V(qn.schedid == SchedStrategy.ID_INF) ./ qn.rates(qn.schedid == SchedStrategy.ID_INF));
                D = V(qn.schedid ~= SchedStrategy.ID_INF) ./ qn.rates(qn.schedid ~= SchedStrategy.ID_INF);
                N = qn.nclosedjobs;
                XN(1,1) = N / (Z + N*sum(D));
                CN(1,1) = Z + sum(D);
                TN(:,1) = V .* XN(1,1);
                RN(:,1) = 1 ./ qn.rates;
                QN(:,1) = TN(:,1) .* RN(:,1);
                UN(:,1) = TN(:,1) ./ qn.rates;
                UN((qn.schedid == SchedStrategy.ID_INF),1) = QN((qn.schedid == SchedStrategy.ID_INF),1);
                lG = - N*log(XN(1,1)); % approx
            end
            runtime=toc(T0);
        case 'bjb.upper'
            if qn.nclasses==1 && qn.nclosedjobs >0 % closed single-class queueing network
                if any(qn.nservers(qn.schedid ~= SchedStrategy.ID_INF)>1)
                    error('Line:UnsupportedMethod','Unsupported method for a model with multi-server stations.');
                end
                V = qn.visits{1}(:);
                Z = sum(V(qn.schedid == SchedStrategy.ID_INF) ./ qn.rates(qn.schedid == SchedStrategy.ID_INF));
                D = V(qn.schedid ~= SchedStrategy.ID_INF) ./ qn.rates(qn.schedid ~= SchedStrategy.ID_INF);
                Dmax = max(D);
                N = qn.nclosedjobs;
                Xaba_upper_1 =  min( 1/Dmax, (N-1) / (Z + sum(D)));
                Xaba_lower_1 =  (N-1) / (Z + (N-1)*sum(D));
                CN(1,1) = (Z+sum(D)+max(D)*(N-1-Z*Xaba_lower_1));
                XN(1,1) = min(1/Dmax, N / (Z+sum(D)+mean(D)*(N-1-Z*Xaba_upper_1)));
                TN(:,1) = V .* XN(1,1);
                % RN undefined in the literature so we use ABA upper
                RN(:,1) = 1 ./ qn.rates * N;                                
                %RN = 0*TN;
                %RN(qn.schedid ~= SchedStrategy.ID_INF,1) = NaN *  D+ max(D) ./ V(qn.schedid ~= SchedStrategy.ID_INF) .* (N-1-Z*Xaba_lower_1) / (qn.nstations - sum(qn.schedid == SchedStrategy.ID_INF));
                RN(qn.schedid == SchedStrategy.ID_INF,1) = 1 ./ qn.rates(qn.schedid == SchedStrategy.ID_INF,1);
                QN(:,1) = TN(:,1) .* RN(:,1);
                UN(:,1) = TN(:,1) ./ qn.rates;
                UN((qn.schedid == SchedStrategy.ID_INF),1) = QN((qn.schedid == SchedStrategy.ID_INF),1);
                lG = - N*log(XN(1,1)); % approx
            end
            runtime=toc(T0);    
        case 'bjb.lower'
            if qn.nclasses==1 && qn.nclosedjobs >0 % closed single-class queueing network
                if any(qn.nservers(qn.schedid ~= SchedStrategy.ID_INF)>1)
                    error('Line:UnsupportedMethod','Unsupported method for a model with multi-server stations.');
                end
                V = qn.visits{1}(:);
                Z = sum(V(qn.schedid == SchedStrategy.ID_INF) ./ qn.rates(qn.schedid == SchedStrategy.ID_INF));
                D = V(qn.schedid ~= SchedStrategy.ID_INF) ./ qn.rates(qn.schedid ~= SchedStrategy.ID_INF);
                Dmax = max(D);
                N = qn.nclosedjobs;
                Xaba_upper_1 =  min( 1/Dmax, (N-1) / (Z + sum(D)));
                Xaba_lower_1 =  (N-1) / (Z + (N-1)*sum(D));
                CN(1,1) = (Z+sum(D)+mean(D)*(N-1-Z*Xaba_upper_1));
                XN(1,1) = N / (Z+sum(D)+max(D)*(N-1-Z*Xaba_lower_1));
                TN(:,1) = V .* XN(1,1);
                % RN undefined in the literature so we use ABA lower
                RN(:,1) = 1 ./ qn.rates;                
                %RN = 0*TN;
                %RN(qn.schedid ~= SchedStrategy.ID_INF,1) = NaN * 1 ./ qn.rates(qn.schedid ~= SchedStrategy.ID_INF,1) + mean(D) ./ V(qn.schedid ~= SchedStrategy.ID_INF) .* (N-1-Z*Xaba_upper_1) / (qn.nstations - sum(qn.schedid == SchedStrategy.ID_INF));
                RN(qn.schedid == SchedStrategy.ID_INF,1) = 1 ./ qn.rates(qn.schedid == SchedStrategy.ID_INF,1);
                QN(:,1) = TN(:,1) .* RN(:,1);
                UN(:,1) = TN(:,1) ./ qn.rates;
                UN((qn.schedid == SchedStrategy.ID_INF),1) = QN((qn.schedid == SchedStrategy.ID_INF),1);
                lG = - N*log(XN(1,1)); % approx
            end
            runtime=toc(T0);              
        case 'pb.upper'
            if qn.nclasses==1 && qn.nclosedjobs >0 % closed single-class queueing network
                if any(qn.nservers(qn.schedid ~= SchedStrategy.ID_INF)>1)
                    error('Line:UnsupportedMethod','Unsupported method for a model with multi-server stations.');
                end
                V = qn.visits{1}(:);
                Z = sum(V(qn.schedid == SchedStrategy.ID_INF) ./ qn.rates(qn.schedid == SchedStrategy.ID_INF));
                D = V(qn.schedid ~= SchedStrategy.ID_INF) ./ qn.rates(qn.schedid ~= SchedStrategy.ID_INF);
                Dmax = max(D);
                N = qn.nclosedjobs;
                Xaba_upper_1 =  min( 1/Dmax, (N-1) / (Z + sum(D)));
                Xaba_lower_1 =  (N-1) / (Z + (N-1)*sum(D));
                Dpb2 = sum(D.^2)/sum(D); 
                DpbN = sum(D.^N)/sum(D.^(N-1)); 
                CN(1,1) = (Z+sum(D)+DpbN*(N-1-Z*Xaba_lower_1));
                XN(1,1) = min(1/Dmax, N / (Z+sum(D)+Dpb2*(N-1-Z*Xaba_upper_1)));                
                TN(:,1) = V .* XN(1,1);
                % RN undefined in the literature so we use ABA upper
                RN(:,1) = 1 ./ qn.rates * N;
                %RN = 0*TN;
                %RN(qn.schedid ~= SchedStrategy.ID_INF,1) = NaN * 1 ./ qn.rates(qn.schedid ~= SchedStrategy.ID_INF,1) + (D.^N/sum(D.^(N-1))) ./ V(qn.schedid ~= SchedStrategy.ID_INF)  * (N-1-Z*Xaba_upper_1);
                RN(qn.schedid == SchedStrategy.ID_INF,1) = 1 ./ qn.rates(qn.schedid == SchedStrategy.ID_INF,1);
                QN(:,1) = TN(:,1) .* RN(:,1);
                UN(:,1) = TN(:,1) ./ qn.rates;
                UN((qn.schedid == SchedStrategy.ID_INF),1) = QN((qn.schedid == SchedStrategy.ID_INF),1);
                lG = - N*log(XN(1,1)); % approx
            end
            runtime=toc(T0);    
        case 'pb.lower'
            if qn.nclasses==1 && qn.nclosedjobs >0 % closed single-class queueing network
                if any(qn.nservers(qn.schedid ~= SchedStrategy.ID_INF)>1)
                    error('Line:UnsupportedMethod','Unsupported method for a model with multi-server stations.');
                end
                V = qn.visits{1}(:);
                Z = sum(V(qn.schedid == SchedStrategy.ID_INF) ./ qn.rates(qn.schedid == SchedStrategy.ID_INF));
                D = V(qn.schedid ~= SchedStrategy.ID_INF) ./ qn.rates(qn.schedid ~= SchedStrategy.ID_INF);
                Dmax = max(D);
                N = qn.nclosedjobs;
                Xaba_upper_1 =  min( 1/Dmax, (N-1) / (Z + sum(D)));
                Xaba_lower_1 =  (N-1) / (Z + (N-1)*sum(D));
                Dpb2 = sum(D.^2)/sum(D); 
                DpbN = sum(D.^N)/sum(D.^(N-1)); 
                CN(1,1) = (Z+sum(D)+Dpb2*(N-1-Z*Xaba_upper_1));
                XN(1,1) = N / (Z+sum(D)+DpbN*(N-1-Z*Xaba_lower_1));
                TN(:,1) = V .* XN(1,1);
                % RN undefined in the literature so we use ABA lower
                RN(:,1) = 1 ./ qn.rates;
                %RN = 0*TN;
                %RN(qn.schedid ~= SchedStrategy.ID_INF,1) = NaN *  1 ./ qn.rates(qn.schedid ~= SchedStrategy.ID_INF,1) + (D.^2/sum(D)) ./ V(qn.schedid ~= SchedStrategy.ID_INF)  * (N-1-Z*Xaba_upper_1);
                RN(qn.schedid == SchedStrategy.ID_INF,1) = 1 ./ qn.rates(qn.schedid == SchedStrategy.ID_INF,1);
                QN(:,1) = TN(:,1) .* RN(:,1);
                UN(:,1) = TN(:,1) ./ qn.rates;
                UN((qn.schedid == SchedStrategy.ID_INF),1) = QN((qn.schedid == SchedStrategy.ID_INF),1);
                lG = - N*log(XN(1,1)); % approx
            end
            runtime=toc(T0);                   
        case 'gb.upper'
            if qn.nclasses==1 && qn.nclosedjobs >0 % closed single-class queueing network
                if any(qn.nservers(qn.schedid ~= SchedStrategy.ID_INF)>1)
                    error('Line:UnsupportedMethod','Unsupported method for a model with multi-server stations.');
                end
                V = qn.visits{1}(:);
                Z = sum(V(qn.schedid == SchedStrategy.ID_INF) ./ qn.rates(qn.schedid == SchedStrategy.ID_INF));
                D = V(qn.schedid ~= SchedStrategy.ID_INF) ./ qn.rates(qn.schedid ~= SchedStrategy.ID_INF);
                N = qn.nclosedjobs;
                Dmax = max(D);
                XN(1,1) = min(1/Dmax, pfqn_xzgsbup(D,N,Z));
                CN(1,1) = N / pfqn_xzgsblow(D,N,Z);
                TN(:,1) = V .* XN(1,1);
                XNlow = pfqn_xzgsblow(D,N,Z);
                k = 0;
                for i=1:size(qn.schedid,1)
                    if qn.schedid(i) == SchedStrategy.ID_INF
                        RN(i,1) = 1 / qn.rates(i);
                        QN(i,1) = XN(1,1) * RN(i,1);
                    else
                        k = k + 1;
                        QN(i,1) = pfqn_qzgbup(D,N,Z,k);
                        RN(i,1) = QN(i,1) / XNlow / V(i) ;
                    end
                end
                RN(qn.schedid == SchedStrategy.ID_INF,1) = 1 ./ qn.rates(qn.schedid == SchedStrategy.ID_INF,1);
                UN(:,1) = TN(:,1) ./ qn.rates;
                UN((qn.schedid == SchedStrategy.ID_INF),1) = QN((qn.schedid == SchedStrategy.ID_INF),1);
                lG = - N*log(XN(1,1)); % approx
            end
            runtime=toc(T0);
        case 'gb.lower'
            if qn.nclasses==1 && qn.nclosedjobs >0 % closed single-class queueing network
                if any(qn.nservers(qn.schedid ~= SchedStrategy.ID_INF)>1)
                    error('Line:UnsupportedMethod','Unsupported method for a model with multi-server stations.');
                end
                V = qn.visits{1}(:);
                Z = sum(V(qn.schedid == SchedStrategy.ID_INF) ./ qn.rates(qn.schedid == SchedStrategy.ID_INF));
                D = V(qn.schedid ~= SchedStrategy.ID_INF) ./ qn.rates(qn.schedid ~= SchedStrategy.ID_INF);
                N = qn.nclosedjobs;
                XN(1,1) = pfqn_xzgsblow(D,N,Z);
                CN(1,1) = N / pfqn_xzgsbup(D,N,Z);
                TN(:,1) = V .* XN(1,1);
                XNup = pfqn_xzgsbup(D,N,Z);
                k = 0;
                for i=1:size(qn.schedid,1)
                    if qn.schedid(i) == SchedStrategy.ID_INF
                        RN(i,1) = 1 / qn.rates(i);
                        QN(i,1) = XN(1,1) * RN(i,1);
                    else
                        k = k + 1;
                        QN(i,1) = pfqn_qzgblow(D,N,Z,k);
                        RN(i,1) = QN(i,1) / XNup / V(i) ;
                    end
                end
                UN(:,1) = TN(:,1) ./ qn.rates;
                UN((qn.schedid == SchedStrategy.ID_INF),1) = QN((qn.schedid == SchedStrategy.ID_INF),1);
                lG = - N*log(XN(1,1)); % approx
            end
            runtime=toc(T0);
        otherwise
            [QN,UN,RN,TN,CN,XN,lG,runtime] = solver_mva_analysis(qn, options);
    end
end
self.setAvgResults(QN,UN,RN,TN,CN,XN,runtime,method);
self.result.Prob.logNormConstAggr = lG;
end
