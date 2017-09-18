function [] = usound(vSignal, fs)
%USOUND Playback sound on UNIX systems
% -------------------------------------------------------------------------
% This function uses aplay to playback sounds on *NIX systems. aplay is
% often installed by default. No scaling is applied to the signal vector.
%
% Usage: [] = usound(vSignal, fs)
%
%   Input:   ---------
%           vSignal: Signal vector to be played back
%           fs: Sampling rate in Hz
%
%  Output:   ---------
%           none
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  03-Nov-2015 16:04:39
%

% code adapted from:
% http://signalsprocessed.blogspot.de/2011/02/playing-sounds-from-matlab-on-unix.html


filename = [tempname '.wav'];
audiowrite( filename, vSignal, fs );

dummy = system(sprintf('aplay %s &', filename)); %#ok<NASGU>


% End of file: usound.m
