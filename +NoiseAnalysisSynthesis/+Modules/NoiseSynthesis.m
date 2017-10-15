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
end

properties (Nontunable)
    SampleRate;
    NumBins;
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
    FrequencyBands; % Frequency bands
    ModulationParameters;
    
    SpectrumSynthesizer;
    ModulationSynthesizer;
    AmplitudeSynthesizer;
    ClickSynthesizer;
end

properties (SetAccess = protected, Dependent)
    NumSensorSignals;  % Number of desired sensor signals (dependent on size of the sensor position matrix)
    NumFrequencyBands; % Number of frequency bands
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
        
        obj.NumBins = obj.StftParameters.Nfft/2+1;
        
        % Initialize angles between source(s) and sensor(s)
        obj.Source2SensorAngle = pi/2 * ones(obj.NumSensorSignals);
        
        obj.SpectrumSynthesizer.SampleRate        = obj.SampleRate;
        obj.SpectrumSynthesizer.Nfft              = obj.StftParameters.Nfft;
        obj.SpectrumSynthesizer.MeanPsd           = obj.NoiseProperties.MeanPsd;
        obj.SpectrumSynthesizer.DoApplyColoration = obj.DoApplyColoration;
        
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
        noiseBlock{1} = obj.SpectrumSynthesizer();
        noiseBlock    = obj.ModulationSynthesizer(noiseBlock);
        
        if obj.DoApplyModulations
            noiseBlock = obj.applyModulations();
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
    end
end
end





% End of file: NoiseSynthesis.m
