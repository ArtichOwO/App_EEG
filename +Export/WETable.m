function WE = WETable(app, file, filename)
    d2 = uiprogressdlg(app.UIFigure, ...
        Title   = "Calculating WE: " + filename, ...
        Message = "Please wait...");

    regions    = string(fieldnames(app.Regions));
    asymLabels = string(fieldnames(app.AsymPairs));

    nR = numel(regions);
    nA = numel(asymLabels);

    region_means = zeros(nR, 1);
    asym_means   = zeros(nA, 1);

    nElec = sum(cellfun(@(r) numel(fieldnames(app.Regions.(r))), cellstr(regions)));
    step  = 0;

    elec_we = struct();

    for r = 1:nR
        region    = regions(r);
        elecnames = string(fieldnames(app.Regions.(region)));
        we_sum    = 0;

        for i = 1:numel(elecnames)
            val = computeElecWE(app, file, elecnames(i));
            elec_we.(elecnames(i)) = val;
            we_sum = we_sum + val;

            step = step + 1;
            d2.Value = min(1, step / nElec);
        end

        region_means(r) = we_sum / numel(elecnames);
    end

    for a = 1:nA
        pairs    = app.AsymPairs.(asymLabels(a));
        nPairs   = size(pairs, 1);
        asym_sum = 0;

        for p = 1:nPairs
            asym_sum = asym_sum + abs(elec_we.(pairs(p,1)) - elec_we.(pairs(p,2)));
        end

        asym_means(a) = asym_sum / nPairs;
    end

    colNames = [ "WE_" + regions; "WE_" + asymLabels ];

    WE = array2table([region_means; asym_means]', ...
        VariableNames = colNames);

    d2.Value = 1;
    close(d2);
end

function val = computeElecWE(app, file, elecname)
    e = app.getElectrodeIndex(elecname);
    signal = Utils.getSignal(app, e);
    val = computeWE(app, signal);

    %{
    Fs = file.Fileinfo.NumSamples(e);

    win_len = 5 * Fs;
    K = 3;
    max_start = length(signal) - win_len;

    if max_start <= 0
        val = computeWE(app, signal);
    else
        starts = randi(max_start, K, 1);
        we_vals = arrayfun(@(k) ...
            computeWE(app, signal(starts(k) : starts(k)+win_len-1)), ...
            (1:K)');
        val = mean(we_vals);
    end
    %}
end

function we = computeWE(app, signal)
    N = 7;
    mw = app.MWSel.Value;

    [C, L] = wavedec(signal, N, mw);

    E = zeros(1, N + 1);
    for i = 1:N
        coeffs = detcoef(C, L, i);
        E(i) = sum(coeffs .^ 2);
    end

    coeffs = appcoef(C, L, mw, N);
    E(N + 1) = sum(coeffs .^ 2);

    p = E / sum(E);
    p = p(p > 0);
    we = -sum(p .* log(p));
end
