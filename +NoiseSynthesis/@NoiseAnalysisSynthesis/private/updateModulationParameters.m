function [] = updateModulationParameters(self)
%UPDATEMODULATIONPARAMETERS Update the modulation parameters based on STFT params
% -------------------------------------------------------------------------
%
% Usage: [] = updateModulationParameters(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:23:46
%


self.ModulationParams = NoiseSynthesis.STFTparams(...
    self.ModelParameters.ModulationWinLen,...
    0,...
    self.STFTParameters.FrameRate);



% End of file: updateModulationParameters.m
