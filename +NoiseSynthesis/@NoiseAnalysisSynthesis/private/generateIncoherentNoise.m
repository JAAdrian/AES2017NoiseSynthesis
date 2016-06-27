function [] = generateIncoherentNoise(self)
%GENERATEINCOHERENTNOISE Generate noise signals without spatial coherence
% -------------------------------------------------------------------------
%
% Usage: [] = generateIncoherentNoise(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:12:22
%


self.SensorSignals{1} = generateNoise(self,self.bApplyColoration);

% apply modulations if desired
if self.bApplyModulations,
    applyModulations(self);
end

self.mBands = self.SensorSignals{1};
self.SensorSignals = [];
self.SensorSignals = SynthesisFilterbank(self);


% End of file: generateIncoherentNoise.m
