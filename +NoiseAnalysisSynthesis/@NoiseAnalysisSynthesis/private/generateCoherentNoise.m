function [] = generateCoherentNoise(obj)
%GENERATECOHERENTNOISE Generate noise signals with desired spatial coherence
% -------------------------------------------------------------------------
%
% Usage: [] = generateCoherentNoise(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:11:52
%

import NoiseSynthesis.external.*


showMsg(obj,'Synthesizing Sensor Signals');

% generate G incoherent noise signals
obj.SensorSignals = cellfun(...
    @(x) generateNoise(obj,obj.bApplyColoration),...
    cell(obj.NumSensorSignals,1),...
    'uni',false);

% apply modulations if desired
if obj.bApplyModulations
    applyModulations(obj);
end

% apply coherence by mixing
bComputePSD = false;
mCoherentSignals = mixSignals(obj, obj.SensorSignals, bComputePSD);

% transform into time domain
obj.SensorSignals = zeros(obj.DesiredSignalLenSamples, obj.NumSensorSignals);
for aaSignal = 1:obj.NumSensorSignals
    obj.mBands = squeeze(mCoherentSignals(aaSignal,:,:)).';
    obj.SensorSignals(:, aaSignal) = SynthesisFilterbank(obj);
end


% End of file: generateCoherentNoise.m
