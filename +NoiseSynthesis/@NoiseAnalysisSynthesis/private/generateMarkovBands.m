function [] = generateMarkovBands(self)
%GENERATEMARKOVBANDS Generate level fluctuations using Markov chain
% -------------------------------------------------------------------------
%
% Usage: [] = generateMarkovBands(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:19:46
%


for aaBand = 1:self.numBands,
    self.mArtificialLevelCurves(:,aaBand) = genmarkov(self,aaBand);
end



% End of file: generateMarkovBands.m
