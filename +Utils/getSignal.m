function [signal, fs, offset] = getSignal(app, electrode)
    signal = [];
    fs = 0;
    offset = 0;

    if isempty(app.getFile())
        uialert(app.UIFigure, ...
            "Load an EDF file first", "Signal Error")
        return
    end

    if isstring(electrode) || ischar(electrode)
        idx = app.getElectrodeIndex(electrode);
    else
        idx = electrode;
    end

    if isempty(idx)
        uialert(app.UIFigure, ...
            "Channel not found in EDF", "Signal Error")
        return
    end

    signal = app.convertToPhysical( ...
        cell2mat(app.getFile().Record{:, idx}), idx);
    fs = app.getFile().Fileinfo.NumSamples(idx);

    band = str2double(app.BandSel.Value);
    if band > 0
        bands = Utils.DWT(signal, app.MWSel.Value);
        signal = bands{band};
    end

    offset = app.TimeOffset.Value*fs + 1;
    endabs = offset + app.TimeWindow.Value*fs - 1;

    signal = signal(offset:endabs); 
end
