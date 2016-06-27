function [] = usoundsc(x, fs)
%USOUNDSC Playback sound on UNIX systems with scaling to maximum amplitude
% -------------------------------------------------------------------------
% This function uses aplay to playback sounds on *NIX systems. aplay is
% often installed by default. Scaling is applied to the signal vector so
% the maximum amplitude is 1 to ensure maximum scaling without clipping.
%
% Usage: [] = usoundsc(x, fs)
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
% Date   :  10-Nov-2015 23:46:18
%

x = bsxfun(@rdivide,x,max(abs(x)));

% code adapted from:
% http://signalsprocessed.blogspot.de/2011/02/playing-sounds-from-matlab-on-unix.html

filename = [tempname '.wav'];
audiowrite(filename, x, fs);

dummy = system(sprintf('aplay %s &', filename)); %#ok<NASGU>




% End of file: usoundsc.m
