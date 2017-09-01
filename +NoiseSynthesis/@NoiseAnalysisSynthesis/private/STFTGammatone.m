function [mTransform] = STFTGammatone(obj)
%STFTGAMMATONE Return transformation matrix for the Gammatone approximation
% -------------------------------------------------------------------------
% Source:
% S. van de Par, A. Kohlrausch, R. Heusdens, J. Jensen, and S. H. Jensen,
% “A perceptual model for sinusoidal audio coding based on spectral
% integration,” EURASIP Journal on Applied Signal Processing, vol. 2005,
% pp. 1292–1304, 2005.

%
% Usage: [mTransform] = STFTGammatone(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 19:58:34
%


erbCenterFreqs = obj.vCenterFreqs;
erbFreqs       = erb(erbCenterFreqs);

numChannels    = length(erbCenterFreqs);
gammatoneOrder = 4;

k = 2^(gammatoneOrder - 1) * factorial(gammatoneOrder-1) / ...
    (pi * doublefactorial(2*gammatoneOrder - 3));

freq = linspace(0, obj.SampleRate/2, obj.NumBins);

mTransform = zeros(numChannels, obj.NumBins);
for iChannel = 1:numChannels
    mTransform(iChannel,:) = ...
        (1 + (...
            (freq - erbCenterFreqs(iChannel)) ./ ...
            (k .* erbFreqs(iChannel)) ) .^2 ...
        ) .^ (-gammatoneOrder/2);
end
% 
% figure;
% semilogx(vFreq, 20*log10(mTransform + eps));
% axis tight;
% axis([obj.GammatoneLowestBand, obj.GammatoneHighestBand,...
%     -70, 0]);
end


function erbFreqs = erb(freq)
erbFreqs = 24.7 .* (4.37 * freq/1000 + 1);
end

function dpf = doublefactorial(in)
if iseven(in)
    dpf = prod(2:2:in);
else
    dpf = prod(1:2:in);
end
end


function istrue = iseven(in)
divideByTwo = mod(in, 2);

istrue = false(size(in));

istrue(divideByTwo == 0) = true;
end


% End of file: STFTGammatone.m
