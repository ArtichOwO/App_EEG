function [signal, fs, offset, label] = getSelectedSignal(app)
    signal = [];
    fs = 0;
    offset = 0;
    label = "";

    if ~app.checkFileElectrode()
        return
    end

    label = app.ElectrodeList.Value{1};
    [signal, fs, offset] = Utils.getSignal(app, label);
end
