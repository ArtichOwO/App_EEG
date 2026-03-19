function exportData(app)
    [FileName, PathName, ~] = uiputfile("*.csv", "Save table as:");
    if ~ischar(FileName)
        return;
    end
    File = fullfile(PathName, FileName);

    nFiles = app.numberOfFiles();

    file = app.getFile();
    lbl = strtrim(erase(file.Fileinfo.SignalLabels, ...
        ["EEG", "-LE", "_LE", "LE"]));
    lbl = lbl(1:19);

    Filenames = cell(nFiles, 1);
    ApEn = array2table(zeros(0, numel(lbl)), ...
        VariableNames=strcat("ApEn_", lbl));

    d = uiprogressdlg(app.UIFigure, ...
                      Title="Exporting data", Message="Please wait...");

    for f = 1:nFiles
        app.selectFile(f);
        file = app.getFile();

        Filenames{f} = extractBefore(file.Fileinfo.Filename, ".edf");
        
        d2 = uiprogressdlg(app.UIFigure, ...
                           Title=strcat("Calculating ApEn: ", Filenames{f}), ...
                           Message="Please wait...");
        apen_means = zeros(1, 19);

        for e = 1:19
            signal = Utils.getSignal(app, e);
            m = 2;
            r = 0.2 * std(signal);
        
            Fs = file.Fileinfo.NumSamples(e);
            win_sec = 1;
            win_len = win_sec * Fs;
        
            num_win = floor(length(signal)/win_len);
            apen_vals = zeros(num_win,1);
        
            for w = 1:num_win
                idx = (w-1)*win_len + 1 : w*win_len;
                apen_vals(w) = Utils.ApEn_fast_internal(signal(idx), m, r);
            end
        
            apen_means(e) = mean(apen_vals);
            d2.Value = min(1, d2.Value + 1/19);
        end
        
        d2.Value = 1;
        close(d2);
        
        Tline = array2table(apen_means, ...
            VariableNames=strcat("ApEn_", lbl));
        ApEn = [ApEn; Tline];
        
        d.Value = min(1, d.Value + 1/nFiles);
    end
    d.Value = 1;
    close(d);
    
    T = [table(Filenames) ApEn];
    writetable(T, File);
end
