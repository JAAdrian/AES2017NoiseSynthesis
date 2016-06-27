function [] = analyzeModulationDepth(self)
%ANALYZEMODULATIONDEPTH Compute analysis file's modulation depth in bands
% -------------------------------------------------------------------------
%
% Usage: [] = analyzeModulationDepth(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:06:56
%


self.ModelParameters.ModulationDepth = self.hModNormFun(self.mLevelCurves).';




% End of file: analyzeModulationDepth.m
