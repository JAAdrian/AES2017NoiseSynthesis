function [] = generateMarkovBands(obj)
%GENERATEMARKOVBANDS Generate level fluctuations using Markov chain
% -------------------------------------------------------------------------
%
% Usage: [] = generateMarkovBands(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:19:46
%


for aaBand = 1:obj.numBands,
    obj.mArtificialLevelCurves(:,aaBand) = genmarkov(obj,aaBand);
end



% End of file: generateMarkovBands.m
