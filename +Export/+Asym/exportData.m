function exportData(app)
    if ~app.checkFile()
        return;
    end

    [FileName, PathName, ~] = uiputfile( ...
        ["*.xlsx" "Excel"; "*.csv" "CSV"], "Save table as:");
    if ~ischar(FileName)
        return;
    end
    File = fullfile(PathName, FileName);

    nFiles = app.numberOfFiles();

    Filenames = cell(nFiles, 1);
    Type = cell(nFiles, 1);
    ApEn = cell(nFiles, 1);
    WE = cell(nFiles, 1);

    d = uiprogressdlg(app.UIFigure, ...
                      Title="Exporting data", Message="Please wait...");

    ApEn_winlen = 2;
    for f = 1:nFiles
        app.selectFile(f);
        file = app.getFile();
        Filenames{f} = extractBefore(file.Fileinfo.Filename, ".edf");
        Type{f} = strtok(file.Fileinfo.Filename);
        ApEn{f} = Export.Asym.apEnTable(app, file, Filenames{f}, ApEn_winlen);
        %WE{f} = Export.Asym.WETable(app, file, Filenames{f});
        
        d.Value = min(1, d.Value + 1/nFiles);
    end
    d.Value = 1;
    delete(d);
    
    T = [table(Filenames) table(Type) vertcat(ApEn{:}) vertcat(WE{:})];
    writetable(T, File, Sheet="Features");
    writetable(table({ ...
            "ApEn_winlen";
            "MW";
            "Date"
        }, { ...
            ApEn_winlen;
            app.MWSel.Value;
            string(datetime, "dd/MM/yyyy")
        }, VariableNames=["Parameter", "Value"]), ...
        File, Sheet="Metadata");
end
