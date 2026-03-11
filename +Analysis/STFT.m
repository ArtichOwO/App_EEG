function STFT(app)
    [signal, fs, offset, label] = getSelectedSignal(app);

    if isempty(signal)
        return
    end

    win = hamming(256);
    overlap = 200;
    nfft = 512;

    [s,f,t] = stft(signal, fs, ...
                   Window=win, ...
                   OverlapLength=overlap, ...
                   FFTLength=nfft);

    pos = f >= 0;
    imagesc(app.Axes, t+offset, f(pos), mag2db(abs(s(pos, :))));
    title(app.Axes, strcat("STFT — ", label));
    axis(app.Axes, 'xy');
    xlabel(app.Axes, 'Time (s)');
    ylabel(app.Axes, 'Frequency (Hz)');
    colorbar(app.Axes);
end
