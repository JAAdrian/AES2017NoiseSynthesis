function [vNoise] = generateNoise(self,iNoiseMode)
%GENERATENOISE Generate a noise signal based on desired PSD
% -------------------------------------------------------------------------
%
% Usage: [vNoise] = generateNoise(self,iNoiseMode)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:11:04
%


if nargin < 2 || isempty(iNoiseMode),
    iNoiseMode = 0;
end

mUniformPhaseNoise = 2*pi * rand(self.numBins,self.numBlocks) - pi;
mUniformPhaseNoise([1,end],:) = 0;

switch iNoiseMode,
    case 0,
        vNoise = exp(1j * mUniformPhaseNoise);
    case 1,
        if iscell(self.ModelParameters.MeanPSD),
            MeanPSD = freqz(...
                self.ModelParameters.MeanPSD{1},...
                self.ModelParameters.MeanPSD{2},...
                self.STFTParameters.NFFT/2+1,...
                self.Fs...
                );
            
            MeanPSD = abs(MeanPSD);
        else
            MeanPSD = self.ModelParameters.MeanPSD;
        end
        
        vNoise = bsxfun(...
            @times,...
            sqrt(MeanPSD),...
            exp(1j * mUniformPhaseNoise));
end


% End of file: generateNoise.m
