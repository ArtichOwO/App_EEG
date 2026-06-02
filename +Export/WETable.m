function WE = WETable(app, ~, filename)
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

    for r = 1:nR
        region = regions(r);
        elecnames = string(fieldnames(app.Regions.(region)));
        n = numel(elecnames);
    
        signals = cell(n, 1);
        for i = 1:n
            e = app.getElectrodeIndex(elecnames(i));
            signals{i}  = Utils.getSignal(app, e);
        end
        mw = app.MWSel.Value;

        vals = zeros(1, n);
        parfor i = 1:n
            vals(i) = computeElecWE(signals{i}, mw);
        end
    
        for i = 1:n
            elec_we.(elecnames(i)) = vals(i);
        end
    
        region_means(r) = mean(vals);
    
        step     = step + n;
        d2.Value = min(1, step / nElec);
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

function we = computeElecWE(signal, mw)
    N = 7;

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
