function [] = mixBands(obj)
%MIXBANDS Apply Habets' method to apply correlation between freq. bands
% -------------------------------------------------------------------------
%%
% Usage: [] = mixBands(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:16:46
%

import NoiseSynthesis.External.*

mMixingMatrixBands = computeBandMixingMatrix(obj.ModelParameters.GammaBands);

vMean = mean(obj.mArtificialLevelCurves,1);
obj.mArtificialLevelCurves = bsxfun(@minus,obj.mArtificialLevelCurves,vMean);
% essential! let all curves have the same energy! Use the
% centralized RMS, ie. the standard deviation
obj.mArtificialLevelCurves = bsxfun(@rdivide,obj.mArtificialLevelCurves,std(obj.mArtificialLevelCurves,1));
obj.mArtificialLevelCurves = bsxfun(@plus,obj.mArtificialLevelCurves,vMean);

obj.mArtificialLevelCurves = (mMixingMatrixBands' * obj.mArtificialLevelCurves.').';



% End of file: mixBands.m
