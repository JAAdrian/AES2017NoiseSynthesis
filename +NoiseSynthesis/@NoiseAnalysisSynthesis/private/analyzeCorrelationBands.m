function [] = analyzeCorrelationBands(self)
%ANALYZECORRELATIONBANDS Analyze the inter-band correlaion, i.e. comodulations
% -------------------------------------------------------------------------
%
% Usage: [] = analyzeCorrelationBands(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:05:47
%

import NoiseSynthesis.external.*


self.ModelParameters.GammaBands = computeBandCorrelation(self.mLevelCurves);





% End of file: analyzeCorrelationBands.m
