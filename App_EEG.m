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
    % Approximate Entropy (AppEn)
    % ========================
    function doAppEn()
        
        [signal, fs, label] = getSelectedSignal();
    
        if isempty(signal)
            return
        end

        m = 2;
        r = 0.2 * std(signal);
    
        value = apen_calc(signal,m,r);

        uialert(f,...
            sprintf('Approximate Entropy = %.5f',value),...
            ['AppEn - ',label]);
    
    end

    % ========================
    % TOPOGRAPHIC MAPS
    % ========================
    function doTopoMaps()

        EEG = buildEEGstruct();
        if isempty(EEG)
            return
        end
    
        fs = EEG.srate;
    
        tStart = edtStart.Value;
        tEnd   = edtEnd.Value;
    
        iStart = max(1, round(tStart*fs));
        iEnd   = min(EEG.pnts, round(tEnd*fs));
    
        data_segment = EEG.data(:, iStart:iEnd);
    
        % -------------------------
        % remove channels without position
        % -------------------------
        valid_chan = false(length(EEG.chanlocs),1);
    
        for i = 1:length(EEG.chanlocs)
            if isfield(EEG.chanlocs(i),'X') && ...
               isfield(EEG.chanlocs(i),'Y') && ...
               isfield(EEG.chanlocs(i),'Z') && ...
               ~isempty(EEG.chanlocs(i).X) && ...
               ~isempty(EEG.chanlocs(i).Y) && ...
               ~isempty(EEG.chanlocs(i).Z)
                valid_chan(i) = true;
            end
        end
    
        data_segment = data_segment(valid_chan,:);
        chanlocs = EEG.chanlocs(valid_chan);
    
        % -------------------------
        % map parameters
        % -------------------------
        n_maps = 10;
        win_width = (tEnd - tStart) / n_maps;
        step = (tEnd - tStart - win_width) / (n_maps - 1);
        window_centers = tStart + win_width/2 + (0:n_maps-1)*step;
    
        % -------------------------
        % plot maps
        % -------------------------
        figure('Color','w','Name','Topographic maps');
        sgtitle("Topographic maps");
    
        for k = 1:n_maps
            t1 = window_centers(k) - win_width/2;
            t2 = window_centers(k) + win_width/2;
    
            i1 = max(1, round((t1 - tStart)*fs)+1);
            i2 = min(size(data_segment,2), round((t2 - tStart)*fs));
    
            mean_data = mean(data_segment(:, i1:i2), 2);
    
            subplot(ceil(n_maps/5),5,k);
            topoplot(mean_data(:), chanlocs,...
                'electrodes','on',...
                'style','both');
    
            title(sprintf('%.0f–%.0f ms', t1*1000, t2*1000));
    
        end
    
        cbar;
    
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
