function [] = analyze(obj)
%ANALYZE Estimate signal properties from the desired analysis signal
% -------------------------------------------------------------------------
% This class method estimates the following three signal properties:
%   - amplitude distribution in time domain
%   - long term spectrum in freq. domain
%   - modulations in freq. domain
%
% Usage: [] = analyze(obj)
%
%   Input:   ---------
%           obj: Object of type NoiseSynthesis.NoiseAnalysisSynthesis
%
%  Output:   ---------
%           none
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  02-Dec-2015 16:22:02
%

import NoiseSynthesis.External.*

% make sure to use the desired parameters for the modulations
updateModulationParameters(obj);

% declick the analysis signal if desired
if obj.bDeClick
    showMsg(obj,'DeClicking Analysis Signal');
    DeClickAnalysisSignal(obj);
end

% HP filter if desired (true by default)
if obj.bHPFilterAnalysis
    [b, a] = butter(2, obj.CutOffHP*2/obj.Fs, 'high');
    obj.AnalysisSignal = filter(b, a, obj.AnalysisSignal);
end

% estimate the amplitude distribution
showMsg(obj, 'Analyzing Amplitude Distribution');
analyzeAmplitudeDistribution(obj);

showMsg(obj, 'DeCrackling Analysis Signal')
DeCrackleAnalysisSignal(obj);

% transform into STFT domain
showMsg(obj,'Transforming into STFT Domain');
AnalysisFilterbank(obj, obj.AnalysisSignal);

% estimate coloration
showMsg(obj, 'Analyzing Coloration');
analyzeMeanBandPower(obj);

% estimate modulations
showMsg(obj, 'Analyzing Modulations');
analyzeModulations(obj);






% End of file: analyze.m
