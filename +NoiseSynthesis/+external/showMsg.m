function [] = showMsg(obj, message)
%SHOWMSG Print verbos message in command line
% -------------------------------------------------------------------------
% Checks whether in verbose or not so can be included in the code no matter
% what obj.bVerbose is true or false.
%
% Usage: [] = showMsg(obj,szMessage)
%
%   Input:   ---------
%           obj: Object of type NoiseSynthesis.NoiseAnalysisSynthesis
%           message: Message to be printed
%
%  Output:   ---------
%           none
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:51:03
%


if obj.verbose
fprintf('*** %s ***\n', message);
end




% End of file: showMsg.m
