function [vNoise] = generateNoise(obj, iNoiseMode)
%GENERATENOISE Generate a noise signal based on desired PSD
% -------------------------------------------------------------------------
%
% Usage: [vNoise] = generateNoise(obj,iNoiseMode)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:11:04
%


if nargin < 2 || isempty(iNoiseMode)
    iNoiseMode = 0;
end

mUniformPhaseNoise = 2*pi * rand(obj.numBins,obj.numBlocks) - pi;
mUniformPhaseNoise([1,end],:) = 0;

switch iNoiseMode
    case 0
        vNoise = exp(1j * mUniformPhaseNoise);
    case 1
        if iscell(obj.ModelParameters.MeanPSD)
            MeanPSD = freqz(...
                obj.ModelParameters.MeanPSD{1},...
                obj.ModelParameters.MeanPSD{2},...
                obj.STFTParameters.NFFT/2+1,...
                obj.Fs...
                );
            
            MeanPSD = abs(MeanPSD);
        else
            MeanPSD = obj.ModelParameters.MeanPSD;
        end
        
        vNoise = bsxfun(...
            @times,...
            sqrt(MeanPSD),...
            exp(1j * mUniformPhaseNoise));
end


% End of file: generateNoise.m
