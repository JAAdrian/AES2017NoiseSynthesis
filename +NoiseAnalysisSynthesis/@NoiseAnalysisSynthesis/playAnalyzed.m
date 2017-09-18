function [] = playAnalyzed(obj, leveldB)
%PLAYANALYZED Audio playback of the analysis signal
% -------------------------------------------------------------------------
% This class method chooses, depending on the platform, the right playback
% function and plays back the analysis signal at the desired level.
%
% Usage: [] = playAnalyzed(obj, leveldB)
%
%   Input:   ---------
%           obj: Object of type NoiseSynthesis.NoiseAnalysisSynthesis
%           leveldB: Playback level in dBFS [default: obj.soundLeveldB]
%
%  Output:   ---------
%           none
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  02-Dec-2015 16:26:37
%

import NoiseSynthesis.External.*


if nargin < 2 || isempty(leveldB)
    leveldB = obj.soundLeveldB;
end

hPlayFun       = @sound;
hPlayFunScaled = @soundsc;
if isunix()
    hPlayFun       = @usound;
    hPlayFunScaled = @usoundsc;
end

signal = obj.OriginalAnalysisSignal;

scaleFactor = 10^(leveldB/20) / rms(signal);
if ~leveldB
    hPlayFunScaled(signal, obj.SampleRate);
else
    hPlayFun(scaleFactor * signal, obj.SampleRate);
end







% End of file: playAnalyzed.m
