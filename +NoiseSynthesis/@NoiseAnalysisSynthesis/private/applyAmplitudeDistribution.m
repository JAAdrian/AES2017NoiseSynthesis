function [] = applyAmplitudeDistribution(self)
%APPLYAMPLITUDEDISTRIBUTION Shape the synthesis signal's amplitude distribution
% -------------------------------------------------------------------------
%
% Usage: [] = applyAmplitudeDistribution(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:09:01
%

import NoiseSynthesis.external.*

if self.bApplyAmplitudeDistr,
    showMsg(self,'Applying desired Amplitude Distribution');
    
    for iSignal = 1:self.NumSensorSignals,
        self.SensorSignals(:, iSignal) = ...
            shapeAmplitudeDistr(self, self.SensorSignals(:, iSignal));
    end
end





% End of file: applyAmplitudeDistribution.m
