function eeg_GUI_f
    
    [ALLEEG, EEG0, CURRENTSET, ALLCOM] = eeglab;
    close;

    % ========================
    % Regions definition
    % ========================
    regions.Frontal = struct( ...
        'Fp1','EEGFp1LE','Fp2','EEGFp2LE','F3','EEGF3LE', ...
        'F4','EEGF4LE','F7','EEGF7LE','F8','EEGF8LE','Fz','EEGFzLE');

    regions.Temporal = struct( ...
        'T3','EEGT3LE','T4','EEGT4LE','T5','EEGT5LE','T6','EEGT6LE');

    regions.Parietal = struct( ...
        'P3','EEGP3LE','P4','EEGP4LE','Pz','EEGPzLE');

    regions.Occipital = struct( ...
        'O1','EEGO1LE','O2','EEGO2LE');

    regions.Central = struct( ...
        'C3','EEGC3LE','C4','EEGC4LE','Cz','EEGCzLE');

    regionNames = fieldnames(regions);

    % ========================
    % Application state
    % ========================
    app.hdr = [];
    app.record = [];
    app.fileinfo = [];
    app.filepath = [];
    app.regions = regions;

    % ========================
    % Create GUI
    % ========================
    f = uifigure('Name','EEG Viewer','Position',[100 100 900 500]);

    btnLoad = uibutton(f,...
        'Text','Choose EDF file',...
        'Position',[700 450 150 25]);

    uilabel(f,'Position',[50 450 120 22],'Text','Select region:');
    ddRegion = uidropdown(f,...
        'Items',regionNames,...
        'Position',[180 450 150 22],...
        'Enable','off');

    uilabel(f,'Position',[400 450 120 22],'Text','Select channel:');
    ddChannel = uidropdown(f,...
        'Position',[520 450 150 22],...
        'Enable','off');

    uilabel(f,'Position',[50 20 60 22],'Text','Start (s)');
    edtStart = uieditfield(f,'numeric','Position',[110 20 70 22],'Value',0);

    uilabel(f,'Position',[200 20 60 22],'Text','End (s)');
    edtEnd = uieditfield(f,'numeric','Position',[260 20 70 22],'Value',10);

    ax = uiaxes(f,'Position',[50 50 800 380]);
    title(ax,'No file loaded')
    grid(ax,'on')

    % ========================
    % Analysis Panel + Buttons
    % ========================
    analysisPanel = uipanel(f,...
    'Title','Analysis',...
    'Position',[50 395 630 45]);
    
    btnPSD = uibutton(analysisPanel,'Text','Spectral Analysis',...
        'Position',[10 5 110 17],'Enable','off');
    
    btnSTFT = uibutton(analysisPanel,'Text','STFT',...
        'Position',[130 5 90 17],'Enable','off');
    
    btnWavelet = uibutton(analysisPanel,'Text','Wavelet',...
        'Position',[230 5 90 17],'Enable','off');
    
    btnAppEn = uibutton(analysisPanel,'Text','AppEn',...
        'Position',[330 5 90 17],'Enable','off');
    
    btnTopo = uibutton(analysisPanel,'Text','Topographic',...
        'Position',[430 5 110 17],'Enable','off');
    

    % ========================
    % Button callbacks
    % ========================
    btnLoad.ButtonPushedFcn = @(src,event) loadEDF();
    btnPSD.ButtonPushedFcn = @(src,event) doPSD();
    btnSTFT.ButtonPushedFcn = @(src,event) doSTFT();
    btnWavelet.ButtonPushedFcn = @(src,event) doWavelet();
    btnAppEn.ButtonPushedFcn = @(src,event) doAppEn();
    btnTopo.ButtonPushedFcn = @(src,event) doTopoMaps();

    % ========================
    % Dropdown callbacks
    % ========================
    ddRegion.ValueChangedFcn = @(src,event) regionChanged();
    ddChannel.ValueChangedFcn = @(src,event) channelChanged();

    % ========================
    % LOAD EDF FILE
    % ========================
    function loadEDF()

        [filename,pathname] = uigetfile('*.edf','Select an EEG file');
        if isequal(filename,0)
            return
        end

        filepath = fullfile(pathname,filename);

        title(ax,'Loading EDF...')
        drawnow

        [hdr,record] = edfread(filepath);
        fileinfo = edfinfo(filepath);

        app.hdr = hdr;
        app.record = record;
        app.fileinfo = fileinfo;
        app.filepath = filepath;

        ddRegion.Enable = 'on';
        ddChannel.Enable = 'on';
        btnPSD.Enable = 'on';
        btnSTFT.Enable = 'on';
        btnWavelet.Enable = 'on';
        btnAppEn.Enable = 'on';
        btnTopo.Enable = 'on';

        updateChannelDropdown(ddRegion.Value);
        plotSelectedChannel(ddChannel.Value);

        % Update signal duration value :
        duration_total = app.fileinfo.NumDataRecords * seconds(app.fileinfo.DataRecordDuration);
        edtEnd.Value = duration_total;

    end

    % ========================
    % GET SELECTED SIGNAL
    % ========================
    function [signal, fs, label] = getSelectedSignal()
    
        signal = [];
        fs = [];
        label = '';
    
        % ------------------
        % validate EDF file
        % ------------------
        if isempty(app.record)
            uialert(f,'Load an EDF file first','Signal Error')
            return
        end
    
        % ------------------
        % validate channel
        % ------------------
        region = app.regions.(ddRegion.Value);
        label = ddChannel.Value;
    
        if strcmp(label,'Total')
            uialert(f,'Select a single channel first','Signal Error')
            return
        end
    
        realName = region.(label);
        idx = find(strcmp(app.hdr.label,realName));
    
        if isempty(idx)
            uialert(f,'Channel not found in EDF','Signal Error')
            return
        end
    
        % ------------------
        % convert signal to physical units
        % ------------------
        signal = convertToPhysical(idx);
    
        signal = signal(~isnan(signal));
        signal = signal(~isinf(signal));
    
        % ------------------
        % sampling rate
        % ------------------
        fs = app.fileinfo.NumSamples(1) / seconds(app.fileinfo.DataRecordDuration);
    
        % ------------------
        % time interval selection
        % ------------------
        tStart = edtStart.Value;
        tEnd   = edtEnd.Value;
    
        iStart = max(1, round(tStart * fs));
        iEnd   = min(length(signal), round(tEnd * fs));
    
        if iEnd <= iStart
            uialert(f,'Invalid time interval','Signal Error')
            signal = [];
            return
        end
    
        signal = signal(iStart:iEnd);
    
    end

 % ========================
    % Approximate Entropy (AppEn) over time - VERSION RAPIDE
    % ========================
    function doAppEn()
        
        [signal, fs, label] = getSelectedSignal();
    
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
            uialert(f, 'Le signal sélectionné est trop court.', 'Erreur AppEn');
            return;
        end
        
        n_windows = floor((N - win_size) / step_size) + 1;
        appEn_vals = zeros(1, n_windows);
        t_centers = zeros(1, n_windows);
        
        % Paramètres de l'algorithme
        m = 2;
        r = 0.2 * std(signal); 
        tStart = edtStart.Value; 

        % -------------------------
        % Calcul avec barre de progression
        % -------------------------
        d = uiprogressdlg(f, 'Title', 'Calcul de l''AppEn (Mode Rapide)', ...
                             'Message', 'Analyse des fenêtres en cours...', ...
                             'Cancelable', 'on');
        
        for k = 1:n_windows
            if d.CancelRequested
                break;
            end
            
            idx_start = (k-1)*step_size + 1;
            idx_end = idx_start + win_size - 1;
            segment = signal(idx_start:idx_end);
            
            % Appel de la nouvelle fonction optimisée
            appEn_vals(k) = ApEn_fast_internal(segment, m, r);
            
            t_centers(k) = tStart + (idx_start + win_size/2) / fs;
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
        figure('Name', ['AppEn Fast - ', label], 'Color', 'w');
        plot(t_centers, appEn_vals, '-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
        title(sprintf('Entropie Approximative (Fast) - Voie %s (r=%.2f)', label, r));
        xlabel('Temps (s)');
        ylabel('AppEn');
        grid on;
    end

    % ========================
    % ALGORITHME VECTORISÉ (ApEn_fast)
    % ========================
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
% ========================
    % INTEGRATED TOPOGRAPHIC MAP (Full Signal Length)
    % ========================
    function doTopoMaps()
        if isempty(app.record)
            uialert(f,'Load an EDF file first','Topo Error');
            return
        end

        % 1. Get the signal segment indices using the existing app function
        % FIX: Force indices to be integers using round() to prevent indexing error
        indices = round(getSelectedSignal()); 
        idxStart = indices(1);
        idxEnd = indices(2);
        
        % Ensure indices are within valid range
        idxStart = max(1, idxStart);
        idxEnd = min(size(app.record, 2), idxEnd);

        % 2. Define Electrode Positions (10-20 system)
        x = [6.5 5.5 5 5.5 6.5 2.1 0.5 2.1 9 11.5 12.5 13 12.5 11.5 15.9 17.5 15.9 9 9]';
        y = [0.5 4.5 8.5 12.5 16.5 3.5 8.5 13.5 4.5 0.5 4.5 8.5 12.5 16.5 3.5 8.5 13.5 8.5 12.5]';
        numChannels = length(x);

        % 3. Extract and Average Data across the entire segment
        ZdataRaw = zeros(numChannels, 1);
        for i = 1:numChannels
            % Get the physical signal for this channel
            fullSignal = convertToPhysical(i);
            
            % Extract the segment using integer indices
            segment = fullSignal(idxStart:idxEnd);
            
            % Use RMS to represent average activity over the duration
            ZdataRaw(i) = rms(segment); 
        end

        % Normalize for color mapping
        z = rescale(ZdataRaw, 0, 1);
        mapTitle = sprintf('Topographic Map (RMS) from %.2f to %.2f s', ...
            edtStart.Value, edtEnd.Value);

        % 4. Interpolation - Create a smooth grid
        [xq, yq] = meshgrid(0:0.1:18, 0:0.1:18);
        F = scatteredInterpolant(x, y, z, 'linear', 'none');
        zq = F(xq, yq);

        % 5. Create Plotting Window
        fig = figure('Name', mapTitle, 'Color', 'w');
        ax = axes(fig);
        
        % Plot the surface
        surf(ax, xq, yq, zq, 'EdgeColor', 'none'); 
        hold(ax, 'on');
        
        view(ax, 2); 
        shading(ax, 'interp');
        colormap(ax, 'jet');
        colorbar(ax);
        axis(ax, 'equal', 'off');
        set(ax, 'ydir', 'reverse');
        title(ax, mapTitle);

        % 6. Draw Head Outline
        theta = -2*pi : 0.01 : 2*pi;
        cx = 9; cy = 8.5;
        plot3(ax, 8.5*cos(theta)+cx, 8.5*sin(theta)+cy, ones(size(theta))*2, ...
              'LineWidth', 12, 'Color', [0.9 0.9 0.9]); 
        plot3(ax, 8*cos(theta)+cx, 8*sin(theta)+cy, ones(size(theta))*2.1, ...
              'LineWidth', 2, 'Color', 'k');

        % 7. Add Nose
        plot3(ax, [8.5 9 9.5], [0.1 -0.5 0.1], [3 3 3], 'k', 'LineWidth', 2);

        % 8. Add Electrode Labels
        xLabels = [6.5 5.5 5 5.5 6.5 3 1.5 3 9 11.5 12.5 13 12.5 11.5 15 16.5 15 9 9];
        yLabels = [1.5 4.5 8.5 12.5 15.5 4 8.5 13 4.5 1.5 4.5 8.5 12.5 15.5 4 8.5 13 8.5 12.5];
        
        for i = 1:numChannels
            lbl = erase(app.hdr.label{i}, ["EEG", "-LE", "_LE", "LE"]);
            text(ax, xLabels(i), yLabels(i), 5, lbl, ...
                'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Color', 'k', 'FontSize', 8);
        end
    end
    % ========================
    % STFT (Short-time Fourier Transform)
    % ========================
    function doSTFT()

        [signal, fs, label] = getSelectedSignal();
    
        if isempty(signal)
            return
        end
    
        figure('Name',['STFT - ',label],'Color','w');
    
        win = hamming(256);
        overlap = 200;
        nfft = 512;
    
        stft(signal, fs, ...
            'Window', win, ...
            'OverlapLength', overlap, ...
            'FFTLength', nfft);
    
    end

    % ========================
    % WAVELET DECOMPOSITION
    % ========================
    function doWavelet()
    
        [signal, fs, label] = getSelectedSignal();
    
        if isempty(signal)
            return
        end
    
        w = "db2";
        N = 7;
    
        [C,L] = wavedec(signal, N, w);
    
        D2 = wrcoef('d', C, L, w, 2);
        D3 = wrcoef('d', C, L, w, 3);
        D4 = wrcoef('d', C, L, w, 4);
        D5 = wrcoef('d', C, L, w, 5);
        D6 = wrcoef('d', C, L, w, 6);
        D7 = wrcoef('d', C, L, w, 7);
        A7 = wrcoef('a', C, L, w, 7);
    
        gamma = D2 + D3;
        beta  = D4;
        alpha = D5;
        theta = D6;
        delta = D7 + A7;
    
        bands = {gamma, beta, alpha, theta, delta};
        names = {"Gamma","Beta","Alpha","Theta","Delta"};
    
        t = (0:length(signal)-1)/fs;
    
        figure('Name',['Wavelet Bands - ',label],'Color','w');
    
        for k=1:5
            subplot(5,1,k)
            plot(t,bands{k})
            title(names{k})
            grid on
        end
    
    end

    % ========================
    % UPDATE CHANNEL DROPDOWN BASED ON REGION
    % ========================
    function updateChannelDropdown(regionName)

        region = app.regions.(regionName);
        channelLabels = fieldnames(region);
        realNames = struct2cell(region);

        valid = ismember(realNames, app.hdr.label);
        channelLabels = channelLabels(valid);

        ddChannel.Items = [{'Total'}, channelLabels'];
        ddChannel.Value = ddChannel.Items{1};

    end

    % ========================
    % REGION DROPDOWN CHANGED
    % ========================
    function regionChanged()

        if isempty(app.record)
            return
        end

        updateChannelDropdown(ddRegion.Value);
        plotSelectedChannel(ddChannel.Value);

    end

    % ========================
    % CHANNEL DROPDOWN CHANGED
    % ========================
    function channelChanged()

        if isempty(app.record)
            return
        end

        plotSelectedChannel(ddChannel.Value);

    end

    % ========================
    % PLOT SELECTED CHANNEL
    % ========================
    function plotSelectedChannel(channelLabel)

        cla(ax)

        region = app.regions.(ddRegion.Value);

        if strcmp(channelLabel,'Total')
            plotRegion(region);
            return
        end

        realName = region.(channelLabel);
        idx = find(strcmp(app.hdr.label,realName));
        if isempty(idx)
            return
        end

        signal = convertToPhysical(idx);

        n = numel(signal);
        duration_total = app.fileinfo.NumDataRecords * app.fileinfo.DataRecordDuration;
        t = linspace(0,duration_total,n);

        plot(ax,t,signal,'b')
        title(ax,['EEG Signal - ',channelLabel])
        xlabel(ax,'Time (s)')
        ylabel(ax,'Amplitude (µV)')
        grid(ax,'on')

    end

    % ========================
    % PLOT REGION (multiple channels)
    % ========================
    function plotRegion(regionStruct)

        hold(ax,'on')

        shortNames = fieldnames(regionStruct);
        realNames = struct2cell(regionStruct);

        offset = 20;

        duration_total = app.fileinfo.NumDataRecords * app.fileinfo.DataRecordDuration;

        for i = 1:length(realNames)

            idx = find(strcmp(app.hdr.label,realNames{i}));
            if isempty(idx)
                continue
            end

            signal = convertToPhysical(idx);

            n = numel(signal);
            t = linspace(0,duration_total,n);

            plot(ax,t,signal+(i-1)*offset,'DisplayName',shortNames{i})

        end

        hold(ax,'off')
        legend(ax,'show','Location','eastoutside')
        title(ax,['EEG Region - ',ddRegion.Value])
        xlabel(ax,'Time (s)')
        ylabel(ax,'Amplitude (µV, offset)')
        grid(ax,'on')

    end

    % ========================
    % DIGITAL → PHYSICAL CONVERSION
    % ========================
    function signal = convertToPhysical(idx)

        if isfield(app.hdr,'digitalMin')

            DigitalMin  = app.hdr.digitalMin(idx);
            DigitalMax  = app.hdr.digitalMax(idx);
            PhysicalMin = app.hdr.physicalMin(idx);
            PhysicalMax = app.hdr.physicalMax(idx);

            signal = (app.record(idx,:) - DigitalMin) .* ...
                (PhysicalMax - PhysicalMin) ./ ...
                (DigitalMax - DigitalMin) + PhysicalMin;
        else
            signal = app.record(idx,:);
        end

    end

    % ========================
    % Approximate Entropy calculation
    % ========================
    function out = apen_calc(u,m,r)
        N = length(u);

        function y = maxdist(i,j,mm)
            y = max(abs(u(i:i+mm-1) - u(j:j+mm-1)));
        end

        function y = phi(mm)
            n = N - mm + 1;
            y = sum(arrayfun(@(i) ...
                log(sum(arrayfun(@(j) maxdist(i,j,mm)<=r,1:n))/n), ...
                1:n))/n;
        end

        out = phi(m) - phi(m+1);

    end

    % ========================
    % BUILD EEGLAB STRUCTURE
    % ========================
    function EEG = buildEEGstruct()
    
        EEG = [];
    
        if isempty(app.record)
            uialert(f,'Load an EDF first','Topo Error');
            return
        end
    
        nChan = length(app.hdr.label);
        nPnts = size(app.record,2);
    
        % -------------------------
        % build data matrix channels x time
        % -------------------------
        data = zeros(nChan,nPnts);
    
        for i = 1:nChan
            data(i,:) = convertToPhysical(i);
        end
    
        % -------------------------
        % sampling rate
        % -------------------------
        fs = app.fileinfo.NumSamples(1) / ...
             seconds(app.fileinfo.DataRecordDuration);
    
        % -------------------------
        % base EEGLAB structure
        % -------------------------
        EEG = [];

        EEG.data   = data;
        EEG.nbchan = nChan;
        EEG.srate  = fs;
        EEG.pnts   = nPnts;
        EEG.trials = 1;
        EEG.xmin   = 0;
        EEG.xmax   = nPnts/fs;

        EEG.setname   = 'GUI_dataset';
        EEG.filename  = '';
        EEG.filepath  = '';
        EEG.subject   = '';
        EEG.group     = '';
        EEG.condition = '';
        EEG.session   = '';
        EEG.comments  = '';
        EEG.ref       = 'common';
        EEG.event     = [];
        EEG.epoch     = [];

        % -------------------------
        % clean channel labels
        % -------------------------
        for i = 1:nChan
            EEG.chanlocs(i).labels = erase(app.hdr.label{i},'-LE');
        end

        EEG = eeg_checkset(EEG);

        % -------------------------
        % load standard channel positions
        % -------------------------
        eeglab_path = fileparts(which('eeglab.m'));
        lookup_file = fullfile(eeglab_path,'plugins','dipfit',...
                               'standard_BEM','elec',...
                               'standard-10-5-cap385.elp');

        if exist(lookup_file,'file')
            EEG = pop_chanedit(EEG,'lookup',lookup_file);
            EEG = eeg_checkset(EEG);
        else
            warning('File standard-10-5-cap385.elp not found');
        end
    
    end

end
