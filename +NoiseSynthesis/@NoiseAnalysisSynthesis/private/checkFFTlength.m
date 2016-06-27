function [] = checkFFTlength(self)
%CHECKFFTLENGTH Adjust DFT and block size size if sampling rate is not 44.1 kHz
% -------------------------------------------------------------------------
%
% Usage: [] = checkFFTlength(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:20:34
%


if self.Fs < 16e3 & self.Fs >= 8e3, %#ok<AND2>
    self.STFTParameters = NoiseSynthesis.STFTparams(256/self.Fs,self.overlapRatio,self.Fs,'synthesis');
    self.STFTParameters.OriginalSignalLength = self.DesiredSignalLenSamples;
end
if self.Fs < 44.1e3 & self.Fs >= 16e3, %#ok<AND2>
    self.STFTParameters = NoiseSynthesis.STFTparams(512/self.Fs,self.overlapRatio,self.Fs,'synthesis');
    self.STFTParameters.OriginalSignalLength = self.DesiredSignalLenSamples;
end
if self.Fs > 48e3,
    self.STFTParameters = NoiseSynthesis.STFTparams(2048/self.Fs,self.overlapRatio,self.Fs,'synthesis');
    self.STFTParameters.OriginalSignalLength = self.DesiredSignalLenSamples;
end




% End of file: checkFFTlength.m
