function [mClickSTFT] = genArtificialClicks(obj)
%GENARTIFICIALCLICKS Generate clicks in STFT domain using the Markov model
% -------------------------------------------------------------------------
%
% Usage: [mClickSTFT] = genArtificialClicks(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:21:05
%

import NoiseSynthesis.External.*

mClickSTFT = STFT(...
    genclickmarkov(obj),...
    obj.STFTParameters...
    );



% End of file: genArtificialClicks.m
