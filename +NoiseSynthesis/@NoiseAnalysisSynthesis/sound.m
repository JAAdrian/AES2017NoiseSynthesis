function [] = sound(obj,leveldB,bStereo)
%SOUND Audio playback of both analysis and synthesis signal without scaling
% -------------------------------------------------------------------------
% This class method overloads MATLAB's standard sound() function to provide
% an easy way to playback both analyzed and synthesized signals from the
% current object. Playback level is not scaled to maximum amplitude.
% It wraps playAnalyzed(obj) and playSynthesized(obj).
%
% Usage: [] = sound(obj)
%        [] = sound(obj,leveldB)
%        [] = sound(obj,leveldB,bStereo)
%
%   Input:   ---------
%           obj: Object of type NoiseSynthesis.NoiseAnalysisSynthesis
%           leveldB: Playback level in dBFS [default: obj.soundLeveldB]
%           bStereo: Boolean whether to use multichannel playback [default: false]
%
%  Output:   ---------
%           none
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  02-Dec-2015 16:25:26
%


if nargin < 3 || isempty(bStereo)
    bStereo = false;
end
if nargin < 2 || isempty(leveldB)
    leveldB = obj.soundLeveldB;
end

if ~isempty(obj.AnalysisSignal)
    fprintf('*** Playing Analysis  Signal ***\n');
    playAnalyzed(obj,leveldB);
    pause(obj.lenSignalPlotAudio/obj.Fs + 0.5);
end
fprintf('*** Playing Synthesis Signal ***\n');
playSynthesized(obj,leveldB,bStereo);





% End of file: sound.m
