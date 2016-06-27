function [] = DeCrackleAnalysisSignal(self)
%DECLICKANALYSISSIGNAL DeCrackle analysis signal
% -------------------------------------------------------------------------
%
% Usage: [] = DeCrackleAnalysisSignal(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 19:53:04
%

import NoiseSynthesis.external.*

threshold = 90;

self.vBeforeDeCrackling = self.AnalysisSignal;
self.AnalysisSignal = DeCrackleNoise(self.AnalysisSignal, self.Fs, threshold);

self.AnalysisSignal = self.AnalysisSignal / std(self.AnalysisSignal) ...
    * std(self.vBeforeDeCrackling);


% End of file: DeCrackleAnalysisSignal.m
