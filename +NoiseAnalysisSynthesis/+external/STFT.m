function [varargout] = STFT(vSignal,vWindow,overlap,nfft,fs,szSpecType)
%STFT Compute Short Time Fourier Transform
% -------------------------------------------------------------------------
% <Detailed description of the function>
%
% Usage: [varargout] = STFT(vSignal)
%        [varargout] = STFT(vSignal,vWindow)
%        [varargout] = STFT(vSignal,vWindow,overlap)
%        [varargout] = STFT(vSignal,vWindow,overlap,nfft)
%        [varargout] = STFT(vSignal,vWindow,overlap,nfft,fs)
%        [varargout] = STFT(vSignal,vWindow,overlap,nfft,fs,szSpecType)
%        [varargout] = STFT(vSignal,ParameterObject)
%
%   Input:   ---------
%           vSignal: Signal vector
%           vWindow: Window function to be applied
%                    [default: hann(round(20e-3*fs),'periodic')]
%           overlap: Overlap to be used [default: 0.5]
%           nfft: DFT size to be used [default: pow2(nextpow2(length(vWindow)))]
%           fs: sampling rate in Hz [default: 2*pi]
%           szSpecType: 'single' or 'whole' for either single or double
%                       sided spectra [default: single]
%
%  Output:   ---------
%           none: STFT plots a spectrogram with the desired parameters
%           mSpectrogram: (nfft x numBlocks) Complex STFT matrix
%           vFreq: Frequency vector
%           vTime: Time vector
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  10-Dec-2014 15:08:45
%

if nargin < 6 || isempty(szSpecType) || strcmpi(szSpecType,'yaxis'),
    szSpecType = 'single';
end
if nargin < 5 || isempty(fs),
    fs = 2*pi;
end
if nargin < 2 || isempty(vWindow),
    if fs == 2*pi,
        vWindow = hann(512,'periodic');
    else
        vWindow = hann(round(20e-3 * fs),'periodic');
    end
end
if nargin < 4 || isempty(nfft),
    nfft = pow2(nextpow2(length(vWindow)));
end
if nargin < 3 || isempty(overlap),
    overlap = round(0.5 * length(vWindow));
end

if nargin == 2 && isobject(vWindow),
    Window  = vWindow.Window;
    overlap = vWindow.Overlap;
    nfft    = vWindow.NFFT;
    fs      = vWindow.Fs;
    
    vWindow = Window;
end




% assert that vectors come as column vectors
vSignal = vSignal(:);
vWindow = vWindow(:);

blocklen   = length(vWindow);
frameshift = blocklen - overlap;

numBlocks    = ceil((length(vSignal) - overlap)/frameshift);
lenPaddedSig = numBlocks * frameshift + overlap;

% index vectors for the columns and rows of the STFT
vIdxColumns = (0:numBlocks-1)*frameshift;
vIdxRows    = (1:blocklen)';

% pad zeros
vSignal = [vSignal; zeros(lenPaddedSig - length(vSignal),1)];

% divide the signal into blocks and transform into Fourier domain
mSpectrogram = ...
    vSignal(vIdxRows(:,ones(1,numBlocks)) + vIdxColumns(ones(blocklen,1),:));
mSpectrogram = fft(diag(sparse(vWindow)) * mSpectrogram, nfft, 1);

% time and frequency vector of the time frequency representation
vTime = (vIdxColumns + blocklen/2)' / fs;

vFreq = (0:nfft/2)' / nfft * fs;
if strcmpi(szSpecType,'whole'),
    vFreq = (0:nfft-1)' / nfft * fs;
end

% index of fs/2 depending on the fft length
iFShalf = (nfft + rem(nfft,2)) / 2 + ~rem(nfft,2);

% plot a spectrogram using PSDs if there are no output parameters, else
% return the single sided spectrum
if nargout,
    if strcmpi(szSpecType,'single'),
        mSpectrogram = mSpectrogram(1:iFShalf,:);
    end

    varargout = {mSpectrogram, vFreq, vTime};
else
    mPSD = (mSpectrogram .* conj(mSpectrogram)) / (vWindow'*vWindow) / fs;

    if strcmpi(szSpecType,'single'),
        mPSD          = mPSD(1:iFShalf,:);
        mPSD(2:end-1) = 2*mPSD(2:end-1);
    end

    surf(vTime,vFreq,10*log10(mPSD + eps^2),'edgecolor','none','AmbientStrength',0.5);
    lightangle(210, 45);
    
    axis([vTime(1),vTime(end),vFreq(1),vFreq(end)]);
    set(gca,'view',[0 90]);
    hc = colorbar;
    set(get(hc, 'Label'), 'String', 'Power Spectral Density in dB re. 1^2/Hz');
    box on;

    title('Spectrogram using the STFT method');
    xlabel('Time in sec');
    ylabel('Frequency in Hz');

    drawnow;
end



% End of file: <STFT.m>
