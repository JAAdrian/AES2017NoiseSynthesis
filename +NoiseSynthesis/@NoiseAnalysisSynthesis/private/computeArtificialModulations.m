function [] = computeArtificialModulations(obj)
%COMPUTEARTIFICIALMODULATIONS Generate level fluctuation curves from Markov model
% -------------------------------------------------------------------------
%
% Usage: [] = computeArtificialModulations(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:08:12
%


generateLevelCurves(obj);

if obj.bApplyComodulation
    mixBands(obj);
end

normalizeBands(obj);



% End of file: computeArtificialModulations.m
