function [] = checkFFTlength(obj)
%CHECKFFTLENGTH Adjust DFT and block size size if sampling rate is not 44.1 kHz
% -------------------------------------------------------------------------
%
% Usage: [] = checkFFTlength(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:20:34
%


if obj.SampleRate < 16e3 & obj.SampleRate >= 8e3 %#ok<AND2>
    obj.STFTParameters = NoiseSynthesis.STFTparams(256/obj.SampleRate, obj.overlapRatio, obj.Fs, 'synthesis');
    obj.STFTParameters.OriginalSignalLength = obj.DesiredSignalLenSamples;
end
if obj.SampleRate < 44.1e3 & obj.SampleRate >= 16e3 %#ok<AND2>
    obj.STFTParameters = NoiseSynthesis.STFTparams(512/objSampleRate, obj.overlapRatio, obj.Fs, 'synthesis');
    obj.STFTParameters.OriginalSignalLength = obj.DesiredSignalLenSamples;
end
if obj.SampleRate > 48e3
    obj.STFTParameters = NoiseSynthesis.STFTparams(2048/obj.SampleRate, obj.overlapRatio, obj.Fs, 'synthesis');
    obj.STFTParameters.OriginalSignalLength = obj.DesiredSignalLenSamples;
end




% End of file: checkFFTlength.m
