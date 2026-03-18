function TopoAmp(app)
    if isempty(app.getFile())
        uialert(app.UIFigure, ...
            "Load an EDF file first", "TopoAmp Error")
        return
    end

    info = app.getFile().Fileinfo;

    % --- Get time values from the GUI ---
    tStart = app.TimeOffset.Value;
    tEnd   = tStart + app.TimeWindow.Value;
    
    % --- Compute sampling frequency ---
    fs = info.NumSamples(1) / ...
         seconds(info.DataRecordDuration);
    
    % --- Convert time (seconds) → sample indices ---
    idxStart = round(tStart * fs) + 1;
    idxEnd   = round(tEnd * fs);
    
    % --- Safety check for invalid interval ---
    if idxStart >= idxEnd
        uialert(app.UIFigure, 'Invalid time interval', 'TopoAmp Error');
        return
    end

    fprintf('Using time interval: %.2f s to %.2f s\n', tStart, tEnd);

    % --- Define frequency band ---
    %fBand = [8 13]; % Example: Alpha band (8–13 Hz)

    % --- Electrode positions (10-20 system layout) ---
    x = [6.5 5.5 5 5.5 6.5 2.1 0.5 2.1 9 11.5 12.5 13 12.5 11.5 15.9 17.5 15.9 9 9]';
    y = [0.5 4.5 8.5 12.5 16.5 3.5 8.5 13.5 4.5 0.5 4.5 8.5 12.5 16.5 3.5 8.5 13.5 8.5 12.5]';
    numChannels = length(x);

    % --- Extract segment and compute bandpower for each channel ---
    ZdataRaw = zeros(numChannels, 1);
    for i = 1:numChannels
        % Get full signal in physical units
        [signal, ~, ~] = Utils.getSignal(app, i);
        segment = app.convertToPhysical(signal);
        
        % Compute band power
        ZdataRaw(i) = bandpower(segment); 
    end

    % --- Normalize for color mapping ---
    z = rescale(ZdataRaw, 0, 1);

    % --- Interpolation grid ---
    [xq, yq] = meshgrid(0:0.1:18, 0:0.1:18);
    F = scatteredInterpolant(x, y, z, 'linear', 'none');
    zq = F(xq, yq);

    ax = app.Axes;
    cla(ax, "reset");
    
    % Plot interpolated surface
    surf(ax, xq, yq, zq, 'EdgeColor', 'none'); 
    hold(ax, 'on');
    
    view(ax, 2); 
    shading(ax, 'interp');
    colormap(ax, 'jet');
    c = colorbar(ax);
    c.Label.String = "T value";
    axis(ax, 'equal', 'off');
    set(ax, 'ydir', 'reverse');
    title(ax, "Brain Map — Amplitude");

    % --- Draw head outline ---
    theta = -2*pi : 0.01 : 2*pi;
    cx = 9; 
    cy = 8.5;

    plot3(ax, 8.5*cos(theta)+cx, 8.5*sin(theta)+cy, ...
          ones(size(theta))*2, ...
          'LineWidth', 12, 'Color', [0.9 0.9 0.9]); 

    plot3(ax, 8*cos(theta)+cx, 8*sin(theta)+cy, ...
          ones(size(theta))*2.1, ...
          'LineWidth', 2, 'Color', 'k');

    % --- Draw nose ---
    plot3(ax, [8.5 9 9.5], [0.1 -0.5 0.1], ...
          [3 3 3], 'k', 'LineWidth', 2);

    % --- Electrode labels ---
    xLabels = [6.5 5.5 5 5.5 6.5 3 1.5 3 9 11.5 12.5 13 12.5 11.5 15 16.5 15 9 9];
    yLabels = [1.5 4.5 8.5 12.5 15.5 4 8.5 13 4.5 1.5 4.5 8.5 12.5 15.5 4 8.5 13 8.5 12.5];
    
    for i = 1:numChannels
        lbl = erase(app.getFile().Record.Properties.VariableNames{i}, ...
            ["EEG", "-LE", "_LE", "LE"]);
        text(ax, xLabels(i), yLabels(i), 5, lbl, ...
            'HorizontalAlignment', 'center', ...
            'FontWeight', 'bold', ...
            'Color', 'k', ...
            'FontSize', 8);
    end
end
