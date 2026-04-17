function exportData(app)
    if ~app.checkFile()
        return;
    end

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
    ApEn = table();

    d = uiprogressdlg(app.UIFigure, ...
                      Title="Exporting data", Message="Please wait...");

    for f = 1:nFiles
        app.selectFile(f);
        file = app.getFile();
        Filenames{f} = extractBefore(file.Fileinfo.Filename, ".edf");
        
        ApEn = [ApEn; Export.apEnTable(app, file, Filenames{f})];
        
        d.Value = min(1, d.Value + 1/nFiles);
    end
    d.Value = 1;
    delete(d);
    
    T = [table(Filenames) ApEn];
    writetable(T, File);
end
