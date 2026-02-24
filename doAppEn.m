% Remplace doAppEn() to display entropy in a function of time

    % ========================
    % Approximate Entropy (AppEn) over time
    % ========================
    function doAppEn()
        
        [signal, fs, label] = getSelectedSignal();
    
        if isempty(signal)
            return
        end

        % -------------------------
        % Paramètres de la fenêtre glissante
        % -------------------------
        win_size_sec = 2;   % Taille de la fenêtre (en secondes)
        step_size_sec = 1;  % Pas d'avancement de la fenêtre (en secondes)
        
        win_size = round(win_size_sec * fs);
        step_size = round(step_size_sec * fs);
        
        N = length(signal);
        
        if N < win_size
            uialert(f, 'Le signal sélectionné est trop court pour la fenêtre choisie.', 'Erreur AppEn');
            return;
        end
        
        % Calcul du nombre total de fenêtres
        n_windows = floor((N - win_size) / step_size) + 1;
        
        % Initialisation des vecteurs de résultats
        appEn_vals = zeros(1, n_windows);
        t_centers = zeros(1, n_windows);
        
        % Paramètres de l'AppEn
        m = 2;
        % On calcule 'r' sur le signal complet pour avoir un seuil cohérent sur tout le tracé
        r = 0.2 * std(signal); 
        
        % Récupération du temps de début depuis l'IHM
        tStart = edtStart.Value; 

        % -------------------------
        % Calcul avec barre de progression
        % -------------------------
        % Le calcul d'entropie étant long (O(N^2)), une barre d'attente est indispensable
        d = uiprogressdlg(f, 'Title', 'Calcul de l''AppEn en cours', ...
                             'Message', 'Veuillez patienter...', ...
                             'Cancelable', 'on');
        
        for k = 1:n_windows
            % Vérifier si l'utilisateur a cliqué sur "Annuler"
            if d.CancelRequested
                break;
            end
            
            % Extraction de la fenêtre courante
            idx_start = (k-1)*step_size + 1;
            idx_end = idx_start + win_size - 1;
            segment = signal(idx_start:idx_end);
            
            % Calcul de l'AppEn pour ce segment
            appEn_vals(k) = apen_calc(segment, m, r);
            
            % Calcul du temps au centre de la fenêtre (pour l'axe X du graphique)
            t_centers(k) = tStart + (idx_start + win_size/2) / fs;
            
            % Mise à jour de la barre de progression
            d.Value = k / n_windows;
        end
        
        % Fermeture de la fenêtre de progression
        close(d); 
        
        % Si l'utilisateur a annulé, on ne trace que ce qui a été calculé
        if k < n_windows
            appEn_vals = appEn_vals(1:k-1);
            t_centers = t_centers(1:k-1);
            if isempty(appEn_vals)
                return; % Annulation dès le début
            end
        end

        % -------------------------
        % Affichage du graphique
        % -------------------------
        figure('Name', ['AppEn vs Temps - ', label], 'Color', 'w');
        plot(t_centers, appEn_vals, '-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b', 'Color', [0 0.4470 0.7410]);
        title(sprintf('Entropie Approximative (AppEn) - Voie %s', label));
        xlabel('Temps (s)');
        ylabel('Valeur AppEn');
        grid on;
        
    end
