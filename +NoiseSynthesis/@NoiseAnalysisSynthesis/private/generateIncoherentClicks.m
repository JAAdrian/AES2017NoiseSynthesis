function [] = generateIncoherentClicks(self)
%GENERATEINCOHERENTCLICKS Generate click signals without spatial coherence
% -------------------------------------------------------------------------
%
% Usage: [] = generateIncoherentClicks(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:13:03
%


self.ClickTracks{1} = genArtificialClicks(self);




% End of file: generateIncoherentClicks.m
