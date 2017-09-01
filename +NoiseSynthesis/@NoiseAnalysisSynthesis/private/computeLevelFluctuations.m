function [] = computeLevelFluctuations(obj)
%COMPUTELEVELFLUCTUATIONS <purpose in one line!>
% -------------------------------------------------------------------------
%
% Usage: [] = computeLevelFluctuations(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:02:30
%

import NoiseSynthesis.external.*


modFrameShift = obj.ModulationParams.Frameshift;

numBlocksPadded = obj.lenLevelCurve * modFrameShift + obj.ModulationParams.Overlap;

remBlocks = numBlocksPadded - obj.numBlocks;

vIdxNormalize = ...
    round(0.05 * obj.numBlocks) : ...
    round(0.95 * obj.numBlocks);

obj.mLevelCurves = zeros(obj.lenLevelCurve,obj.numBands);
for aaBand = 1:obj.numBands
    vCurrBandSignal = obj.mBands(aaBand,:).';
    vCurrBandSignal = vCurrBandSignal / ...
        rmsvec(vCurrBandSignal(vIdxNormalize));
    
    vCurrBandSignal = [...
        vCurrBandSignal; ...
        vCurrBandSignal(end-remBlocks+1:end)...
        ]; %#ok<AGROW>
    
    vIdxBlock = 1:obj.ModulationParams.Blocklen;
    for bbBlock = 1:obj.lenLevelCurve
        % get RMS
        obj.mLevelCurves(bbBlock,aaBand) = rmsvec(vCurrBandSignal(vIdxBlock));
        
        % update block index
        vIdxBlock = vIdxBlock + modFrameShift;
    end
end



% End of file: computeLevelFluctuations.m
