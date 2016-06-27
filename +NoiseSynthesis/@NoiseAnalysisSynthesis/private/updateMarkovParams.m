function [] = updateMarkovParams(self,minVal,maxVal)
%UPDATEMARKOVPARAMS Update the state boundaries for the modulation Markov model
% -------------------------------------------------------------------------
%
% Usage: [] = updateMarkovParams(self,minVal,maxVal)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:04:27
%


self.ModelParameters.maxMarkovRMSlevel = maxVal;

vCentralPart = -3:3;
vLowerPart   = [minVal, (minVal + vCentralPart(1))/2];
vUpperPart   = [(maxVal + vCentralPart(end))/2, maxVal];

self.ModelParameters.MarkovStateBoundaries = [vLowerPart, vCentralPart, vUpperPart].';

self.ModelParameters.MarkovStateBoundaries = [
    self.ModelParameters.MarkovStateBoundaries(1:end-1),...
    self.ModelParameters.MarkovStateBoundaries(2:end)
    ];




% End of file: updateMarkovParams.m
