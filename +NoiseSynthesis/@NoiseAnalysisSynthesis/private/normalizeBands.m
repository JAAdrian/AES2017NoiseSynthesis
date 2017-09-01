function [] = normalizeBands(obj)
%NORMALIZEBANDS Apply modulation depth
% -------------------------------------------------------------------------
%
% Usage: [] = normalizeBands(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:17:21
%


% centralize
obj.mArtificialLevelCurves = bsxfun(@minus,...
    obj.mArtificialLevelCurves,...
    median(obj.mArtificialLevelCurves,1));

% apply unit modulation depth
obj.mArtificialLevelCurves = bsxfun(@rdivide,obj.mArtificialLevelCurves,...
    obj.hModNormFun(obj.mArtificialLevelCurves));

% apply pseudo modulation Depth
obj.mArtificialLevelCurves = ...
    bsxfun(@times,obj.mArtificialLevelCurves,obj.ModelParameters.ModulationDepth.');

% apply mean
obj.mArtificialLevelCurves = obj.mArtificialLevelCurves + 1;

% make sure the level fluctuation is non-negative
vIdxOutOfRange = ...
    find(obj.mArtificialLevelCurves < 10^(obj.ModelParameters.MarkovStateBoundaries(1)/20));
obj.mArtificialLevelCurves(vIdxOutOfRange) = ...
    abs(obj.mArtificialLevelCurves(vIdxOutOfRange)) + 1;



% End of file: normalizeBands.m
