function [] = DeClickAnalysisSignal(self)
%DECLICKANALYSISSIGNAL DeClick analysis signal and est. click parameters if desired
% -------------------------------------------------------------------------
%
% Usage: [] = DeClickAnalysisSignal(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 19:53:04
%

import NoiseSynthesis.external.*

threshDeClick = 0.15;

% save the raw analysis signal in private property and declick
% self.AnalysisSignal
self.vOriginalAnalysisSignal = self.AnalysisSignal;
[self.AnalysisSignal, vClickPositions] = ...
    DeClickNoise(self.AnalysisSignal,self.Fs,threshDeClick);

vClicks = self.AnalysisSignal - self.vOriginalAnalysisSignal;

if self.ModelParameters.bApplyClicks && any(vClicks) && self.bEstimateClickSpec,
    estimateClickBandwidth(self,vClicks);
end

self.ModelParameters.SNRclick  = SNR(self.AnalysisSignal,vClicks);

learnMarkovClickParams(self,vClickPositions);

showMsg(self, sprintf('Error signal energy of (Clicked-DeClicked): %g\n', ...
    norm(self.vOriginalAnalysisSignal - self.AnalysisSignal)^2));

end

function [SNR] = SNR(vSignal,vNoise)
energySignal = norm(vSignal);
energyNoise  = norm(vNoise);

SNR = 20*log10( energySignal / energyNoise);
end


% End of file: DeClickAnalysisSignal.m
