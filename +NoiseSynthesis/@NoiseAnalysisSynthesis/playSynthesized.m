function [] = playSynthesized(self,leveldB,bStereo)
%PLAYSYNTHESIZED Audio playback of the synthesized signal
% -------------------------------------------------------------------------
% This class method chooses, depending on the platform, the right playback
% function and plays back the synthesis signal at the desired level. If
% bStereo == true the function plays the first two channels. If false it
% plays the first channel.
%
% Usage: [] = playSynthesized(self)
%        [] = playSynthesized(self,leveldB)
%        [] = playSynthesized(self,leveldB,bStereo)
%
%   Input:   ---------
%           self: Object of type NoiseSynthesis.NoiseAnalysisSynthesis
%           leveldB: Playback level in dBFS [default: self.soundLeveldB]
%           bStereo: Boolean whether to use multichannel playback [default: false]
%
%  Output:   ---------
%           none
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  02-Dec-2015 16:27:12
%

import NoiseSynthesis.external.*


if nargin < 3 || isempty(leveldB),
    bStereo = false;
end
if nargin < 2 || isempty(leveldB),
    leveldB = self.soundLeveldB;
end

hPlayFun       = @sound;
hPlayFunScaled = @soundsc;
if isunix,
    hPlayFun       = @usound;
    hPlayFunScaled = @usoundsc;
end

scaleFactor = 10^(leveldB/20) / rms(self.SensorSignals(:, 1));

if bStereo,
    vSignal = [self.SensorSignals(:, 1), self.SensorSignals(:, 2)];
else
    vSignal =  self.SensorSignals(:, 1);
end

if ~leveldB,
    hPlayFunScaled(vSignal, self.Fs);
else
    hPlayFun(scaleFactor*vSignal, self.Fs);
end





% End of file: playSynthesized.m
