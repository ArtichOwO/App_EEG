function bands = DWT(signal, mw)
    N = 5;%7;
    
    [C, L] = wavedec(signal, N, mw);

    D2 = wrcoef('d', C, L, mw, 2);
    D3 = wrcoef('d', C, L, mw, 3);
    D4 = wrcoef('d', C, L, mw, 4);
    D5 = wrcoef('d', C, L, mw, 5);
    %D6 = wrcoef('d', C, L, mw, 6);
    %D7 = wrcoef('d', C, L, mw, 7);
    %A7 = wrcoef('a', C, L, mw, 7);
    A5 = wrcoef('a', C, L, mw, 5);

    %{
    gamma = D2 + D3;   %-> 16–64 Hz
    beta  = D4;        %-> 8–16 Hz
    alpha = D5;        %-> 4–8 Hz
    theta = D6;        %-> 2–4 Hz
    delta = D7 + A7;   %-> 0–2 Hz
    %}

    delta = A5; %D6 + D7 + A7; %-> 0–4 Hz
    theta = D5;           %-> 4–8 Hz
    alpha = D4;           %-> 8–16 Hz
    beta  = D3;           %-> 16–32 Hz
    gamma = D2;           %-> 32–64 Hz

    bands = {gamma, beta, alpha, theta, delta};
end
