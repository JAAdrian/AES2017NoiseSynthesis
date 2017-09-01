function [] = DeClickAnalysisSignal(obj)
%DECLICKANALYSISSIGNAL DeClick analysis signal and est. click parameters if desired
% -------------------------------------------------------------------------
%
% Usage: [] = DeClickAnalysisSignal(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 19:53:04
%

import NoiseSynthesis.external.*

threshDeClick = 0.15;

% save the raw analysis signal in private property and declick
% obj.AnalysisSignal
obj.vOriginalAnalysisSignal = obj.AnalysisSignal;
[obj.AnalysisSignal, vClickPositions] = ...
    DeClickNoise(obj.AnalysisSignal,obj.Fs,threshDeClick);

vClicks = obj.AnalysisSignal - obj.vOriginalAnalysisSignal;

if obj.ModelParameters.bApplyClicks && any(vClicks) && obj.bEstimateClickSpec,
    estimateClickBandwidth(obj,vClicks);
end

obj.ModelParameters.SNRclick  = SNR(obj.AnalysisSignal,vClicks);

learnMarkovClickParams(obj,vClickPositions);

showMsg(obj, sprintf('Error signal energy of (Clicked-DeClicked): %g\n', ...
    norm(obj.vOriginalAnalysisSignal - obj.AnalysisSignal)^2));

end

function [SNR] = SNR(vSignal,vNoise)
energySignal = norm(vSignal);
energyNoise  = norm(vNoise);

SNR = 20*log10( energySignal / energyNoise);
end


% End of file: DeClickAnalysisSignal.m
