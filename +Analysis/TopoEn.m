function TopoEn(app)
    if isempty(app.getFile())
        uialert(app.UIFigure, ...
            "Load an EDF file first", "TopoFreq Error")
        return
    end

    %info = app.getFile().Fileinfo;
    %fs = info.NumSamples(1) / ...
    %     seconds(info.DataRecordDuration);

    % 1. Get signal segment indices
    %tStart = app.TimeOffset.Value;
    %tEnd   = tStart + app.TimeWindow.Value;
    %idxStart = round(tStart * fs) + 1;
    %idxEnd   = round(tEnd * fs);
    
    % 2. Define Electrode Positions (10-20 system)
    x = [6.5 5.5 5 5.5 6.5 2.1 0.5 2.1 9 11.5 12.5 13 12.5 11.5 15.9 17.5 15.9 9 9]';
    y = [0.5 4.5 8.5 12.5 16.5 3.5 8.5 13.5 4.5 0.5 4.5 8.5 12.5 16.5 3.5 8.5 13.5 8.5 12.5]';
    numChannels = length(x);

    % 3. Calculate AppEn for EVERY channel
    ZdataEntropy = zeros(numChannels, 1);
    m = 2; % Standard AppEn parameter
    
    d = uiprogressdlg(app.UIFigure, 'Title', 'Calculating Topo AppEn', ...
                      'Message', 'Computing entropy for all electrodes...', ...
                      'Cancelable', 'on');

    for i = 1:numChannels
        if d.CancelRequested, break; end
        
        % Extract physical signal for current channel
        [signal, ~, ~] = app.getSignal(i);
        segment = app.convertToPhysical(signal);
        
        % Define 'r' based on the standard deviation of the current segment
        r = 0.2 * std(segment); 
        
        % Use your optimized fast algorithm
        ZdataEntropy(i) = Utils.ApEn_fast_internal(segment, m, r);
        
        d.Value = i / numChannels;
    end
    close(d);

    % 4. Interpolation & Visualization
    z = rescale(ZdataEntropy, 0, 1);
    mapTitle = "Entropy Map (AppEn)";

    [xq, yq] = meshgrid(0:0.1:18, 0:0.1:18);
    F = scatteredInterpolant(x, y, z, 'linear', 'none');
    zq = F(xq, yq);

    % 5. Create Plot
    ax = app.Axes;
    cla(ax, "reset");

    surf(ax, xq, yq, zq, 'EdgeColor', 'none'); 
    hold(ax, 'on');
    view(ax, 2); shading(ax, 'interp'); colormap(ax, 'parula'); colorbar(ax);
    axis(ax, 'equal', 'off'); set(ax, 'ydir', 'reverse');
    title(ax, mapTitle);
    c = colorbar(ax);
    c.Label.String = "T value";

    % Head Outline & Labels (Standard settings)
    theta = -2*pi : 0.01 : 2*pi;
    plot3(ax, 8.5*cos(theta)+9, 8.5*sin(theta)+8.5, ones(size(theta))*2, 'LineWidth', 12, 'Color', [0.9 0.9 0.9]); 
    plot3(ax, 8*cos(theta)+9, 8*sin(theta)+8.5, ones(size(theta))*2.1, 'LineWidth', 2, 'Color', 'k');
    plot3(ax, [8.5 9 9.5], [0.1 -0.5 0.1], [3 3 3], 'k', 'LineWidth', 2); % Nose
    
    xLabels = [6.5 5.5 5 5.5 6.5 3 1.5 3 9 11.5 12.5 13 12.5 11.5 15 16.5 15 9 9];
    yLabels = [1.5 4.5 8.5 12.5 15.5 4 8.5 13 4.5 1.5 4.5 8.5 12.5 15.5 4 8.5 13 8.5 12.5];
    for i = 1:numChannels
        lbl = erase(app.getFile().Record.Properties.VariableNames{i}, ...
            ["EEG", "-LE", "_LE", "LE"]);
        text(ax, xLabels(i), yLabels(i), 5, lbl, 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 8);
    end
end
