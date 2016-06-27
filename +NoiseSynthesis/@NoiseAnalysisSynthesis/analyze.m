function [] = analyze(self)
%ANALYZE Estimate signal properties from the desired analysis signal
% -------------------------------------------------------------------------
% This class method estimates the following three signal properties:
%   - amplitude distribution in time domain
%   - long term spectrum in freq. domain
%   - modulations in freq. domain
%
% Usage: [] = analyze(self)
%
%   Input:   ---------
%           self: Object of type NoiseSynthesis.NoiseAnalysisSynthesis
%
%  Output:   ---------
%           none
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  02-Dec-2015 16:22:02
%

import NoiseSynthesis.external.*

% make sure to use the desired parameters for the modulations
updateModulationParameters(self);

% declick the analysis signal if desired
if self.bDeClick,
    showMsg(self,'DeClicking Analysis Signal');
    DeClickAnalysisSignal(self);
end

% HP filter if desired (true by default)
if self.bHPFilterAnalysis,
    [b,a] = butter(2,self.CutOffHP*2/self.Fs,'high');
    self.AnalysisSignal = filter(b,a,self.AnalysisSignal);
end

% estimate the amplitude distribution
showMsg(self,'Analyzing Amplitude Distribution');
analyzeAmplitudeDistribution(self);

showMsg(self,'DeCrackling Analysis Signal')
DeCrackleAnalysisSignal(self);

% transform into STFT domain
showMsg(self,'Transforming into STFT Domain');
AnalysisFilterbank(self,self.AnalysisSignal);

% estimate coloration
showMsg(self,'Analyzing Coloration');
analyzeMeanBandPower(self);

% estimate modulations
showMsg(self,'Analyzing Modulations');
analyzeModulations(self);






% End of file: analyze.m
