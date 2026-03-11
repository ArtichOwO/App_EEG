function bands = DWT(signal, mw)
    N = 7;
    
    [C, L] = wavedec(signal, N, mw);

    D2 = wrcoef('d', C, L, mw, 2);
    D3 = wrcoef('d', C, L, mw, 3);
    D4 = wrcoef('d', C, L, mw, 4);
    D5 = wrcoef('d', C, L, mw, 5);
    D6 = wrcoef('d', C, L, mw, 6);
    D7 = wrcoef('d', C, L, mw, 7);
    A7 = wrcoef('a', C, L, mw, 7);

    gamma = D2 + D3;
    beta  = D4;
    alpha = D5;
    theta = D6;
    delta = D7 + A7;

    bands = {gamma, beta, alpha, theta, delta};
end
