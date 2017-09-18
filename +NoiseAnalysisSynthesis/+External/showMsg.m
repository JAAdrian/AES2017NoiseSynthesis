function [] = showMsg(isVerbose, message)
%SHOWMSG Print verbos message in command line
% -------------------------------------------------------------------------
% Checks whether in verbose or not so can be included in the code no matter
% what obj.bVerbose is true or false.
%
% Usage: [] = showMsg(isVerbose, message)
%
%   Input:   ---------
%           isVerbose: bool whether verbose mode is specified
%           message: Message to be printed
%
%  Output:   ---------
%           none
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:51:03
%


if isVerbose
fprintf('*** %s ***\n', message);
end




% End of file: showMsg.m
