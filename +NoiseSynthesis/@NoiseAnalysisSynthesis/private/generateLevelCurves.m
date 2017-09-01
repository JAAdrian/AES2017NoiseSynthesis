function [] = generateLevelCurves(obj)
%GENERATELEVELCURVES Generate level fluctuation curves for the synthesis
% -------------------------------------------------------------------------
%
% Usage: [] = generateLevelCurves(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:16:23
%


if obj.bVerbose
    rng(1);
else
    rng('shuffle');
end

if obj.ModelParameters.bUseMarkovChains
    generateMarkovBands(obj);
else
    generateGaussBands(obj);
end


% End of file: generateLevelCurves.m
