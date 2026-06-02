function ApEn = apEnTable(app, file, filename)
    d2 = uiprogressdlg(app.UIFigure, ...
        Title   = "Calculating ApEn: " + filename, ...
        Message = "Please wait...");

    regions = string(fieldnames(app.Regions));
    asymLabels = string(fieldnames(app.AsymPairs));
    bands = string(app.BandSel.Items(2:end));

    nR = numel(regions);
    nA = numel(asymLabels);
    nB = numel(bands);

    region_means = zeros(nR, nB);
    asym_means = zeros(nA, nB);

    all_elecnames = string.empty;
    elec_region_idx = [];
    for r = 1:nR
        elecnames = string(fieldnames(app.Regions.(regions(r))));
        all_elecnames = [all_elecnames; elecnames];
        elec_region_idx = [elec_region_idx; repmat(r, numel(elecnames), 1)];
    end
    nElecTotal = numel(all_elecnames);

    asym_pairs = struct();
    for a = 1:nA
        asym_pairs.(asymLabels(a)) = app.AsymPairs.(asymLabels(a));
    end

    for b = 1:nB
        %app.BandSel.Value = int2str(b);

        signals_flat = cell(nElecTotal, 1);
        Fs_flat = zeros(nElecTotal, 1);
        for i = 1:nElecTotal
            e = app.getElectrodeIndex(all_elecnames(i));
            signals_flat{i} = Utils.getSignal(app, e, b);
            Fs_flat(i) = file.Fileinfo.NumSamples(e);
        end

        vals_flat = zeros(nElecTotal, 1);
        parfor i = 1:nElecTotal
            vals_flat(i) = computeElecApEn(signals_flat{i}, Fs_flat(i));
        end

        elec_apen = struct();
        for r = 1:nR
            idx = elec_region_idx == r;
            region_means(r, b) = mean(vals_flat(idx));
            elecnames = all_elecnames(idx);
            vals_r = vals_flat(idx);
            for i = 1:sum(idx)
                elec_apen.(elecnames(i)) = vals_r(i);
            end
        end

        d2.Value = min(1, b / nB);

        for a = 1:nA
            pairs = asym_pairs.(asymLabels(a));
            nPairs = size(pairs, 1);
            asym_sum = 0;
            for p = 1:nPairs
                asym_sum = asym_sum + abs(elec_apen.(pairs(p,1)) - elec_apen.(pairs(p,2)));
            end
            asym_means(a, b) = asym_sum / nPairs;
        end
    end

    [R, ~] = ndgrid(regions, bands);
    [A, Bnd] = ndgrid(asymLabels, bands);
    colNames = ["ApEn_"+R(:)+"_"+Bnd(:); "ApEn_"+A(:)+"_"+Bnd(:)];

    ApEn = array2table([region_means(:)', asym_means(:)'], ...
           VariableNames = colNames);

    d2.Value = 1;
    close(d2);
end

function val = computeElecApEn(signal, Fs)
    m = 2;
    r_val = 0.2 * std(signal);

    win_len = 1 * Fs;
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
end
