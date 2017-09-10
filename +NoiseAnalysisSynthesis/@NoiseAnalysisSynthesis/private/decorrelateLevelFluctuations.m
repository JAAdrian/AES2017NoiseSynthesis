function [] = decorrelateLevelFluctuations(obj)
%DECORRELATELEVELFLUCTUATIONS Decorrelate modulation curves for modulation analysis
% -------------------------------------------------------------------------
%
% Usage: [] = decorrelateLevelFluctuations(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:06:18
%

import NoiseSynthesis.external.*

% compute nonparametric location parameter -> median
vMedians = median(obj.mLevelCurves, 1);

% get the mixing matrix based on the inter-band correlation
mMixingMatrix = computeBandMixingMatrix(obj.ModelParameters.GammaBands);

% initialize the decorrelated bands
obj.mLevelCurvesDecorr = obj.mLevelCurves;

% zscore for equal energy
obj.mLevelCurvesDecorr = bsxfun(@minus,obj.mLevelCurvesDecorr,mean(obj.mLevelCurvesDecorr,1));
obj.mLevelCurvesDecorr = bsxfun(@rdivide,obj.mLevelCurvesDecorr,std(obj.mLevelCurvesDecorr,[],1));

% decorrelate using numberically robust pseudo-inverse of the mixing matrix
obj.mLevelCurvesDecorr = (pinv(mMixingMatrix') * obj.mLevelCurvesDecorr.').';

% normalize by the largest value over all values of the decorr. level 
% fluctuations
maxVal = max(max(abs(obj.mLevelCurvesDecorr)));
obj.mLevelCurvesDecorr = obj.mLevelCurvesDecorr / maxVal;

%restore previous median
obj.mLevelCurvesDecorr = bsxfun(@plus,...
    obj.mLevelCurvesDecorr,vMedians - median(obj.mLevelCurvesDecorr,1));

% set values smaller than the smallest Markov state and simply add 1
vIdxOutOfRange = ...
    find(obj.mLevelCurvesDecorr < 10^(obj.ModelParameters.MarkovStateBoundaries(1)/20));
obj.mLevelCurvesDecorr(vIdxOutOfRange) = abs(obj.mLevelCurvesDecorr(vIdxOutOfRange)) + 1;




% End of file: decorrelateLevelFluctuations.m
