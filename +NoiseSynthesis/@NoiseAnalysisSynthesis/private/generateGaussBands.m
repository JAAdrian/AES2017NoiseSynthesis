function [] = generateGaussBands(obj)
%GENERATEGAUSSBANDS Alternative to Markov chain, generate normally distr. level fluctuations
% -------------------------------------------------------------------------
%
% Usage: [] = generateGaussBands(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:19:24
%


obj.mArtificialLevelCurves = randn(obj.lenLevelCurve,obj.numBands);



% End of file: generateGaussBands.m
