function out = ApEn_fast_internal(u, m, r)
    N_seg = length(u);
    
    % --- Calcul pour m ---
    n = N_seg - m + 1;
    X = zeros(n, m);
    for k_m = 1:m
        X(:,k_m) = u(k_m : N_seg - m + k_m);
    end
    
    D = pdist2(X, X, 'chebychev');
    C = sum(D <= r, 2) / n;
    phi_m = mean(log(C));
    
    % --- Calcul pour m+1 ---
    m2 = m + 1;
    n2 = N_seg - m2 + 1;
    X2 = zeros(n2, m2);
    for k_m = 1:m2
        X2(:,k_m) = u(k_m : N_seg - m2 + k_m);
    end
    
    C2 = zeros(n2,1);
    for i = 1:n2
        D2 = max(abs(X2 - X2(i,:)), [], 2);
        C2(i) = sum(D2 <= r) / n2;
    end
    phi_m1 = mean(log(C2));
    
    out = phi_m - phi_m1;
end
