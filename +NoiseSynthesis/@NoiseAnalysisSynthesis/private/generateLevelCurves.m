function [] = generateLevelCurves(self)
%GENERATELEVELCURVES Generate level fluctuation curves for the synthesis
% -------------------------------------------------------------------------
%
% Usage: [] = generateLevelCurves(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:16:23
%


if self.bVerbose,
    rng(1);
else
    rng('shuffle');
end

if self.ModelParameters.bUseMarkovChains,
    generateMarkovBands(self);
else
    generateGaussBands(self);
end


% End of file: generateLevelCurves.m
