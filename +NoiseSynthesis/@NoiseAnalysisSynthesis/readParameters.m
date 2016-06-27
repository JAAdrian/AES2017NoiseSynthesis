function [] = readParameters(self,szFilename)
%READPARAMETERS Read parameter set for signal synthesis
% -------------------------------------------------------------------------
% This class method reads model parameters from a mat-file and passes them
% to the parameter object.
%
% Usage: [] = readParameters(self,szFilename)
%
%   Input:   ---------
%           self: Object of type NoiseSynthesis.NoiseAnalysisSynthesis
%           szFilename: Name of the desired parameter mat-file
%
%  Output:   ---------
%           none
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  02-Dec-2015 16:34:23
%

assert(isa(szFilename, 'char'), ['Pass a string corresponding to the ', ...
    'name of parameter file!']);

[szPath,szName,szExt] = fileparts(szFilename);

if isempty(szExt) || ~strcmpi(szExt,'.mat'),
    szFilename = fullfile(szPath,[szName, '.mat']);
end

try
    stData = load(szFilename);
catch
    error('File not found!');
end

self.ModelParameters = stData.objParameterSet;





% End of file: readParameters.m
