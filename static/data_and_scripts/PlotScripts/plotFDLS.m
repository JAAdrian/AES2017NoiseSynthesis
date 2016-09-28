% <purpose of this file>
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  22-Sep-2015 17:55:54
% Updated:  <>

clear;
close all;

addpath('deps');


ColorNumOrd   = 9;
ColorDenumOrd = 9;



[vSignal,fs] = returnPlotSignal();
vSignal      = vSignal(1:min(round(5*fs),length(vSignal)),1);


blocklenSec = 50e-3;
blocklen    = round(blocklenSec * fs);
overlap     = round(0.5 * blocklen);
nfft        = pow2(nextpow2(blocklen));
vWin        = hann(blocklen,'periodic');

mSTFT = STFT(...
    vSignal,...
    vWin,...
    overlap,...
    nfft,...
    fs...
    );

vPowers = mean(mSTFT.*conj(mSTFT),2);
vPowers([1,end]) = 2*vPowers([1,end]);
vPowers = vPowers / (fs * norm(vWin));

vFreq = linspace(0,fs/2,nfft/2+1);

stAlgo.fs   = fs;                   % sampling rate
stAlgo.type = 'fractional-octave';  % type of spectral smoothing
                                    % . 'fractional-octave' or
                                    % . 'fixed-bandwidth'

stAlgo.bandwidth = 1;           % bandwidth
                                % . in octaves for 'fractional-octave'
                                % . in Hz for 'fixed-bandwidth'

stAlgo.L_FFT = nfft;            % length of the DFT

% initialize the smoothing algorithm
stAlgo = spectralsmoothing_init(stAlgo);

% perform the smoothing
vPowersSmooth = spectralsmoothing_process(vPowers, stAlgo);

vWeights = ones(length(vPowersSmooth),1);
% vWeights = logspace(log10(1),log10(vFreq(end)),length(vPowersSmooth));

[b,a] = FDLSDesign(...
    ColorNumOrd,...
    ColorDenumOrd,...
    vFreq,...
    vPowersSmooth,...
    fs,...
    vWeights);

[vFDLS] = freqz(b,a,nfft/2+1,fs);

% lMSE = mean((log10(abs(vFDLS)) - log10(sqrt(vPowers))).^2);
dist_cosh = distchpf(abs(vFDLS).',vPowers.');


%% plot that jazz

hf = figure;
plot(vFreq,10*log10(vPowers + eps^2),'color',0.7*[1 1 1]); hold on;
plot(vFreq,10*log10(vPowersSmooth + eps^2),'k--');
plot(vFreq,10*log10(abs(vFDLS) + eps^2),'k'); hold off;
grid on;

set(gca,'xscale','log');
xlabel('Frequency in Hz');
ylabel('PSD in dB re. 1^2/Hz');
legend('Welch Periodogram','Smoothed Periodogram','FDLS Approximation',...
    'location','southwest');

axis tight;
axis([20,20.5e3 -105 inf]);



%-------------------- Licence ---------------------------------------------
% Copyright (c) 2015, J.-A. Adrian
% Institute for Hearing Technology and Audiology
% Jade University of Applied Sciences
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
%
%	1. Redistributions of source code must retain the above copyright
%	   notice, this list of conditions and the following disclaimer.
%
%	2. Redistributions in binary form must reproduce the above copyright
%	   notice, this list of conditions and the following disclaimer in
%	   the documentation and/or other materials provided with the
%	   distribution.
%
%	3. Neither the name of the copyright holder nor the names of its
%	   contributors may be used to endorse or promote products derived
%	   from this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
% IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
% TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
% PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
% HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
% TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

% End of file: plotFDLS.m
