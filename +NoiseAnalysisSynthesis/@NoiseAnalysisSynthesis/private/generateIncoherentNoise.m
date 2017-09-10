function [] = generateIncoherentNoise(obj)
%GENERATEINCOHERENTNOISE Generate noise signals without spatial coherence
% -------------------------------------------------------------------------
%
% Usage: [] = generateIncoherentNoise(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:12:22
%


obj.SensorSignals{1} = generateNoise(obj,obj.bApplyColoration);

% apply modulations if desired
if obj.bApplyModulations
    applyModulations(obj);
end

obj.mBands = obj.SensorSignals{1};
obj.SensorSignals = [];
obj.SensorSignals = SynthesisFilterbank(obj);


% End of file: generateIncoherentNoise.m
