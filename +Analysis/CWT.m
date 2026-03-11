function CWT(app)
    [signal, fs, offset, label] = getSelectedSignal(app);

    if isempty(signal)
        return
    end

    [cfs, F] = cwt(signal, fs);

    imagesc(app.Axes, offset+(0:numel(signal)-1)/fs, F, abs(cfs));
    axis(app.Axes, 'xy');
    title(app.Axes, strcat("CWT — ", label));
    xlabel(app.Axes, 'Time (s)');
    ylabel(app.Axes, 'Frequency (Hz)');
    title(app.Axes, 'CWT');
    colorbar(app.Axes);
end
