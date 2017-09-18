function [vTimeSignal] = ISTFT(mSTFT,Phase,vWindow,overlap,lenOriginal,bNoReal)
%ISTFT Inverse Short Time Fourier Transform
% -------------------------------------------------------------------------
% This function is the inverse operation of the STFT function.
%
% Usage: [vTimeSignal] = ISTFT(mSTFT)
%        [vTimeSignal] = ISTFT(mSTFT,Phase)
%        [vTimeSignal] = ISTFT(mSTFT,Phase,vWindow)
%        [vTimeSignal] = ISTFT(mSTFT,Phase,vWindow,overlap)
%        [vTimeSignal] = ISTFT(mSTFT,Phase,vWindow,overlap,lenOriginal)
%        [vTimeSignal] = ISTFT(mSTFT,Phase,vWindow,overlap,lenOriginal,bNoReal)
%
%   Input:   ---------
%           mSTFT: (DFTSize x numBlocks) Complex STFT matrix
%           Phase: Option for phase processing [default: Phase = []]
%                   - empty: Do not alter the phase
%                   - phase matrix (DFTSize x numBlocks): apply the phase matrix
%                   - string 'random': apply randomized phase
%           vWindow: Window function to be used in the WOLA step [default: sqrt(hann(DFTSize,'periodic'))]
%           overlap: Overlap to be used in the WOLA stop [default: 0.5]
%           lenOriginal: Desired length of the time signal. To be used to
%                        account for longer signals due to zero padding
%           bNoReal: Bool whether to apply the real() function on the ifft()
%                    output [default: false]
%
%  Output:   ---------
%           vTimeSignal: Resulting time signal vector
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  27-Mar-2015 16:00:09
%

if nargin < 6 || isempty(bNoReal),
    bNoReal = false;
end
if nargin < 5 || isempty(lenOriginal),
    lenOriginal = [];
end
if nargin < 4 || isempty(overlap),
    overlap = @(x) round(x * 0.5);
end
if nargin < 3 || isempty(vWindow),
    vWindow = @(x) sqrt(hann(x,'periodic'));
end
if nargin < 2 || isempty(Phase),
    Phase = [];
end
if nargin < 1 || isempty(mSTFT),
    help(mfilename);
    return;
end

if nargin == 2 && isobject(Phase),
    vWindow = Phase.Window;
    overlap = Phase.Overlap;
    
    if ~isempty(Phase.OriginalSignalLength),
        lenOriginal = Phase.OriginalSignalLength;
    end
    
    Phase = [];
end

% TODO take double side into account
% TODO take odd nffts into account

if isempty(Phase),
    mPhase = zeros(size(mSTFT));
elseif isnumeric(Phase),
    mPhase = Phase;
elseif ischar(Phase),
    switch lower(Phase),
        case 'random',
            mPhase = exp(1j * 2*pi*rand(size(mSTFT)));
            mPhase([1, end],:) = 0;
    end
end


mSTFT = mSTFT .* exp(1j * mPhase);
mSTFT = [mSTFT; conj(mSTFT(end-1:-1:2,:))];

if bNoReal,
    mTime = ifft(mSTFT);
else
    mTime = real(ifft(mSTFT));
end



if isa(overlap,'function_handle'),
    overlap = overlap(size(mSTFT,1));
end
if isa(vWindow,'function_handle'),
    vWindow = vWindow(size(mSTFT,1));
end


% source:
% http://www.dsprelated.com/freebooks/sasp/Constant_Overlap_Add_COLA_Cases.html
frameshift = size(mTime,1) - overlap;
normFactor = 1 / (norm(vWindow)^2 / frameshift); % denominator is so called COLA term
                                                 % (C)onstant (O)ver(l)ap (A)dd
                                                 % norm: we are dealing with
                                                 % two sqrt(vWindow) windows
                                                 % so we need sum(vWindow.^2)

if length(vWindow) == size(mTime,1), % do ordinary WOLA if blocklen == nfft
    vWindow = vWindow * normFactor;
    vTimeSignal = unbuffer(diag(sparse(vWindow)) * mTime, overlap, lenOriginal);
else % zero padding in the analysis -> do not use the synth window and do OLA as in fftfilt
    % the frameshift is the original frameshift. This way all padded
    % samples are summed with the next block(s)
    frameshift = length(vWindow) - overlap;
    overlap    = size(mTime,1) - frameshift;
    
    % this is still WRONG with a bias of ~2dB
    normFactor = 1 / (norm(vWindow)^2 / frameshift);
    
    vTimeSignal = unbuffer(mTime * normFactor, overlap, lenOriginal);
end


end

function [vUnbufferedSignal] = unbuffer(mBufferedSignal,overlap,lenOriginal)
%UNBUFFER   decomposes a via buffer.m windowed signal into a signal vector
% -------------------------------------------------------------------------
% Decomposition of a buffered signal matrix via WOLA.
%
% Usage: vUnbufferedSignal = unbuffer(mBufferedSignal,overlap,lenOriginal)
%
%   Input:   ---------
%           mBufferedSignal = buffered signal matrix
%                   overlap = {0.5 x size(mBufferedSignal,1)}
%                             amount of frame overlap in samples.
%                             Default equals 50% overlap
%               lenOriginal = {length(vUnbufferedSignal)}
%                             length of the original unbufferd signal which
%                             has been altered due to zero padding
%
%  Output:   ---------
%           vUnbufferedSignal = decomposed signal column vector
%
%
% Copyright (C) 2012 by Jens-Alrik Adrian
% Author :  Jens-Alrik Adrian <jens-alrik.adrian AT uni-oldenburg.de>
% Date   :  13-Jan-2012 23:38:32
% Updated:  07-Dec-2014 23:21:30    cleaned up the code (JA)
%


[blocklen, numBlocks] = size(mBufferedSignal);

if numBlocks < 2 || blocklen < 2,
    error('Usage only on matrices containing more than one row or column!');
end
if nargin < 2,  overlap = round(0.5*blocklen);   end
if nargin < 1,
    help(mfilename);
    return;
end

frameshift = blocklen - overlap;

vUnbufferedSignal = zeros(numBlocks*frameshift + overlap,1);

if nargin < 3 || isempty(lenOriginal),
    lenOriginal = length(vUnbufferedSignal);
end


vIdxBlock = 1:blocklen;
for aaFrame = 1:numBlocks,
    vUnbufferedSignal(vIdxBlock) = ...
        vUnbufferedSignal(vIdxBlock) + mBufferedSignal(:,aaFrame);

    vIdxBlock = vIdxBlock + frameshift;
end

vUnbufferedSignal = vUnbufferedSignal(1:lenOriginal);
end





% End of file: ISTFT.m
