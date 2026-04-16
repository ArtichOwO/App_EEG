function CWT(app)
    [signal, fs, offset, label] = Utils.getSelectedSignal(app);

    if isempty(signal)
        return
    end

    [cfs, F] = cwt(signal, fs);

    cla(app.Axes, "reset");
    imagesc(app.Axes, offset+(0:numel(signal)-1)/fs, F, abs(cfs));
    %surf(app.Axes, offset+(0:numel(signal)-1)/fs, F, abs(cfs));
    %view(app.Axes, 2);
    
    axis(app.Axes, 'xy');
    title(app.Axes, "CWT — " + label + " (Morse)");
    xlabel(app.Axes, 'Time (s)');
    ylabel(app.Axes, 'Frequency (Hz)');
    colorbar(app.Axes);
end
