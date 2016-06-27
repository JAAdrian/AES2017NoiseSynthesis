function [] = playAnalyzed(self,leveldB)
%PLAYANALYZED Audio playback of the analysis signal
% -------------------------------------------------------------------------
% This class method chooses, depending on the platform, the right playback
% function and plays back the analysis signal at the desired level.
%
% Usage: [] = playAnalyzed(self,leveldB)
%
%   Input:   ---------
%           self: Object of type NoiseSynthesis.NoiseAnalysisSynthesis
%           leveldB: Playback level in dBFS [default: self.soundLeveldB]
%
%  Output:   ---------
%           none
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  02-Dec-2015 16:26:37
%

import NoiseSynthesis.external.*


if nargin < 2 || isempty(leveldB),
    leveldB = self.soundLeveldB;
end

hPlayFun       = @sound;
hPlayFunScaled = @soundsc;
if isunix,
    hPlayFun       = @usound;
    hPlayFunScaled = @usoundsc;
end

if ~isempty(self.ClickTracks),
    vSignal = self.vOriginalAnalysisSignal;
else
    vSignal = self.AnalysisSignal;
end

scaleFactor = 10^(leveldB/20) / rms(vSignal);
if ~leveldB,
    hPlayFunScaled(vSignal, self.Fs);
else
    hPlayFun(scaleFactor * vSignal, self.Fs);
end







% End of file: playAnalyzed.m
