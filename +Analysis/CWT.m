function CWT(app)
    [signal, fs, offset, label] = Utils.getSelectedSignal(app);

    if isempty(signal)
        return
    end

    cla(app.Axes, "reset");
    [cfs, F] = cwt(signal, fs);
    mag = abs(cfs);
    
    [F, ord] = sort(F);
    mag = mag(ord, :);
    
    Flin = linspace(F(1), F(end), 200);
    magLin = interp1(F, mag, Flin);
    
    t = offset + (0:numel(signal)-1)/fs;
    imagesc(app.Axes, t, Flin, magLin);
    
    axis(app.Axes, 'xy');
    title(app.Axes, "CWT — " + label + " (Morse)");
    xlabel(app.Axes, 'Time (s)');
    ylabel(app.Axes, 'Frequency (Hz)');
    colorbar(app.Axes);
end
