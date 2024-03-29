function [lGn] = pfqn_nc(L,N,Z,varargin)
% [LGN] = PFQN_NC(L,N,Z,VARARGIN)

options = Solver.parseOptions(varargin,SolverNC.defaultOptions);

% remove empty classes
nnzClasses = find(N);
L = L(:,nnzClasses);
N = N(:,nnzClasses);
Z = Z(:,nnzClasses);
Lsum = sum(L,2);
Lmax = max(L,[],2);
L = L((Lmax./Lsum)>options.tol,:); % remove stations with no demand
LZsum = sum(L,1) + sum(Z,1);
if any(N(LZsum == 0)>0) % if there is a class with jobs but L and Z all zero
    error('The specified model is impossible: no station has positive demands in one of the non-empty classes.');
end
[M,K]=size(L);

% return immediately if degenerate case
if isempty(L) || sum(L(:))<options.tol % all demands are zero
    if isempty(Z) || sum(Z(:))<options.tol
        lGn = 0;
    else
        lGn = - sum(factln(N)) + sum(N.*log(sum(Z,1)));
    end
    return
elseif M==1 && (isempty(Z) || sum(Z(:))<options.tol) % single node and no think time
    lGn = factln(sum(N)) - sum(factln(N)) + sum(N.*log(sum(L,1)));
    return
end

% contribution from jobs that permanently loop at delay
zeroDemandClasses = find(sum(L,1)<options.tol); % all jobs in delay
nonzeroDemandClasses = setdiff(1:K, zeroDemandClasses);
if sum(Z(:),1)<options.tol || isempty(Z)
    lGz = 0;
else
    if isempty(zeroDemandClasses) % for old MATLAB release compatibility
        lGz = 0;
    else
        Nz = N(zeroDemandClasses);
        lGz = - sum(factln(Nz)) + sum(Nz.*log(sum(Z(:,zeroDemandClasses),1)));
    end
end
Lnnzd = L(:,nonzeroDemandClasses);
Nnnzd = N(nonzeroDemandClasses);
Znnzd = Z(:,nonzeroDemandClasses);


% first try rather efficient methods
if M==1 % single node
    if (K==1 && N<30) || strcmp(options.method,'exact')
        options.method = 'exact';
        logI = sub_method(Lnnzd, Nnnzd, Znnzd, options);
        lGn =  lGz + logI;
        return
    end
    
    Nstar = (sum(Lnnzd)+sum(Znnzd,1))/max(Lnnzd);
    if strcmpi(options.method,'default') && sum(Nnnzd) > 5 * sum(Nstar)
        options.method = 'le';
        logI = sub_method(Lnnzd, Nnnzd, Znnzd, options);
        if isfinite(logI)
            lGn =  lGz + logI;
            return;
        end
    end
    
    % cycle solution methods
    % 'pnc' excluded because if one of the Zs is zero produces bad results
    methods = {'pnc2','imci'};
    if options.samples < 1e5
        if options.verbose == 2
            warning('options.samples value is too low for SolverNC. Setting to 1e5.');
        end
        options.samples = 1e5;
    end
    for m=1:length(methods)
        options.method = methods{m};
        logI = sub_method(Lnnzd, Nnnzd, Znnzd, options);
        if isfinite(logI)
            lGn =  lGz + logI;
            return;
        end
    end
    return
else % not a repairmen problem
    Nstar = (sum(Lnnzd)+sum(Znnzd,1))/max(Lnnzd);
    if strcmpi(options.method,'default') && sum(Nnnzd) > 5 * sum(Nstar)
        options.method = 'le';
    end
    lGn = sub_method(Lnnzd, Nnnzd, Znnzd, options);
end
end

function lG = sub_method(L,N,Z,options)
% LG = SUB_METHOD(L,N,Z,OPTIONS)

switch options.method
    case {'mmint','pnc2'}
        if size(L,1)>1
            warning('The %s method requires a model with a delay and a queueing station. Switching to default.',options.method);
            [~,lG] = pfqn_mci(L,N,sum(Z,1),options.samples,'imci'); % repairmen
        else
            lG = pfqn_pnc2(L,N,sum(Z,1));
        end
    case {'pana','panacea','pnc'}
        [~,lG] = pfqn_panacea(L,N,sum(Z,1));
    case 'le'
        [~,lG] = pfqn_le(L,N,sum(Z,1));
    case 'ls'
        [~,lG] = pfqn_ls(L,N,sum(Z,1),options.samples);
    case {'default','mci','imci'}
        [~,lG] = pfqn_mci(L,N,sum(Z,1),options.samples,'imci'); % repairmen
    case {'mva'}
        [~,~,~,~,lG] = pfqn_mva(L,N,sum(Z,1));
    case {'exact','ca'}
        [~,lG] = pfqn_ca(L,N,sum(Z,1));
end
return
end
