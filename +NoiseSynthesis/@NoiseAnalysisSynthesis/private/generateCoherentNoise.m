function [] = generateCoherentNoise(self)
%GENERATECOHERENTNOISE Generate noise signals with desired spatial coherence
% -------------------------------------------------------------------------
%
% Usage: [] = generateCoherentNoise(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:11:52
%

import NoiseSynthesis.external.*


showMsg(self,'Synthesizing Sensor Signals');

% generate G incoherent noise signals
self.SensorSignals = cellfun(...
    @(x) generateNoise(self,self.bApplyColoration),...
    cell(self.NumSensorSignals,1),...
    'uni',false);

% apply modulations if desired
if self.bApplyModulations,
    applyModulations(self);
end

% apply coherence by mixing
bComputePSD = false;
mCoherentSignals = mixSignals(self, self.SensorSignals, bComputePSD);

% transform into time domain
self.SensorSignals = zeros(self.DesiredSignalLenSamples, self.NumSensorSignals);
for aaSignal = 1:self.NumSensorSignals,
    self.mBands = squeeze(mCoherentSignals(aaSignal,:,:)).';
    self.SensorSignals(:, aaSignal) = SynthesisFilterbank(self);
end


% End of file: generateCoherentNoise.m
