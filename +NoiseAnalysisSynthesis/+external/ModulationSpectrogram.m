function [varargout] = ModulationSpectrogram(vSignal,vWin,overlap,nfft,fs,szPlotScaleMode)
%MODULATIONSPECTROGRAM <purpose in one line!>
% -------------------------------------------------------------------------
% <Detailed description of the function>
%
% Usage: [varargout] = ModulationSpectrogram(vSignal,vWin,overlap,nfft,fs)
%        [varargout] = ModulationSpectrogram(vSignal,vWin,overlap,nfft,fs,szPlotScaleMode)
%
%   Input:   ---------
%           vSignal: Signal vector to be analyzed
%           vWin: Window function to be applied in the STFT
%           overlap: Overlap for the STFT
%           nfft: DFT size for the STFT
%           fs: Sampling rate in Hz
%           szPlotScaleMode: String determining the plot mode.
%               - 'lin': linear modulation freq. axis
%               - 'log': logarithmic modulation freq. axis
%               - 'loglog': log. modulation freq. axis AND log. freq. axis
%
%  Output:   ---------
%           mModSpec: Complex modulation spectrum
%           vFreq: Frequency vector
%           vModFreq: Modulation frequency vector
%           vTime: Time vector
%           numBlocks: Number of STFT blocks
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  08-Oct-2014 12:04:46
%

import NoiseSynthesis.external.*

if nargin < 6 || isempty(szPlotScaleMode),
    szPlotScaleMode = 'lin';
end

[mSpec,vFreq,vTime] = STFT(vSignal,vWin,overlap,nfft,fs);

% get fft params and subsampled sampling rate
hopsize  = length(vWin) - overlap;
fsMod    = round(fs/hopsize);
nfftMod  = pow2(nextpow2(size(mSpec,2)));
mModWin  = diag(sparse(hann(size(mSpec,2),'periodic')));

% compute unscaled and unwindowed magnitude to pass to output. This way the
% output is invertible
mModSpec = fft(log(max(abs(mSpec),eps)),nfftMod,2);
% mModSpec = fft(abs(mSpec),nfftMod,2);
mModSpec = mModSpec(:,1:end/2+1);

% modulation frequency vector dependend on subsampled sampling rate
vModFreq = (0:nfftMod/2)' / nfftMod * fsMod;


if nargout
    varargout = {mModSpec, vFreq, vModFreq, vTime, size(mSpec,2)};
else
    % actual modulation spectrum using window function for smoother display
%     mModSpec = fft(log(max(abs(mSpec),eps)) * mModWin,nfftMod,2);
    mModSpec = fft(abs(mSpec) * mModWin,nfftMod,2);

    % periodogram
    mModPSD = mModSpec .* conj(mModSpec);

    % scale the mod. spec. to a density, compensate for the window energy and
    % consider the singel sided spectrum
    mModPSD            = mModPSD / (diag(mModWin)'*diag(mModWin)) / fsMod;
    mModPSD            = mModPSD(:,1:end/2+1);
    mModPSD(:,2:end-1) = 2*mModPSD(:,2:end-1);

    ha(1) = subplot(211);
    surf(vModFreq,vFreq,10*log10(abs(mModPSD)),'edgecolor','none');
    axis tight;
    clim = get(gca,'clim');
    set(gca,'clim',[clim(2)-60,clim(2)]);
    set(gca,'view',[0,90]);
    colorbar;
    box on;

    title({'Modulation Spectrogram based on STFT Method',...
        sprintf(['max. shown mod.-freq.: f_{mod,max} = %.1f Hz ',...
        '(fs/(2 * frameshift))'],fs/(2*hopsize))});
    xlabel('Modulation Frequency in Hz');
    ylabel('Center Frequency in Hz');

    if strcmpi(szPlotScaleMode,'log'),
        set(gca,'xscale','log');
        xlabel('Modulation Frequency in Hz (log)');
    end
    if strcmpi(szPlotScaleMode,'loglog'),
        set(gca,'xscale','log','yscale','log');
        xlabel('Modulation Frequency in Hz (log)');
        ylabel('Center Frequency in Hz (log)');
    end
    
    ha(2) = subplot(212);
    surf(vModFreq,vFreq,angle(mModSpec(:,1:end/2+1)),'edgecolor','none');
    axis tight;
    set(gca,'view',[0,90]);
    colorbar;
    box on;
    
    title('Modulation Phase Spectrum');
    xlabel('Modulation Frequency in Hz');
    ylabel('Center Frequency in Hz');
    
    if strcmpi(szPlotScaleMode,'log'),
        set(gca,'xscale','log');
        xlabel('Modulation Frequency in Hz (log)');
    end
    
    linkaxes(ha,'xy');
end





% End of file: ModulationSpectrogram.m
