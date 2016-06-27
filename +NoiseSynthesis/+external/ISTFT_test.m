% Test the ISTFT
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  27-Mar-2015 16:00:08

clear;
close all;

[vSignal,fs] = audioread('speech.wav');

blocklen = round(fs * 32e-3);
overlap  = round(0.5 * blocklen);
nfft     = pow2(nextpow2(blocklen));
vWin     = sqrt(hann(nfft,'periodic'));

mSTFT = STFT(vSignal,vWin,overlap,nfft,fs);

vSignalReconst = ISTFT(mSTFT,[],vWin,overlap,length(vSignal));

figure;
plot([vSignal, vSignalReconst]);

soundsc(vSignal,fs);
pause(length(vSignal)/fs + 0.5);
soundsc(vSignalReconst,fs);


% End of file: ISTFT_test.m
