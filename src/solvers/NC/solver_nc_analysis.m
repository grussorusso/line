function [Q,U,R,T,C,X,lG,runtime] = solver_nc_analysis(qn, options)
% [Q,U,R,T,C,X,LG,RUNTIME] = SOLVER_NC_ANALYSIS(QN, OPTIONS)

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

M = qn.nstations;    %number of stations
nservers = qn.nservers;
NK = qn.njobs';  % initial population per class
sched = qn.sched;
%chains = qn.chains;
C = qn.nchains;
SCV = qn.scv;
ST = 1 ./ qn.rates;
ST(isnan(ST))=0;
ST0=ST;

alpha = zeros(qn.nstations,qn.nclasses);
Vchain = zeros(qn.nstations,qn.nchains);
for c=1:qn.nchains
    inchain = find(qn.chains(c,:));
    for i=1:qn.nstations
        Vchain(i,c) = sum(qn.visits{c}(i,inchain)) / sum(qn.visits{c}(qn.refstat(inchain(1)),inchain));
        for k=inchain
            alpha(i,k) = alpha(i,k) + qn.visits{c}(i,k) / sum(qn.visits{c}(i,inchain));
        end
    end
end
Vchain(~isfinite(Vchain))=0;
alpha(~isfinite(alpha))=0;
alpha(alpha<1e-12)=0;
eta_1 = zeros(1,M);
eta = ones(1,M);
if findstring(sched,'fcfs') == -1, options.iter_max=1; end

it = 0;
while max(abs(1-eta./eta_1)) > options.iter_tol && it <= options.iter_max
    it = it + 1;
    eta_1 = eta;
    M = qn.nstations;    %number of stations
    K = qn.nclasses;    %number of classes
    C = qn.nchains;
    Lchain = zeros(M,C);
    STchain = zeros(M,C);
    
    SCVchain = zeros(M,C);
    Nchain = zeros(1,C);
    refstatchain = zeros(C,1);
    for c=1:C
        inchain = find(qn.chains(c,:));
        isOpenChain = any(isinf(qn.njobs(inchain)));
        for i=1:M
            % we assume that the visits in L(i,inchain) are equal to 1
            Lchain(i,c) = Vchain(i,c) * ST(i,inchain) * alpha(i,inchain)';
            STchain(i,c) = ST(i,inchain) * alpha(i,inchain)';
            if isOpenChain && i == qn.refstat(inchain(1)) % if this is a source ST = 1 / arrival rates
                STchain(i,c) = sumfinite(ST(i,inchain)); % ignore degenerate classes with zero arrival rates
            else
                STchain(i,c) = ST(i,inchain) * alpha(i,inchain)';
            end
            SCVchain(i,c) = SCV(i,inchain) * alpha(i,inchain)';
        end
        Nchain(c) = sum(NK(inchain));
        refstatchain(c) = qn.refstat(inchain(1));
        if any((qn.refstat(inchain(1))-refstatchain(c))~=0)
            error('Classes in chain %d have different reference station.',c);
        end
    end
    STchain(~isfinite(STchain))=0;
    Lchain(~isfinite(Lchain))=0;
    Tstart = tic;
    Nt = sum(Nchain(isfinite(Nchain)));
    
    Lcorr = zeros(M,C);
    Z = zeros(M,C);
    Zcorr = zeros(M,C);
    infServers = [];
    for i=1:M
        if isinf(nservers(i)) % infinite server
            %mu_chain(i,1:sum(Nchain)) = 1:sum(Nchain);
            infServers(end+1) = i;
            Lcorr(i,:) = 0;
            Z(i,:) = Lchain(i,:);
            Zcorr(i,:) = 0;
        else
            if strcmpi(options.method,'exact') && nservers(i)>1
                options.method = 'default';
                warning('%s does not support exact multiserver yet. Switching to approximate method.', mfilename);
            end
            Lcorr(i,:) = Lchain(i,:) / nservers(i);
            Z(i,:) = 0;
            Zcorr(i,:) = Lchain(i,:) * (nservers(i)-1)/nservers(i);
        end
    end
    Qchain = zeros(M,C);
    
    % step 1
    lG = pfqn_nc(Lcorr,Nchain,sum(Z,1)+sum(Zcorr,1), options);
    
    % commented out, poor performance on bench_CQN_FCFS_rm_multiserver_hicv_midload
    % model 7 as it does not guarantee that the closed population is
    % constant
    %     % step 2 - reduce the artificial think time
    %     if any(S(isfinite(S)) > 1)
    %         Xchain = zeros(1,C);
    %         for r=1:C % we need the utilizations in step 2 so we determine tput
    %             Xchain(r) = exp(pfqn_nc(Lcorr,oner(Nchain,r),sum(Z,1)+sum(Zcorr,1), options) - lG);
    %         end
    %         for i=1:M
    %             if isinf(S(i)) % infinite server
    %                 % do nothing
    %             else
    %                 Zcorr(i,:) = max([0,(1-(Xchain*Lchain(i,:)'/S(i))^S(i))]) * Lchain(i,:) * (S(i)-1)/S(i);
    %             end
    %         end
    %         lG = pfqn_nc(Lcorr,Nchain,sum(Z,1)+sum(Zcorr,1), options); % update lG
    %     end
    
    for r=1:C
        lGr(r) = pfqn_nc(Lcorr,oner(Nchain,r),sum(Z,1)+sum(Zcorr,1), options);
        Xchain(r) = exp(lGr(r) - lG);
        for i=1:M
            if Lchain(i,r)>0
                if isinf(nservers(i)) % infinite server
                    Qchain(i,r) = Lchain(i,r) * Xchain(r);
                else
                    lGar(i,r) = pfqn_nc([Lcorr(setdiff(1:size(Lcorr,1),i),:),zeros(size(Lcorr,1)-1,1); Lcorr(i,:),1], [oner(Nchain,r),1], [sum(Z,1)+sum(Zcorr,1),0], options);
                    Qchain(i,r) = Zcorr(i,r) * Xchain(r) + Lcorr(i,r) * exp(lGar(i,r) - lG);
                end
            end
        end
    end
    
    if isnan(Xchain)
        %        Z
        %        Zcorr
        %        Lcorr,Nchain,sum(Z,1)+sum(Zcorr,1)
        %        lG
        %        lGr
        %        lGar
        warning('Normalizing constant computations produced a floating-point range exception. Model is likely too large.');
    end
    
    Z = sum(Z(1:M,:),1);
    
    Rchain = Qchain ./ repmat(Xchain,M,1) ./ Vchain;
    Rchain(infServers,:) = Lchain(infServers,:) ./ Vchain(infServers,:);
    Tchain = repmat(Xchain,M,1) .* Vchain;
    Uchain = Tchain .* Lchain;
    Cchain = Nchain ./ Xchain - Z;
    
    Xchain(~isfinite(Xchain))=0;
    Uchain(~isfinite(Uchain))=0;
    Qchain(~isfinite(Qchain))=0;
    Rchain(~isfinite(Rchain))=0;
    
    Xchain(Nchain==0)=0;
    Uchain(:,Nchain==0)=0;
    Qchain(:,Nchain==0)=0;
    Rchain(:,Nchain==0)=0;
    Tchain(:,Nchain==0)=0;
    
    for c=1:qn.nchains
        inchain = find(qn.chains(c,:));
        for k=inchain(:)'
            X(k) = Xchain(c) * alpha(qn.refstat(k),k);
            for i=1:qn.nstations
                if isinf(nservers(i))
                    U(i,k) = ST(i,k) * (Xchain(c) * Vchain(i,c) / Vchain(qn.refstat(k),c)) * alpha(i,k);
                else
                    U(i,k) = ST(i,k) * (Xchain(c) * Vchain(i,c) / Vchain(qn.refstat(k),c)) * alpha(i,k) / nservers(i);
                end
                if Lchain(i,c) > 0
                    Q(i,k) = Rchain(i,c) * ST(i,k) / STchain(i,c) * Xchain(c) * Vchain(i,c) / Vchain(qn.refstat(k),c) * alpha(i,k);
                    T(i,k) = Tchain(i,c) * alpha(i,k);
                    R(i,k) = Q(i,k) / T(i,k);
                    % R(i,k) = Rchain(i,c) * ST(i,k) / STchain(i,c) * alpha(i,k) / sum(alpha(qn.refstat(k),inchain)');
                else
                    T(i,k) = 0;
                    R(i,k) = 0;
                    Q(i,k) = 0;
                end
            end
            C(k) = qn.njobs(k) / X(k);
        end
    end
    
    for i=1:M
        sd = ST0(i,:)>0;
        switch sched{i}
            case SchedStrategy.FCFS
                %if range(ST0(i,sd))>0 % check if non-product-form
                rho(i) = sum(U(i,:)); % true utilization of each server, critical to use this
                ca(i) = 0;
                for j=1:M
                    for r=1:K
                        if ST0(j,r)>0
                            for s=1:K
                                if ST0(i,s)>0
                                    pji_rs = qn.rt((i-1)*qn.nclasses + r, (j-1)*qn.nclasses + s);
                                    ca(i) = ca(i) + SCV(j,r)*T(j,r)*pji_rs/sum(T(i,sd));
                                end
                            end
                        end
                    end
                end
                
                %ca(i) = 1;
                cs(i) = (SCV(i,sd)*T(i,sd)')/sum(T(i,sd));
                % asymptotic decay rate (diffusion approximation, Kobayashi JACM)
                eta(i) = exp(-2*(1-rho(i))/(cs(i)+ca(i)*rho(i)));
                %end
                %eta(i) = rho(i);
                %eta(i) = (rho(i)^nservers(i)+rho(i))/2; % multi-server
                
        end
    end
    
    for i=1:M
        sd = ST0(i,:)>0;
        switch sched{i}
            case SchedStrategy.FCFS
                %if range(ST0(i,sd))>0 % check if non-product-form
                for k=1:K
                    if sum(Q(i,ST(i,:)>0)) < nservers(i)
                        if ST0(i,k)>0
                            ST(i,k) = ST0(i,k);
                        end
                    else % sum(Q(i,ST(i,:)>0)) >= S(i)
                        if ST0(i,k)>0
                            ST(i,k) = eta(i)*nservers(i)/sum(T(i,sd));
                        end
                    end
                end
                %end
        end
    end
end
runtime = toc(Tstart);
Q=abs(Q); R=abs(R); X=abs(X); U=abs(U);


X(~isfinite(X))=0; U(~isfinite(U))=0; Q(~isfinite(Q))=0; R(~isfinite(R))=0;
%if options.verbose > 0
%    fprintf(1,'NC analysis completed in %f sec\n',runtime);
%end
return
end
