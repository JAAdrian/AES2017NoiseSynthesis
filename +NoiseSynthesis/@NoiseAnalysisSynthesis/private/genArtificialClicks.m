function [mClickSTFT] = genArtificialClicks(self)
%GENARTIFICIALCLICKS Generate clicks in STFT domain using the Markov model
% -------------------------------------------------------------------------
%
% Usage: [mClickSTFT] = genArtificialClicks(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:21:05
%

import NoiseSynthesis.external.*

mClickSTFT = STFT(...
    genclickmarkov(self),...
    self.STFTParameters...
    );



% End of file: genArtificialClicks.m
