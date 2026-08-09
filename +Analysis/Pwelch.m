function Pwelch(app)
    [signal, fs, offset, label] = Utils.getSelectedSignal(app);

    if isempty(signal)
        return
    end

    start = offset/fs;
    finish = (length(signal)+offset)/fs;

    cla(app.Axes, "reset");
    grid(app.Axes, "on");

    [pxx, f] = pwelch(signal(start+1:finish), [], [], [], fs);
    plot(app.Axes, f, 10*log10(pxx));

    title(app.Axes, "EEG Signal - Pwelch");
    xlabel(app.Axes, "Time (s)");
    ylabel(app.Axes, "Amplitude (µV)");
    app.setAxesLimit(label, [start finish]);
end
