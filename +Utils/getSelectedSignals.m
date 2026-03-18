function [signals, fs, offset, labels] = getSelectedSignals(app)
    labels = app.ElectrodeList.Value;
    signals = cell(length(labels), 1);
    fs = 0;
    offset = 0;

    if ~app.checkFileElectrode()
        return
    end

    for k = 1:length(labels)
        [signals{k}, fs, offset] = Utils.getSignal(app, labels{k});
    end
end
