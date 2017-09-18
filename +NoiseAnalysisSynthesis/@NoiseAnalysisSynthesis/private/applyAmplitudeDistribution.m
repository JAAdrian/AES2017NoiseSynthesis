function [] = applyAmplitudeDistribution(obj)
%APPLYAMPLITUDEDISTRIBUTION Shape the synthesis signal's amplitude distribution
% -------------------------------------------------------------------------
%
% Usage: [] = applyAmplitudeDistribution(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:09:01
%

import NoiseSynthesis.External.*

if obj.bApplyAmplitudeDistr
    showMsg(obj, 'Applying desired Amplitude Distribution');
    
    for iSignal = 1:obj.NumSensorSignals
        obj.SensorSignals(:, iSignal) = ...
            shapeAmplitudeDistr(obj, obj.SensorSignals(:, iSignal));
    end
end





% End of file: applyAmplitudeDistribution.m
