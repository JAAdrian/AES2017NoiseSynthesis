function stAlgo = spectralsmoothing_init(stAlgo)

% Implementation of the algorithm described in
%     "Generalized Fractional-Octave Smoothing of Audio and Acoustic
%     Responses", P. D. Hatziantoniou and J. N. Mourjopoulos
%
% 06.10.08: v0.9  - complex smoothing not yet implemented!
%                 - only "standard" (rect, hann, hamming etc.) window
%                   supported
% 11.08.09: v0.95 - debugged based on M. Ruhland's C++ implementation

% $Revision: 29 $
% $Author: brandt $
% $Date: 2011-03-30 20:43:53 +0200 (Mi, 30 Mrz 2011) $

% TODO:
% . test both bark ('bark1' and 'bark2' modes)

%% internal stuff...
k = (0 : (stAlgo.L_FFT)-1)';        % discrete frequency vector
f_bin = stAlgo.fs / stAlgo.L_FFT;   % bin bandwidth

%% dependency of resolution bandwidth on frequency
switch(stAlgo.type)
    case 'fractional-octave'
        f_u = 2^(0.5 * stAlgo.bandwidth)*k*f_bin;
        f_l = 0.5^(0.5*stAlgo.bandwidth)*k*f_bin;
        P = f_u - f_l;
        stAlgo.m = [floor(0.5 * P(1:(stAlgo.L_FFT)/2+1) / f_bin); ...
            floor(0.5 * P((stAlgo.L_FFT)-((stAlgo.L_FFT)/2+1:(stAlgo.L_FFT)-1)) / f_bin)]+1;
    case 'fixed-bandwidth'
         stAlgo.m = fix(0.5 * stAlgo.bandwidth/f_bin) * ones(1, stAlgo.L_FFT); % TODO: geändert und noch nicht eingehend getestet
                                                                               % (Faktor 0.5)
    case 'bark1'
        % define the edge and center frequencies of the bark bands:
        feBark = [0, 100, 200, 300, 400, 510, 630, 770, 920, 1080, 1270, 1480, 1720, 2000, 2320, 2700, 3150, 3700, 4400, 5300, 6400, 7700, 9500, 12000, 15500, 20500, 27000];
        fcBark = [50, 150, 250, 350, 450, 570, 700, 840, 1000, 1170, 1370, 1600, 1850, 2150, 2500, 2900, 3400, 4000, 4800, 5800, 7000, 8500, 10500, 13500];

        % the number of bark bands:
        nBark = length(feBark)-1;

        % determine spectral windows:
        f_l = zeros(1, nBark);
        f_u = zeros(1, nBark);
        for k = 1:nBark
            f_l(k) = feBark(k);
            f_u(k) = feBark(k+1);
        end
        P_temp = f_u - f_l;
        P = zeros(stAlgo.L_FFT, 1);
        for k = 0 : stAlgo.L_FFT/2
            f_k = k * f_bin;
            barkBand = find(f_k >= feBark, 1, 'last');
            P(k+1) = P_temp(barkBand);
        end
        stAlgo.m = [floor(0.5 * P(1:(stAlgo.L_FFT)/2+1) / f_bin); ...
            floor(0.5 * P((stAlgo.L_FFT)-((stAlgo.L_FFT)/2+1:(stAlgo.L_FFT)-1)) / f_bin)]+1;
        assignin('base', 'm1', stAlgo.m);
        assignin('base', 'P1', P);
    case 'bark2'
        highestBand = (26.81 / (1 + 1960 / (stAlgo.fs/2) )) - 0.53;
        [fcBark, BBark] = bark2hz(linspace(1, highestBand, stAlgo.L_FFT/2+1));
        f_l = fcBark - BBark/2;
        f_u = fcBark + BBark/2;
        P = (f_u - f_l)';
        stAlgo.m = [floor(0.5 * P(1:(stAlgo.L_FFT)/2+1) / f_bin); ...
            floor(0.5 * P((stAlgo.L_FFT)-((stAlgo.L_FFT)/2+1:(stAlgo.L_FFT)-1)) / f_bin)]+1;
        assignin('base', 'm2', stAlgo.m);
        assignin('base', 'P2', P);
    otherwise
        error('this type of nonuniform smoothing is unknown');
end

%% calculate the smoothing matrix
b = 0.5; % 1.00 -> rectangular
         % 0.50 -> Hann window
         % 0.54 -> Hamming window
M = max(stAlgo.m);
for i_m = 1 : M
    for k = 0 : (stAlgo.L_FFT)
        if (k >= 0 && k <= i_m)
            stAlgo.W_sm(i_m, k+1) = (b-(b-1)*cos((pi/(i_m))*k)) / (2*b*(i_m+1)-1);
        elseif (k > stAlgo.L_FFT-i_m-1 && k <= stAlgo.L_FFT-1)
            stAlgo.W_sm(i_m, k+1) = (b-(b-1)*cos((pi/(i_m))*(k-stAlgo.L_FFT))) / (2*b*(i_m+1)-1);
        else
            stAlgo.W_sm(i_m, k+1) = 0;
        end
    end
end

end % of function

function [f, B] = bark2hz(b)

%f=52547.6*(26.28-b-(22.11-1.1*b).*(b>20.1)/6.1-(3*b-6).*(b<2)/17).^(-1)-1960;
f = 1960 ./ (26.81 ./ (b + 0.53) - 1);

% bandwidth
B = 52548 ./ (b.^2 - 52.56.*b + 690.39);

end
