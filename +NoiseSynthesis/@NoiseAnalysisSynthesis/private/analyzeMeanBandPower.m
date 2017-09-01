function [] = analyzeMeanBandPower(obj)
%ANALYZEMEANBANDPOWER Compute the analysis file's PSD
% -------------------------------------------------------------------------
%
% Usage: [] = analyzeMeanBandPower(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:04:56
%

import NoiseSynthesis.external.*


% compute the MS (mean square), i.e. the average power in the
% current band

if obj.ModelParameters.bReducePSD
    blocklenSec = 50e-3;
    overlap     = 0.5;
    params      = NoiseSynthesis.STFTparams(blocklenSec, overlap, obj.Fs);
    
    spec = STFT(...
        obj.AnalysisSignal, ...
        params ...
        );
    
    powers = mean(spec .* conj(spec), 2);
    powers([1, end]) = 2*powers([1,end]);
    
    freq = linspace(0, obj.SampleRate/2, params.Nfft/2+1);
    
    stAlgo.fs   = obj.SampleRate;              % sampling rate
    stAlgo.type = 'fractional-octave';  % type of spectral smoothing
                                        % . 'fractional-octave' or
                                        % . 'fixed-bandwidth'
    
    stAlgo.bandwidth = 1;           % bandwidth
                                    % . in octaves for 'fractional-octave'
                                    % . in Hz for 'fixed-bandwidth'
    
    stAlgo.L_FFT = params.Nfft;            % length of the DFT
    
    % initialize the smoothing algorithm
    stAlgo = NoiseSynthesis.spectralsmoothing.spectralsmoothing_init(stAlgo);
    
    % perform the smoothing
    powersSmooth = NoiseSynthesis.spectralsmoothing.spectralsmoothing_process(powers, stAlgo);
    
    weights = ones(length(powersSmooth), 1);
    
    [b, a] = FDLSDesign(...
        obj.ModelParameters.ColorNumOrd, ...
        obj.ModelParameters.ColorDenumOrd, ...
        freq, ...
        powersSmooth, ...
        obj.SampleRate, ...
        weights ...
        );
    
    obj.ModelParameters.MeanPSD = {b, a};
else
    % times two due to single sided spectrum
    obj.ModelParameters.MeanPSD = mean(obj.mBands .^ 2, 2);
    obj.ModelParameters.MeanPSD(2:end-1) = 2 * obj.ModelParameters.MeanPSD(2:end-1) ;
end





% End of file: analyzeMeanBandPower.m
