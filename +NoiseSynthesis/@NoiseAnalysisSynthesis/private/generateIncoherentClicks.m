function [] = generateIncoherentClicks(obj)
%GENERATEINCOHERENTCLICKS Generate click signals without spatial coherence
% -------------------------------------------------------------------------
%
% Usage: [] = generateIncoherentClicks(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:13:03
%


obj.ClickTracks{1} = genArtificialClicks(obj);




% End of file: generateIncoherentClicks.m
