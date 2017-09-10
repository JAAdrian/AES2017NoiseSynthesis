function [] = analyzeModulationDepth(obj)
%ANALYZEMODULATIONDEPTH Compute analysis file's modulation depth in bands
% -------------------------------------------------------------------------
%
% Usage: [] = analyzeModulationDepth(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:06:56
%


obj.ModelParameters.ModulationDepth = obj.ModNormFun(obj.mLevelCurves).';




% End of file: analyzeModulationDepth.m
