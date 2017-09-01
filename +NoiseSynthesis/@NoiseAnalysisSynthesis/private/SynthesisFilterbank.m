function [timeSignal] = SynthesisFilterbank(obj)
%SYNTHESISFILTERBANK Transform the time-freq. repr. to time domain
% -------------------------------------------------------------------------
%
% Usage: [vTimeSignal] = SynthesisFilterbank(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 19:55:38
%

import NoiseSynthesis.external.*


timeSignal = ISTFT(...
    obj.mBands, ...
    obj.STFTParameters ...
    );

timeSignal = timeSignal - mean(timeSignal);




% End of file: SynthesisFilterbank.m
