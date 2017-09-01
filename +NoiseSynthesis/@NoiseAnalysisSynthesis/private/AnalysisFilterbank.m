function [] = AnalysisFilterbank(obj, signalIn)
%ANALYSISFILTERBANK Transform signals into STFT domain
% -------------------------------------------------------------------------
%
% Usage: [] = AnalysisFilterbank(obj,vSigIn)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 19:54:50
%

import NoiseSynthesis.external.*


obj.Bands = STFT(...
    signalIn,...
    obj.STFTParameters...
    );

% STFT returns a single sided spectrum by default
obj.mBands = abs(obj.Bands);





% End of file: AnalysisFilterbank.m
