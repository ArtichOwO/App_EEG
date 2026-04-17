function ApEn = apEnTable(app, file, filename)
    d2 = uiprogressdlg(app.UIFigure, ...
        Title = "Calculating ApEn: " + filename, ...
        Message = "Please wait...");

    regions = string(app.RegionList.Items);
    bands   = string(app.BandSel.Items(2:end));

    nR = numel(regions);
    nB = numel(bands);

    region_means = zeros(nR, nB);

    total_steps = nB * 19;
    step = 0;

    for b = 1:nB
        app.BandSel.Value = int2str(b);

        for r_idx = 1:nR
            region = regions(r_idx);

            elecnames = fieldnames(app.Regions.(region));
            apen_mean = 0;

            for i = 1:numel(elecnames)
                elecname = elecnames{i};

                e = app.getElectrodeIndex(elecname);
                signal = Utils.getSignal(app, e);

                m = 2;
                r_val = 0.2 * std(signal);

                Fs = file.Fileinfo.NumSamples(e);

                win_sec = 10;
                win_len = win_sec * Fs;
                
                K = 5;
                
                L = length(signal);
                max_start = L - win_len;
                
                if max_start <= 0
                    apen_vals = Utils.ApEn_fast_internal(signal, m, r_val);
                else
                    starts = randi(max_start, K, 1);
                    apen_vals = zeros(K,1);
                
                    for k = 1:K
                        idx = starts(k) : starts(k) + win_len - 1;
                        apen_vals(k) = Utils.ApEn_fast_internal(signal(idx), m, r_val);
                    end
                end

                apen_mean = apen_mean + mean(apen_vals);

                step = step + 1;
                d2.Value = min(1, step / total_steps);
            end

            apen_mean = apen_mean / numel(elecnames);
            region_means(r_idx, b) = apen_mean;
        end
    end

    [R, B] = ndgrid(regions, bands);
    names = "ApEn_" + R(:) + "_" + B(:);
    ApEn = array2table(region_means(:)', VariableNames = names);

    d2.Value = 1;
    close(d2);
end
