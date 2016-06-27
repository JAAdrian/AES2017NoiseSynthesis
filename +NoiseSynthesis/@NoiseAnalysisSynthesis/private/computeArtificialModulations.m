function [] = computeArtificialModulations(self)
%COMPUTEARTIFICIALMODULATIONS Generate level fluctuation curves from Markov model
% -------------------------------------------------------------------------
%
% Usage: [] = computeArtificialModulations(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:08:12
%


generateLevelCurves(self);

if self.bApplyComodulation,
    mixBands(self);
end

normalizeBands(self);



% End of file: computeArtificialModulations.m
