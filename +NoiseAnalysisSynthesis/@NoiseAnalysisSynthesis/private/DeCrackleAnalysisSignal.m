function [] = DeCrackleAnalysisSignal(obj)
%DECLICKANALYSISSIGNAL DeCrackle analysis signal
% -------------------------------------------------------------------------
%
% Usage: [] = DeCrackleAnalysisSignal(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 19:53:04
%

import NoiseSynthesis.External.*

threshold = 90;

obj.BeforeDeCrackling = obj.AnalysisSignal;
obj.AnalysisSignal = DeCrackleNoise(...
    obj.AnalysisSignal, ...
    obj.SampleRate, ...
    threshold ...
    );

obj.AnalysisSignal = ...
    obj.AnalysisSignal / std(obj.AnalysisSignal) * std(obj.vBeforeDeCrackling);


% End of file: DeCrackleAnalysisSignal.m
