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
    asym_means   = zeros(nA, nB);

    nElec = sum(cellfun(@(r) numel(fieldnames(app.Regions.(r))), cellstr(regions)));
    step  = 0;

    for b = 1:nB
        app.BandSel.Value = int2str(b);
        elec_apen = struct();

        for r = 1:nR
            region    = regions(r);
            elecnames = string(fieldnames(app.Regions.(region)));
            apen_sum  = 0;

            for i = 1:numel(elecnames)
                val = computeElecApEn(app, file, elecnames(i));
                elec_apen.(elecnames(i)) = val;
                apen_sum = apen_sum + val;

                step = step + 1;
                d2.Value = min(1, step / (nB * nElec));
            end

            region_means(r, b) = apen_sum / numel(elecnames);
        end

        for a = 1:nA
            pairs = app.AsymPairs.(asymLabels(a));
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

    colNames = [ "ApEn_"+R(:)+"_"+Bnd(:); "ApEn_"+A(:)+"_"+Bnd(:) ];

    ApEn = array2table([region_means(:)', asym_means(:)'], ...
           VariableNames = colNames);

    d2.Value = 1;
    close(d2);
end

function val = computeElecApEn(app, file, elecname)
    e = app.getElectrodeIndex(elecname);
    signal = Utils.getSignal(app, e);

    m = 2;
    r_val = 0.2 * std(signal);
    Fs = file.Fileinfo.NumSamples(e);

    win_len = 10 * Fs;
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
