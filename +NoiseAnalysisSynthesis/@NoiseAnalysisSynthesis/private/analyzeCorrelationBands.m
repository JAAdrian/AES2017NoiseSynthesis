function [] = analyzeCorrelationBands(obj)
%ANALYZECORRELATIONBANDS Analyze the inter-band correlaion, i.e. comodulations
% -------------------------------------------------------------------------
%
% Usage: [] = analyzeCorrelationBands(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:05:47
%

import NoiseSynthesis.External.*


obj.ModelParameters.GammaBands = computeBandCorrelation(obj.mLevelCurves);





% End of file: analyzeCorrelationBands.m
