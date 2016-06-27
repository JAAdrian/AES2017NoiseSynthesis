function [] = analyzeMeanBandPower(self)
%ANALYZEMEANBANDPOWER Compute the analysis file's PSD
% -------------------------------------------------------------------------
%
% Usage: [] = analyzeMeanBandPower(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:04:56
%

import NoiseSynthesis.external.*


% compute the MS (mean square), i.e. the average power in the
% current band

if self.ModelParameters.bReducePSD,
    blocklenSec = 50e-3;
    overlap     = 0.5;
    params      = NoiseSynthesis.STFTparams(blocklenSec,overlap,self.Fs);
    
    mSTFT = STFT(...
        self.AnalysisSignal,...
        params...
        );
    
    vPowers = mean(mSTFT.*conj(mSTFT),2);
    vPowers([1,end]) = 2*vPowers([1,end]);
    
    vFreq = linspace(0,self.Fs/2,params.NFFT/2+1);
    
    stAlgo.fs   = self.Fs;              % sampling rate
    stAlgo.type = 'fractional-octave';  % type of spectral smoothing
                                        % . 'fractional-octave' or
                                        % . 'fixed-bandwidth'
    
    stAlgo.bandwidth = 1;           % bandwidth
                                    % . in octaves for 'fractional-octave'
                                    % . in Hz for 'fixed-bandwidth'
    
    stAlgo.L_FFT = params.NFFT;            % length of the DFT
    
    % initialize the smoothing algorithm
    stAlgo = NoiseSynthesis.spectralsmoothing.spectralsmoothing_init(stAlgo);
    
    % perform the smoothing
    vPowersSmooth = NoiseSynthesis.spectralsmoothing.spectralsmoothing_process(vPowers, stAlgo);
    
    vWeights = ones(length(vPowersSmooth),1);
    
    [b,a] = FDLSDesign(...
        self.ModelParameters.ColorNumOrd,...
        self.ModelParameters.ColorDenumOrd,...
        vFreq,...
        vPowersSmooth,...
        self.Fs,...
        vWeights);
    
    self.ModelParameters.MeanPSD = {b, a};
else
    % times two due to single sided spectrum
    self.ModelParameters.MeanPSD = mean(self.mBands .^ 2,2);
    self.ModelParameters.MeanPSD(2:end-1) = 2 * self.ModelParameters.MeanPSD(2:end-1) ;
end





% End of file: analyzeMeanBandPower.m
