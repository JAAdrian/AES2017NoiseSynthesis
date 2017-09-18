function [] = playSynthesized(obj, leveldB, isStereo)
%PLAYSYNTHESIZED Audio playback of the synthesized signal
% -------------------------------------------------------------------------
% This class method chooses, depending on the platform, the right playback
% function and plays back the synthesis signal at the desired level. If
% bStereo == true the function plays the first two channels. If false it
% plays the first channel.
%
% Usage: [] = playSynthesized(obj)
%        [] = playSynthesized(obj, leveldB)
%        [] = playSynthesized(obj, leveldB, isStereo)
%
%   Input:   ---------
%           obj: Object of type NoiseSynthesis.NoiseAnalysisSynthesis
%           leveldB: Playback level in dBFS [default: obj.soundLeveldB]
%           isStereo: Boolean whether to use multichannel playback [default: false]
%
%  Output:   ---------
%           none
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  02-Dec-2015 16:27:12
%

import NoiseSynthesis.External.*


if nargin < 3 || isempty(leveldB)
    isStereo = false;
end
if nargin < 2 || isempty(leveldB)
    leveldB = obj.soundLeveldB;
end

hPlayFun       = @sound;
hPlayFunScaled = @soundsc;
if isunix()
    hPlayFun       = @usound;
    hPlayFunScaled = @usoundsc;
end

scaleFactor = 10^(leveldB/20) / rms(obj.SensorSignals(:, 1));

if isStereo
    vSignal = [obj.SensorSignals(:, 1), obj.SensorSignals(:, 2)];
else
    vSignal =  obj.SensorSignals(:, 1);
end

if ~leveldB
    hPlayFunScaled(vSignal, obj.Fs);
else
    hPlayFun(scaleFactor*vSignal, obj.Fs);
end





% End of file: playSynthesized.m
