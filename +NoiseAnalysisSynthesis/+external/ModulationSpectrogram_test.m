% Test script for ModulationSpectrogram
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  08-Oct-2014 12:04:47

clear;
% close all;

fs     = 16e3;
lenSec = 2;

vTime = (0:(lenSec*fs)-1)'/fs;


m    = 1;
fmod = [15, 10, 5, 30];
fc   = [1000, 2000, 3000, 4000];

vModSignal = zeros(length(vTime),1);
% vCarrier   = randn(round(lenSec*fs),1);

for aaComp = 1:length(fmod),
    vCarrier   = cos(2*pi*fc(aaComp)*vTime);
    vModSignal = vModSignal + vCarrier .* (1 + m*cos(2*pi*fmod(aaComp)*vTime));
end

[vModSignal,fs] = audioread('speech.wav');

% figure; plot(vSignal);

blocklen = round(15e-3 * fs);
overlap  = round(blocklen * 0.75);
% overlap  = 60;
vWin     = sqrt(hann(blocklen,'periodic'));
nfft     = pow2(nextpow2(blocklen));
% nfft     = blocklen;
% nfft = 128;

[mModSpec,vFreq,vModFreq,vTime,nTimeBlocks] = ...
    ModulationSpectrogram(vModSignal,vWin,overlap,nfft,fs);
figure;
ModulationSpectrogram(vModSignal,vWin,overlap,nfft,fs);

mPhase = angle(mModSpec);
vMeanPhase = mean(mPhase,1);

% mEnvMod = abs(mModSpec);
% % mEnvMod = mean(mEnvMod,1);
%
% mEnvMod = [mEnvMod, conj(mEnvMod(:,end-1:-1:2))];
%
% mEnvFreq = sqrt(ifft(mEnvMod,[],2));
%
% vModFilter = ifftshift(mEnvFreq(10,:));
%
% figure(2);
% plot(vModFilter);
% figure(3);
% freqz(vModFilter,1);



% % --------------------------------------------------------------------
% mMag      = mModSpec;
% mModSpec  = mMag .* exp(1j * mModPhase);
% mModSpec  = [mModSpec conj(mModSpec(:,end-1:-1:2))];
% mSTFT     = real(ifft(mModSpec,[],2));
% mMag      = abs(mSTFT(:,1:nTimeBlocks));
% mMinPhase = -imag(hilbert(log(mMag)));
% % mMinPhase = rand(size(mMag));
% % mMinPhase = zeros(size(mMag));
%
% mFreqSig = mMag .* exp(1j * mMinPhase);
% mTimeSig = real(ifft([mFreqSig; conj(mFreqSig(end-1:-1:2,:))]));
% vTimeSig = unbuffer(diag(sparse(vWin)) * mTimeSig(1:blocklen,:),overlap);
% vTimeSig = [zeros(length(vModSignal)-length(vTimeSig),1); vTimeSig];
%
% figure(2);
% imagesc(vTime,vFreq,20*log10(max(mMag,eps)),[-100 40]); axis xy;
%
%
% figure(3);
% spectrogram(vModSignal,vWin,overlap,nfft,fs,'yaxis');
%
% soundsc(vTimeSig,fs);




% End of file: ModSpec_test.m
