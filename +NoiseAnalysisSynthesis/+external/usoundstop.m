function [] = usoundstop()
%USOUNDSTOP Stop playback on UNIX systems
% -------------------------------------------------------------------------
% This function stops playback on *NIX systems when sound was played back
% via aplay (usound.m) by killing the corresponding system process.
%
% Usage: [] = usoundstop()
%
%   Input:   ---------
%           none
%
%  Output:   ---------
%           none
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  10-Nov-2015 23:48:18
%


% if an 'aplay' process is found kill it
system(sprintf(...
    ['if [ "$(pidof aplay)" ]; then\n',...
    'killall -KILL aplay\n',...
    'fi']...
    ));



% End of file: usoundstop.m
