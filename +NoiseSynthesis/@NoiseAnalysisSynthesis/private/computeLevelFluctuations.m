function [] = computeLevelFluctuations(self)
%COMPUTELEVELFLUCTUATIONS <purpose in one line!>
% -------------------------------------------------------------------------
%
% Usage: [] = computeLevelFluctuations(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:02:30
%

import NoiseSynthesis.external.*


modFrameShift = self.ModulationParams.Frameshift;

numBlocksPadded = self.lenLevelCurve * modFrameShift + self.ModulationParams.Overlap;

remBlocks = numBlocksPadded - self.numBlocks;

vIdxNormalize = ...
    round(0.05 * self.numBlocks) : ...
    round(0.95 * self.numBlocks);

self.mLevelCurves = zeros(self.lenLevelCurve,self.numBands);
for aaBand = 1:self.numBands,
    vCurrBandSignal = self.mBands(aaBand,:).';
    vCurrBandSignal = vCurrBandSignal / ...
        rmsvec(vCurrBandSignal(vIdxNormalize));
    
    vCurrBandSignal = [...
        vCurrBandSignal; ...
        vCurrBandSignal(end-remBlocks+1:end)...
        ]; %#ok<AGROW>
    
    vIdxBlock = 1:self.ModulationParams.Blocklen;
    for bbBlock = 1:self.lenLevelCurve,
        % get RMS
        self.mLevelCurves(bbBlock,aaBand) = rmsvec(vCurrBandSignal(vIdxBlock));
        
        % update block index
        vIdxBlock = vIdxBlock + modFrameShift;
    end
end



% End of file: computeLevelFluctuations.m
