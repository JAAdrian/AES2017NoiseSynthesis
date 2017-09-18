classdef SpectrumAnalysis < matlab.System
%SPECTRUMANALYSIS <purpose in one line!>
% -------------------------------------------------------------------------
% <Detailed description of the function>
%
% SpectrumAnalysis Properties:
%	propA - <description>
%	propB - <description>
%
% SpectrumAnalysis Methods:
%	doThis - <description>
%	doThat - <description>
%
% Author :  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date   :  10-Sep-2017 17:50:47
%

% History:  v0.1.0   initial version, 10-Sep-2017 (JA)
%
    


properties (Constant)
    BLOCKLEN_SEC  = 50e-3;
    OVERLAP_RATIO = 0.5;
end

properties (Access = public)
    Signal;
    SampleRate;
    
    StftParameters;
    ModelParameters;
end

properties (SetAccess = protected)
    FrequencyBands;
end



methods
    function [obj] = SpectrumAnalysis(varargin)
        obj.setProperties(nargin, varargin{:})
    end
end


methods (Access = protected)
    function [] = setupImpl(obj)
        obj.FrequencyBands = NoiseAnalysisSynthesis.External.STFT(...
            obj.Signal,...
            obj.StftParameters...
            );
        
        obj.FrequencyBands = abs(obj.FrequencyBands);
    end
    
    function [meanPsd] = stepImpl(obj)
        import NoiseAnalysisSynthesis.External.*
        
        % compute the MS (mean square), i.e. the average power in the
        % current band
        
        if obj.ModelParameters.DoReducePSD
            params = NoiseAnalysisSynthesis.STFTparams(...
                obj.BLOCKLEN_SEC, ...
                obj.OVERLAP_RATIO, ...
                obj.SampleRate ...
                );
            
            spec = STFT(...
                obj.Signal, ...
                params ...
                );
            
            powers = mean(spec .* conj(spec), 2);
            powers([1, end]) = 2*powers([1,end]);
            
            freq = linspace(0, obj.SampleRate/2, params.Nfft/2+1);
            
            powersSmooth = obj.smoothSpectrum(powers, params.Nfft);
            
            weights = ones(length(powersSmooth), 1);
            
            [b, a] = FDLSDesign(...
                obj.ModelParameters.ColorNumOrd, ...
                obj.ModelParameters.ColorDenumOrd, ...
                freq, ...
                powersSmooth, ...
                obj.SampleRate, ...
                weights ...
                );
            
            meanPsd = {b, a};
            
        else
            % times two due to single sided spectrum
            meanPsd = mean(obj.FrequencyBands .^ 2, 2);
            meanPsd(2:end-1) = 2 * meanPsd(2:end-1) ;
        end
    end
    
    
    function [powersSmooth] = smoothSpectrum(obj, powers, nfft)
        import NoiseAnalysisSynthesis.External.SpectralSmoothing.*
        
        smoother.fs   = obj.SampleRate;       % sampling rate
        smoother.type = 'fractional-octave';  % type of spectral smoothing
                                              % . 'fractional-octave' or
                                              % . 'fixed-bandwidth'

        smoother.bandwidth = 1;  % bandwidth
                                 % . in octaves for 'fractional-octave'
                                 % . in Hz for 'fixed-bandwidth'
        
        smoother.L_FFT = nfft; % length of the DFT
        
        % initialize the smoothing algorithm
        smoother = spectralsmoothing_init(smoother);
        
        % perform the smoothing
        powersSmooth = spectralsmoothing_process(powers, smoother);
    end
end

end





% End of file: SpectrumAnalysis.m
