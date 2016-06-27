function [] = generateGaussBands(self)
%GENERATEGAUSSBANDS Alternative to Markov chain, generate normally distr. level fluctuations
% -------------------------------------------------------------------------
%
% Usage: [] = generateGaussBands(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:19:24
%


self.mArtificialLevelCurves = randn(self.lenLevelCurve,self.numBands);



% End of file: generateGaussBands.m
