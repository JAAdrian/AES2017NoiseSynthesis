function [] = soundsc(self,bStereo)
%SOUNDSC Audio playback of both analysis and synthesis signal with scaling
% -------------------------------------------------------------------------
% This class method overloads MATLAB's standard soundsc() function to
% provide an easy way to playback both analyzed and synthesized signals
% from the current object. Playback level is scaled to maximum amplitude
% without clipping.
% It wraps playAnalyzed(self) and playSynthesized(self).
%
% Usage: [] = soundsc(self)
%        [] = soundsc(self,bStereo)
%
%   Input:   ---------
%           self: Object of type NoiseSynthesis.NoiseAnalysisSynthesis
%           bStereo: Boolean whether to use multichannel playback [default: false]
%
%  Output:   ---------
%           none
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  02-Dec-2015 16:25:56
%


if nargin < 2 || isempty(bStereo),
    bStereo = false;
end

if ~isempty(self.AnalysisSignal),
    fprintf('*** Playing Analysis  Signal ***\n');
    playAnalyzed(self,0);
    pause(self.lenSignalPlotAudio/self.Fs + 0.5);
end
fprintf('*** Playing Synthesis Signal ***\n');
playSynthesized(self,0,bStereo);





% End of file: soundsc.m
