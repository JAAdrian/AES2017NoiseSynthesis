function [] = AnalysisFilterbank(self,vSigIn)
%ANALYSISFILTERBANK Transform signals into STFT domain
% -------------------------------------------------------------------------
%
% Usage: [] = AnalysisFilterbank(self,vSigIn)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 19:54:50
%

import NoiseSynthesis.external.*


self.mBands = STFT(...
    vSigIn,...
    self.STFTParameters...
    );

% STFT returns a single sided spectrum by default
self.mBands = abs(self.mBands);





% End of file: AnalysisFilterbank.m
