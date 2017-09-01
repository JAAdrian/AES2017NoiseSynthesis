function [] = soundsc(obj,bStereo)
%SOUNDSC Audio playback of both analysis and synthesis signal with scaling
% -------------------------------------------------------------------------
% This class method overloads MATLAB's standard soundsc() function to
% provide an easy way to playback both analyzed and synthesized signals
% from the current object. Playback level is scaled to maximum amplitude
% without clipping.
% It wraps playAnalyzed(obj) and playSynthesized(obj).
%
% Usage: [] = soundsc(obj)
%        [] = soundsc(obj,bStereo)
%
%   Input:   ---------
%           obj: Object of type NoiseSynthesis.NoiseAnalysisSynthesis
%           bStereo: Boolean whether to use multichannel playback [default: false]
%
%  Output:   ---------
%           none
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  02-Dec-2015 16:25:56
%


if nargin < 2 || isempty(bStereo)
    bStereo = false;
end

if ~isempty(obj.AnalysisSignal)
    fprintf('*** Playing Analysis  Signal ***\n');
    playAnalyzed(obj,0);
    pause(obj.lenSignalPlotAudio/obj.Fs + 0.5);
end
fprintf('*** Playing Synthesis Signal ***\n');
playSynthesized(obj,0,bStereo);





% End of file: soundsc.m
