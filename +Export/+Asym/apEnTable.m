function ApEn = apEnTable(app, file, filename, winlen)
    d2 = uiprogressdlg(app.UIFigure, ...
        Title   = "Calculating ApEn: " + filename, ...
        Message = "Please wait...");

    asymLabels = struct2cell(app.AsymPairs);
    asymLabels = vertcat(asymLabels{:});
    bands = string(app.BandSel.Items(2:end));
    all_elecs = unique(asymLabels(:));

    nA = size(asymLabels, 1);
    nB = numel(bands);
    nE = numel(all_elecs);

    asym_vals = zeros(nA, nB);

    for b = 1:nB
        signals = cell(nE, 1);
        Fs_arr = zeros(nE, 1);
        for i = 1:nE
            e = app.getElectrodeIndex(all_elecs(i));
            signals{i} = Utils.getSignal(app, e, b);
            Fs_arr(i) = file.Fileinfo.NumSamples(e);
        end

        apen_vals = zeros(nE, 1);
        parfor i = 1:nE
            apen_vals(i) = computeElecApEn(signals{i}, Fs_arr(i), winlen);
        end

        elec_apen = struct();
        for i = 1:nE
            elec_apen.(all_elecs(i)) = apen_vals(i);
        end

        for a = 1:nA
            asym_vals(a, b) = ...
                abs(elec_apen.(asymLabels(a, 1)) ...
                    - elec_apen.(asymLabels(a, 2)));
        end

        d2.Value = min(1, b / nB);
    end

    pairLabels = asymLabels(:, 1) + asymLabels(:, 2);
    [P, B] = ndgrid(pairLabels, bands);
    colNames = "ApEn_" + P(:) + "_" + B(:);

    ApEn = array2table(asym_vals(:)', VariableNames=colNames);

    d2.Value = 1;
    close(d2);
end

function [val, diff] = computeElecApEn(signal, Fs, winlen)
    m = 2;
    r_val = 0.2 * std(signal);

    win_len = winlen * Fs;
    K = 3;
    max_start = length(signal) - win_len;

    if max_start <= 0
        apen_vals = Utils.ApEn_fast_internal(signal, m, r_val);
    else
        starts = round(linspace(1, max_start, K))';
        apen_vals = arrayfun(@(k) ...
            Utils.ApEn_fast_internal(signal(starts(k) : starts(k)+win_len-1), m, r_val), ...
            (1:K)');
    end

    val = mean(apen_vals);
    diff = apen_vals(end) - apen_vals(1);
end
