function [vTimeSignal] = SynthesisFilterbank(self)
%SYNTHESISFILTERBANK Transform the time-freq. repr. to time domain
% -------------------------------------------------------------------------
%
% Usage: [vTimeSignal] = SynthesisFilterbank(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 19:55:38
%

import NoiseSynthesis.external.*


vTimeSignal = ISTFT(...
    self.mBands,...
    self.STFTParameters...
    );

vTimeSignal = vTimeSignal - mean(vTimeSignal);




% End of file: SynthesisFilterbank.m
