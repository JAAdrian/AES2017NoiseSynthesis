function [] = normalizeBands(self)
%NORMALIZEBANDS Apply modulation depth
% -------------------------------------------------------------------------
%
% Usage: [] = normalizeBands(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:17:21
%


% centralize
self.mArtificialLevelCurves = bsxfun(@minus,...
    self.mArtificialLevelCurves,...
    median(self.mArtificialLevelCurves,1));

% apply unit modulation depth
self.mArtificialLevelCurves = bsxfun(@rdivide,self.mArtificialLevelCurves,...
    self.hModNormFun(self.mArtificialLevelCurves));

% apply pseudo modulation Depth
self.mArtificialLevelCurves = ...
    bsxfun(@times,self.mArtificialLevelCurves,self.ModelParameters.ModulationDepth.');

% apply mean
self.mArtificialLevelCurves = self.mArtificialLevelCurves + 1;

% make sure the level fluctuation is non-negative
vIdxOutOfRange = ...
    find(self.mArtificialLevelCurves < 10^(self.ModelParameters.MarkovStateBoundaries(1)/20));
self.mArtificialLevelCurves(vIdxOutOfRange) = ...
    abs(self.mArtificialLevelCurves(vIdxOutOfRange)) + 1;



% End of file: normalizeBands.m
