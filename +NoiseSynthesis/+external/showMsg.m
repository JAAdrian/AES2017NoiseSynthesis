function [] = showMsg(self,szMessage)
%SHOWMSG Print verbos message in command line
% -------------------------------------------------------------------------
% Checks whether in verbose or not so can be included in the code no matter
% what self.bVerbose is true or false.
%
% Usage: [] = showMsg(self,szMessage)
%
%   Input:   ---------
%           self: Object of type NoiseSynthesis.NoiseAnalysisSynthesis
%           szMessage: Message to be printed
%
%  Output:   ---------
%           none
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:51:03
%


if self.bVerbose,
fprintf('*** %s ***\n',szMessage);
end




% End of file: showMsg.m
