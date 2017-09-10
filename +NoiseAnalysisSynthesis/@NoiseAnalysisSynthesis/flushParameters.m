function [] = flushParameters(obj)
%FLUSHPARAMETERS Flush current parameter set
% -------------------------------------------------------------------------
% This class method flushes all parameters for the noise model and resets
% to default values.
%
% Usage: [] = flushParameters(obj)
%
%   Input:   ---------
%           obj: Object of type NoiseSynthesis.NoiseAnalysisSynthesis
%
%  Output:   ---------
%           none
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  02-Dec-2015 16:33:58
%

% overwrite the parameter object with a new default one
obj.ModelParameters = NoiseSynthesis.ModelParametersSet();

% update modulation and Markov parameters
updateModulationParameters(obj);
updateMarkovParams(obj, -12, 12);

% arbitrary default angles
obj.mTheta = pi/2 * ones(obj.NumSensorSignals);

obj.DoAnalysis = true;




% End of file: flushParameters.m
