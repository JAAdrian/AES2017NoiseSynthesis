function [] = decorrelateLevelFluctuations(self)
%DECORRELATELEVELFLUCTUATIONS Decorrelate modulation curves for modulation analysis
% -------------------------------------------------------------------------
%
% Usage: [] = decorrelateLevelFluctuations(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:06:18
%

import NoiseSynthesis.external.*

% compute nonparametric location parameter -> median
vMedians = median(self.mLevelCurves,1);

% get the mixing matrix based on the inter-band correlation
mMixingMatrix = computeBandMixingMatrix(self.ModelParameters.GammaBands);

% initialize the decorrelated bands
self.mLevelCurvesDecorr = self.mLevelCurves;

% zscore for equal energy
self.mLevelCurvesDecorr = bsxfun(@minus,self.mLevelCurvesDecorr,mean(self.mLevelCurvesDecorr,1));
self.mLevelCurvesDecorr = bsxfun(@rdivide,self.mLevelCurvesDecorr,std(self.mLevelCurvesDecorr,[],1));

% decorrelate using numberically robust pseudo-inverse of the mixing matrix
self.mLevelCurvesDecorr = (pinv(mMixingMatrix') * self.mLevelCurvesDecorr.').';

% normalize by the largest value over all values of the decorr. level 
% fluctuations
maxVal = max(max(abs(self.mLevelCurvesDecorr)));
self.mLevelCurvesDecorr = self.mLevelCurvesDecorr / maxVal;

%restore previous median
self.mLevelCurvesDecorr = bsxfun(@plus,...
    self.mLevelCurvesDecorr,vMedians - median(self.mLevelCurvesDecorr,1));

% set values smaller than the smallest Markov state and simply add 1
vIdxOutOfRange = ...
    find(self.mLevelCurvesDecorr < 10^(self.ModelParameters.MarkovStateBoundaries(1)/20));
self.mLevelCurvesDecorr(vIdxOutOfRange) = abs(self.mLevelCurvesDecorr(vIdxOutOfRange)) + 1;




% End of file: decorrelateLevelFluctuations.m
