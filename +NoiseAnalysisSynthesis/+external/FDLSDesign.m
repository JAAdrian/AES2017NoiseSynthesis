function [b,a,Phase] = FDLSDesign(N_Order, D_Order, Freq_Vec, Magnitude, fs_Hz, vWeights)
% [b,a,Phase] = FDLSDesign(N_Order, D_Order, Freq_Vec, Magnitude, fs_Hz, vWeights)
%
% IN:
% N_Order               numerator order  (number of zeros -1)
% D_Order               denominator order (nuber of poles)
% Freq_Vec              frequency values [Hz]
% magnitude             magnitude values (linear)
%
% OUT:
% b,a                   filter coefficients

%  Create minimum phase filter with FDLS method
% (c) Thorsten Schmidt
%
% Updated: 2015-01-30   (JA): Tidied up some code
%          2015-08-07   (JA): Included freq. weighting

import NoiseSynthesis.external.*

if nargin < 6 || isempty(vWeights),
    vWeights = ones(length(Magnitude),1);
end

Magnitude     = Magnitude(:);
fullMagnitude = [Magnitude' Magnitude(end-1:-1:2)'];

% idx=find(fullMagnitude<eps);
% fullMagnitude(idx)=eps;
fullMagnitude = max(fullMagnitude, eps);

% find minimum phase
H_log = log(fullMagnitude);


hil_H_log = hilbert(H_log);
hil_trans = -imag(hil_H_log);

idx   = 1:floor(length(hil_trans)/2)+1;
Phase = hil_trans(idx);
Phase = Phase(:);

% call FDLS
[b,a] = FDLS(N_Order, D_Order, Freq_Vec, Magnitude, Phase, fs_Hz, vWeights);
