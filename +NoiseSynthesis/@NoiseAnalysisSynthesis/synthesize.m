function [SensorSignalsOut] = synthesize(obj)
%SYNTHESIZE Synthesize a noise signal from desired parameters
% -------------------------------------------------------------------------
% This class method generates (single or multichannel) noise signals with
% desired length and parameters.
%
% Usage: [] = synthesize(obj)
%        [SensorSignalsOut] = synthesize(obj)
%
%   Input:   ---------
%           obj: Object of type NoiseSynthesis.NoiseAnalysisSynthesis
%
%  Output:   ---------
%           SensorSignalsOut: cell array containing a sensor signal in each
%                             cell. If no output parameter is desired the
%                             generated sensor signals are still accessible
%                             as an object property.
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  02-Dec-2015 16:22:42
%

import NoiseSynthesis.external.*


if ...
        isempty(obj.ModelParameters.MarkovTransition) && ...
        isempty(obj.ModelParameters.MarkovStateBoundaries) && ...
        isempty(obj.ModelParameters.MeanPSD) && ...
        isempty(obj.ModelParameters.Quantiles) && ...
        isempty(obj.ModelParameters.CDF)
    
    error(['The model parameters seem to be unset (flushed?)! ',...
        'Make sure to provide parameters either by analyzing, ',...
        'loading a model or reading a parameter file.']);
end

% make sure to use the desired parameters for the modulations
updateModulationParameters(obj);

% shuffle the random generator by default. If in verbose mode reset the
% generator
if obj.Verbose
    rng(1);
else
    rng('shuffle');
end

% if a spatial coherence should be applied, generate M incoherent
% Gaussian noise signals in STFT domain and introduce coherence by
% instantaneous mixing, else generate one Gaussian in STFT domain.
% In both cases, apply coloration if desired
if obj.bApplySpatialCoherence
    showMsg(obj,'Applying Spatial Coherence');
    
    generateCoherentNoise(obj);
    
    if obj.ModelParameters.bApplyClicks
        generateCoherentClicks(obj);
    end
else
    generateIncoherentNoise(obj);
    
    if obj.ModelParameters.bApplyClicks
        generateIncoherentClicks(obj);
    end
end

% apply amplitude distribution if desired
applyAmplitudeDistribution(obj);

% mix noise and clicks if desired
mixNoiseAndClicks(obj);

if nargout
    SensorSignalsOut = obj.SensorSignals;
end






% End of file: synthesize.m
