function [mFreqNoiseMix] = mixSignals(obj,caSTFTNoise,bComputePSD)
%MIXSIGNALS Instantaneous mixing of sensor signals to introduce correlation
% -------------------------------------------------------------------------
%
% Usage: [mFreqNoiseMix] = mixSignals(obj,caSTFTNoise,bComputePSD)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:15:54
%


computeSensorDistances(obj);

mSourcePSD = [];
if strcmp(obj.ModelParameters.CohereModel,'anisotropic')
    computeTheta(obj);
    
    if bComputePSD
        mSourcePSD = zeros(obj.numBins,min(obj.NumSources,obj.NumSensorSignals));
        for aaSource = 1:min(obj.NumSources,obj.NumSensorSignals)
            mSourcePSD(:,aaSource) = mean(abs(caSTFTNoise{aaSource}).^2,2);
        end
    end
end

mSTFTNoise = zeros(obj.NumSensorSignals,obj.numBlocks,obj.numBins);
for aaSignal = 1:obj.NumSensorSignals
    % if at least one of the click tracks does not contain one single
    % click, do nothing and return
    if all(caSTFTNoise{aaSignal}(:) == 0)
        mFreqNoiseMix = mSTFTNoise;
        return;
    end
    
    mSTFTNoise(aaSignal,:,:) = caSTFTNoise{aaSignal}.';
end



vFreq = linspace(0,obj.Fs/2,obj.numBins);

mFreqNoiseMix = zeros(size(mSTFTNoise));
for aaBin = 1:obj.numBins
    SourcePSDbin = [1 1];
    if ~isempty(mSourcePSD)
        SourcePSDbin = mSourcePSD(aaBin,:);
    end
    
    mMixingMatrix = computeMixingMatrix(obj,vFreq(aaBin),SourcePSDbin);
    
    mFreqNoiseMix(:,:,aaBin) = ...
        mMixingMatrix' * mSTFTNoise(:,:,aaBin);
end



% End of file: mixSignals.m
