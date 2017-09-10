% Test script for STFT
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  29-Jul-2014 15:08:45

clear;
close all;

% stData = load('handel');
% vSignal = stData.y;
% fs      = stData.Fs;
[vSignal,fs] = audioread('speech.wav');

blocklen = round(20e-3 * fs);
overlap  = round(blocklen * 0.5);
vWindow  = hann(blocklen,'periodic');
nfft     = pow2(nextpow2(blocklen));


[mSpectr,vFreq,vTime] = STFT(vSignal,vWindow,overlap,nfft,fs);

figure;
STFT(vSignal,vWindow,overlap,nfft,fs);

% figure;
% STFT(vSignal);


% End of file: <STFT_test.m>
