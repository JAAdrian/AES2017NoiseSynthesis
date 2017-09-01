function [] = saveParameters(obj,szFilename)
%SAVEPARAMETERS Save model parameters to mat-file
% -------------------------------------------------------------------------
% This class method saves the model parameters to a mat-file for later use
% to load desired parameters for signal synthesis by the class method
% readParameters()
%
% Usage: [] = saveParameters(obj,szFilename)
%
%   Input:   ---------
%           obj: Object of type NoiseSynthesis.NoiseAnalysisSynthesis
%           szFilename: Name of the mat-file to save the parameters in
%
%  Output:   ---------
%           none
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  02-Dec-2015 16:33:21
%

assert(isa(szFilename, 'char'), ['Pass a string corresponding to the ', ...
    'name of the parameter file!']);

[szPath,szName,szExt] = fileparts(szFilename);

if ~exist(szPath,'dir') && ~isempty(szPath)
    mkdir(szPath);
end

if isempty(szExt) || ~strcmpi(szExt,'.mat')
    szFilename = fullfile(szPath,[szName, '.mat']);
end

objParameterSet = obj.ModelParameters; %#ok<NASGU>

save(szFilename,'objParameterSet');






% End of file: saveParameters.m
