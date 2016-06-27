function [mFreqNoiseMix] = mixSignals(self,caSTFTNoise,bComputePSD)
%MIXSIGNALS Instantaneous mixing of sensor signals to introduce correlation
% -------------------------------------------------------------------------
%
% Usage: [mFreqNoiseMix] = mixSignals(self,caSTFTNoise,bComputePSD)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:15:54
%


computeSensorDistances(self);

mSourcePSD = [];
if strcmp(self.ModelParameters.CohereModel,'anisotropic'),
    computeTheta(self);
    
    if bComputePSD,
        mSourcePSD = zeros(self.numBins,min(self.NumSources,self.NumSensorSignals));
        for aaSource = 1:min(self.NumSources,self.NumSensorSignals),
            mSourcePSD(:,aaSource) = mean(abs(caSTFTNoise{aaSource}).^2,2);
        end
    end
end

mSTFTNoise = zeros(self.NumSensorSignals,self.numBlocks,self.numBins);
for aaSignal = 1:self.NumSensorSignals,
    % if at least one of the click tracks does not contain one single
    % click, do nothing and return
    if all(caSTFTNoise{aaSignal}(:) == 0),
        mFreqNoiseMix = mSTFTNoise;
        return;
    end
    
    mSTFTNoise(aaSignal,:,:) = caSTFTNoise{aaSignal}.';
end



vFreq = linspace(0,self.Fs/2,self.numBins);

mFreqNoiseMix = zeros(size(mSTFTNoise));
for aaBin = 1:self.numBins,
    SourcePSDbin = [1 1];
    if ~isempty(mSourcePSD),
        SourcePSDbin = mSourcePSD(aaBin,:);
    end
    
    mMixingMatrix = computeMixingMatrix(self,vFreq(aaBin),SourcePSDbin);
    
    mFreqNoiseMix(:,:,aaBin) = ...
        mMixingMatrix' * mSTFTNoise(:,:,aaBin);
end



% End of file: mixSignals.m
