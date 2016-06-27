function [] = mixBands(self)
%MIXBANDS Apply Habets' method to apply correlation between freq. bands
% -------------------------------------------------------------------------
%%
% Usage: [] = mixBands(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:16:46
%

import NoiseSynthesis.external.*

mMixingMatrixBands = computeBandMixingMatrix(self.ModelParameters.GammaBands);

vMean = mean(self.mArtificialLevelCurves,1);
self.mArtificialLevelCurves = bsxfun(@minus,self.mArtificialLevelCurves,vMean);
% essential! let all curves have the same energy! Use the
% centralized RMS, ie. the standard deviation
self.mArtificialLevelCurves = bsxfun(@rdivide,self.mArtificialLevelCurves,std(self.mArtificialLevelCurves,1));
self.mArtificialLevelCurves = bsxfun(@plus,self.mArtificialLevelCurves,vMean);

self.mArtificialLevelCurves = (mMixingMatrixBands' * self.mArtificialLevelCurves.').';



% End of file: mixBands.m
