function [mTransform] = STFTGammatone(self)
%STFTGAMMATONE Return transformation matrix for the Gammatone approximation
% -------------------------------------------------------------------------
% Source:
% S. van de Par, A. Kohlrausch, R. Heusdens, J. Jensen, and S. H. Jensen,
% “A perceptual model for sinusoidal audio coding based on spectral
% integration,” EURASIP Journal on Applied Signal Processing, vol. 2005,
% pp. 1292–1304, 2005.

%
% Usage: [mTransform] = STFTGammatone(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 19:58:34
%


vERBCenterFreqs = self.vCenterFreqs;
vERB            = ERB(vERBCenterFreqs);

numChannels    = length(vERBCenterFreqs);
gammatoneOrder = 4;

k = 2^(gammatoneOrder - 1) * factorial(gammatoneOrder-1) / ...
    (pi * doublefactorial(2*gammatoneOrder - 3));

vFreq = linspace(0,self.Fs/2,self.numBins);

mTransform = zeros(numChannels,self.numBins);
for aaChannel = 1:numChannels,
    mTransform(aaChannel,:) = ...
        (1 + (...
        (vFreq - vERBCenterFreqs(aaChannel)) ./ ...
        (k .* vERB(aaChannel)) ) .^2 ...
        ) .^ (-gammatoneOrder/2);
end

%         figure;
%         semilogx(vFreq, 20*log10(mTransform + eps));
%         axis tight;
%         axis([self.GammatoneLowestBand, self.GammatoneHighestBand,...
%             -70, 0]);


    function dpf = doublefactorial(in)
        if iseven(in),
            dpf = prod(2:2:in);
        else
            dpf = prod(1:2:in);
        end
    end


    function istrue = iseven(in)
        divideByTwo = mod(in,2);
        
        istrue = false(size(in));
        
        istrue(divideByTwo == 0) = true;
    end

end


function vERB = ERB(vFreq)
vERB = 24.7 .* (4.37 * vFreq/1000 + 1);
end


% End of file: STFTGammatone.m
