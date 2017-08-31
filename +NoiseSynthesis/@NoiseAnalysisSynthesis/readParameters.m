function [] = readParameters(obj, filename)
%READPARAMETERS Read parameter set for signal synthesis
% -------------------------------------------------------------------------
% This class method reads model parameters from a mat-file and passes them
% to the parameter object.
%
% Usage: [] = readParameters(obj, filename)
%
%   Input:   ---------
%           obj: Object of type NoiseSynthesis.NoiseAnalysisSynthesis
%           szFilename: Name of the desired parameter mat-file
%
%  Output:   ---------
%           none
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  02-Dec-2015 16:34:23
%

assert(isa(filename, 'char'), ['Pass a string corresponding to the ', ...
    'name of parameter file!']);

[szPath, szName, szExt] = fileparts(filename);

if isempty(szExt) || ~strcmpi(szExt, '.mat')
    filename = fullfile(szPath, [szName, '.mat']);
end

try
    stData = load(filename);
catch
    error('File not found!');
end

obj.ModelParameters = stData.objParameterSet;
obj.DoAnalysis = false;




% End of file: readParameters.m
