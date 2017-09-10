function [] = updateMarkovParams(obj,minVal,maxVal)
%UPDATEMARKOVPARAMS Update the state boundaries for the modulation Markov model
% -------------------------------------------------------------------------
%
% Usage: [] = updateMarkovParams(obj,minVal,maxVal)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:04:27
%


obj.ModelParameters.maxMarkovRMSlevel = maxVal;

vCentralPart = -3:3;
vLowerPart   = [minVal, (minVal + vCentralPart(1))/2];
vUpperPart   = [(maxVal + vCentralPart(end))/2, maxVal];

obj.ModelParameters.MarkovStateBoundaries = [vLowerPart, vCentralPart, vUpperPart].';

obj.ModelParameters.MarkovStateBoundaries = [
    obj.ModelParameters.MarkovStateBoundaries(1:end-1),...
    obj.ModelParameters.MarkovStateBoundaries(2:end)
    ];




% End of file: updateMarkovParams.m
