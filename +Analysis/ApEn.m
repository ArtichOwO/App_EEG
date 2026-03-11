function ApEn(app)
    [signal, fs, offset, label] = app.getSelectedSignal();
    
    if isempty(signal)
        return
    end

    % -------------------------
    % Paramètres de la fenêtre glissante
    % -------------------------
    % Note : Pour un signal long (351s), augmenter step_size_sec si besoin
    win_size_sec = 2;   
    step_size_sec = 1;  
    
    win_size = round(win_size_sec * fs);
    step_size = round(step_size_sec * fs);
    
    N = length(signal);
    
    if N < win_size
        uialert(app.UIFigure, ...
            "Selected signal is too short", "ApEn Error");
        return;
    end
    
    n_windows = floor((N - win_size) / step_size) + 1;
    appEn_vals = zeros(1, n_windows);
    t_centers = zeros(1, n_windows);
    offset = offset/fs;
    
    % Paramètres de l'algorithme
    m = 2;
    r = 0.2 * std(signal);

    % -------------------------
    % Calcul avec barre de progression
    % -------------------------
    d = uiprogressdlg(app.UIFigure, ...
        Title="ApEn computation (Fast mode)", ...
        Message="Window analysis...", ...
        Cancelable="on");
    
    for k = 1:n_windows
        if d.CancelRequested
            break;
        end
        
        idx_start = (k-1)*step_size + 1;
        idx_end = idx_start + win_size - 1;
        segment = signal(idx_start:idx_end);
        
        % Appel de la nouvelle fonction optimisée
        appEn_vals(k) = ApEn_fast_internal(segment, m, r);
        
        t_centers(k) = offset + (idx_start + win_size/2) / fs;
        d.Value = k / n_windows;
    end
    
    close(d); 
    
    if k < n_windows
        appEn_vals = appEn_vals(1:k-1);
        t_centers = t_centers(1:k-1);
        if isempty(appEn_vals), return; end
    end

    % -------------------------
    % Affichage
    % -------------------------
    plot(app.Axes, t_centers, appEn_vals, '-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
    title(app.Axes, sprintf('Approximate Entropy (Fast) - %s (r=%.2f)', label, r));
    xlabel(app.Axes, 'Temps (s)');
    ylabel(app.Axes, 'AppEn');
    xlim(app.Axes, "auto");
    ylim(app.Axes, "auto");
    grid(app.Axes, "on");
end

function out = ApEn_fast_internal(u, m, r)
    N_seg = length(u);
    
    % --- Calcul pour m ---
    n = N_seg - m + 1;
    X = zeros(n, m);
    for k_m = 1:m
        X(:,k_m) = u(k_m : N_seg - m + k_m);
    end
    
    C = zeros(n,1);
    for i = 1:n
        % Calcul de distance Chebyshev vectorisé
        D = max(abs(X - X(i,:)), [], 2);
        C(i) = sum(D <= r) / n;
    end
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
