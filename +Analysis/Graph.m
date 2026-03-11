function Graph(app)
    [signals, fs, offset, labels] = app.getSelectedSignals();

    if isempty(signals)
        return
    end

    start = offset/fs;
    finish = (length(signals{1})+offset)/fs;

    cla(app.Axes, "reset");
    grid(app.Axes, "on");

    N = length(signals);
    legend_labels = cell(N, 1);

    hold(app.Axes, "on");
    for k = 1:N
        if N == 1
            coffset = 0;
            legend_labels{k} = labels{k};
        else
            coffset = ((N/2)-k)*100;
            legend_labels{k} = sprintf('%s (%+d)', labels{k}, coffset);
        end
        plot(app.Axes, linspace(start, finish, length(signals{k})), ...
            signals{k} + coffset);
    end
    hold(app.Axes, "off");

    title(app.Axes, "EEG Signal - Graph");
    legend(app.Axes, legend_labels);
    xlabel(app.Axes, "Time (s)");
    ylabel(app.Axes, "Amplitude (µV)");
    app.setAxesLimit(labels{1}, [start finish]);
end
