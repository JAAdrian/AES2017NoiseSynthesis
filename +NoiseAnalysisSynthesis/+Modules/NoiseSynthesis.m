classdef NoiseSynthesis < matlab.System
%NOISESYNTHESIS <purpose in one line!>
% -------------------------------------------------------------------------
% <Detailed description of the function>
%
% NoiseSynthesis Properties:
%	propA - <description>
%	propB - <description>
%
% NoiseSynthesis Methods:
%	doThis - <description>
%	doThat - <description>
%
% Author :  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date   :  03-Sep-2017 21:02:25
%

% History:  v0.1.0   initial version, 03-Sep-2017 (JA)
%



properties (Access = public)
    ModelParameters;
    NoiseProperties;
    StftParameters;
    
    DesiredLengthSignalSamples;
    
    Source2SensorAngle; % Angles between sources and sensors
    
    SpectrumSynthesizer;
    ModulationSynthesizer;
    AmplitudeSynthesizer;
    ClickSynthesizer;
end

properties (Nontunable)
    SampleRate;
end

properties (Logical, Nontunable)
    DoApplySpatialCoherence;
    DoApplyColoration;
    DoApplyModulations;
    
    Verbose;
end

properties (Dependent)
    NumSources; % Number of acoustic sources in the noise field (dependent on size of the sources position matrix)
end

properties (SetAccess = protected)
    CoherenceFun; % Function handle to the desired coherence model
end

properties (Access = protected, Constant)
    SOUND_VELOCITY = 343; % Velocity of sound
    MOD_NORM_FUN   = @(x) mad(x, 1, 1); % Normalization function for level fluctuations
end

properties (Access = protected)
    ModulationParameters;
end

properties (SetAccess = protected, Dependent)
    NumSensorSignals;  % Number of desired sensor signals (dependent on size of the sensor position matrix)
    NumSynthesisBlocks;
end

properties (Access = protected, Transient)
    SensorDistances; % Distances between sensors
end



methods
    function [obj] = NoiseSynthesis(varargin)
        obj.DoApplySpatialCoherence = false;
        obj.DoApplyColoration       = true;
        obj.DoApplyModulations      = true;
        
        obj.SampleRate = 44.1e3;
        
        obj.DesiredLengthSignalSamples = obj.SampleRate;
        
        obj.ModelParameters = NoiseAnalysisSynthesis.ModelParameters();
        obj.NoiseProperties = NoiseAnalysisSynthesis.NoiseProperties();
        obj.StftParameters  = NoiseAnalysisSynthesis.STFTparams();
        
        obj.SpectrumSynthesizer   = NoiseAnalysisSynthesis.Modules.SpectrumSynthesis();
        obj.ModulationSynthesizer = NoiseAnalysisSynthesis.Modules.ModulationSynthesis();
        obj.AmplitudeSynthesizer  = NoiseAnalysisSynthesis.Modules.AmplitudeSynthesis();
        obj.ClickSynthesizer      = NoiseAnalysisSynthesis.Modules.ClickSynthesis();
        
        obj.Source2SensorAngle = pi/2;
        
        obj.Verbose = false;
        
        obj.setProperties(nargin, varargin{:})
    end
    
    
    function [numSignals] = get.NumSensorSignals(obj)
        if obj.DoApplySpatialCoherence
            numSignals = size(obj.ModelParameters.SensorPositions, 2);
        else
            numSignals = 1;
        end
    end
    
    function [CohereFun] = get.CoherenceFun(obj)
        switch lower(obj.ModelParameters.CoherenceModel)
            case 'cylindrical'
                % zeroth order bessel of first kind
                CohereFun = @(freq, dist, Source2SensorAngle, vPSD) besselj(0, 2*pi * freq * dist / obj.SoundVelocity);
                
            case 'spherical'
                CohereFun = @(freq, dist, Source2SensorAngle, vPSD) sinc(2 * freq * dist / obj.SoundVelocity);
                
            case 'anisotropic'
                CohereFun = @(freq, dist, Source2SensorAngle, vPSD) anisotropicCoherence(obj, freq, dist, Source2SensorAngle, vPSD);
                
            case 'binaural2d'
                CohereFun = @(freq, dist, Source2SensorAngle, vPSD) binaural2d(obj, dist, freq);
                
            case 'binaural3d'
                CohereFun = @(freq, dist, Source2SensorAngle, vPSD) binaural3d(obj, dist, freq);
                
            otherwise
                warning(sprintf('Coherence model not recognized. Switched to default (''%s'')...',...
                    obj.ModelParameters.CoherenceModel)); %#ok<SPWRN>
        end
    end
    
    function [numSynthesisBlocks] = get.NumSynthesisBlocks(obj)
        numSynthesisBlocks = obj.ModulationParameters.Blocklen;
    end
end

methods (Access = protected)
    function [] = setupImpl(obj)
        if ...
                isempty(obj.NoiseProperties.MarkovTransition) && ...
                isempty(obj.NoiseProperties.MarkovStateBoundaries) && ...
                isempty(obj.NoiseProperties.MeanPSD) && ...
                isempty(obj.NoiseProperties.Quantiles) && ...
                isempty(obj.NoiseProperties.CDF)
            
            error(['The model parameters seem to be unset (flushed?)! ',...
                'Make sure to provide parameters either by analyzing, ',...
                'loading a model or reading a parameter file.']);
        end
        
        obj.ModulationParameters = NoiseAnalysisSynthesis.STFTparams(...
            obj.ModelParameters.ModulationWinLen,...
            0,...
            obj.StftParameters.FrameRate ...
            );
        
        % Initialize angles between source(s) and sensor(s)
        obj.Source2SensorAngle = pi/2 * ones(obj.NumSensorSignals);
        
        obj.SpectrumSynthesizer.SampleRate        = obj.SampleRate;
        obj.SpectrumSynthesizer.Nfft              = obj.StftParameters.Nfft;
        obj.SpectrumSynthesizer.MeanPsd           = obj.NoiseProperties.MeanPsd;
        obj.SpectrumSynthesizer.DoApplyColoration = obj.DoApplyColoration;
        obj.SpectrumSynthesizer.NumSignalBlocks   = obj.NumSynthesisBlocks;
        
        obj.ModulationSynthesizer.SampleRate           = obj.SampleRate;
        obj.ModulationSynthesizer.NoiseProperties      = obj.NoiseProperties;
        obj.ModulationSynthesizer.ModulationParameters = obj.ModulationParameters;
        obj.ModulationSynthesizer.NumFrequencyBands    = size(obj.NoiseProperties.MarkovTransition, 1);
        obj.ModulationSynthesizer.NumSynthesisBlocks   = obj.NumSynthesisBlocks;
        
        % shuffle the random generator by default. If in verbose mode reset the
        % generator
        if obj.Verbose
            rng(1);
        else
            rng('shuffle');
        end
    end
    
    function [noiseBlock] = stepImpl(obj)
        if obj.DoApplySpatialCoherence
            noiseBlock = obj.generateCoherentNoise();
            
            
            if obj.ModelParameters.DoApplyClicks
                noiseBlock = obj.ClickSynthesizer(noiseBlock);
            end
        else
            noiseBlock = obj.generateIncoherentNoise();
            
            if obj.ModelParameters.DoApplyClicks
                noiseBlock = obj.ClickSynthesizer(noiseBlock);
            end
        end
    end
    
    
    
    function [noiseBlock] = generateIncoherentNoise(obj)
        noiseBlock = obj.SpectrumSynthesizer();
        
        if obj.DoApplyModulations
            modulations = obj.ModulationSynthesizer();
            
            noiseBlock = obj.applyModulations(noiseBlock, modulations);
        end
        
        if obj.DoApplySpatialCoherence
            
        end
    end
    
    function [noiseBlock] = generateCoherentNoise(obj)
        noiseBlock = cellfun(...
            obj.SpectrumSynthesizer(), ...
            cell(obj.NumSensorSignals, 1), ...
            'uni', false ...
            );
        
        if obj.DoApplyModulations
            
        end
        
        if obj.DoApplySpatialCoherence
            
        end
    end
    
    
    function [noiseOut] = applyModulations(obj, noiseIn, modulations)
        numBands = size(obj.NoiseProperties.MarkovTransition, 1);
        
        frequencies = linspace(0, obj.SampleRate/2, obj.StftParameters.Nfft/2+1);
        
        frequenciesSubSamples = getMelCenterFreqs(frequencies, numBands);
        
        interpolatedModulations = interp1(...
            frequenciesSubSamples, modulations, ...
            frequencies, ...
            'nearest', ...
            'extrap' ...
            );
        
        idxNan = isnan(interpolatedModulations);
        interpolatedModulations(idxNan) = 1;
        
        phase = angle(noiseIn);
        
        noiseOut = interpolatedModulations .* abs(noiseIn);
        
        noiseOut = noiseOut .* exp(1j * phase);
    end
end
end


function [centerFreqs] = getMelCenterFreqs(frequency, numBands)
% Mel and inverse transform from:
% https://en.wikipedia.org/wiki/Mel_scale

% Mel transform
melScale = 2595*log10(1+frequency/700);

minFreq = min(melScale);
maxFreq = max(melScale);
melResolution = (maxFreq - minFreq) / (numBands + 1);

melCenterFreqs = (0 : numBands-1) * melResolution + melResolution/2;

% inverse transform
centerFreqs = 700 * (exp(melCenterFreqs / 1127) - 1);
end



% End of file: NoiseSynthesis.m
