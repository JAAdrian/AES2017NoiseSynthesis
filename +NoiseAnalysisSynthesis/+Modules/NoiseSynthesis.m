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
    
    Source2SensorAngle; % Angles between sources and sensors
end

properties (Logical, Nontunable)
    DoApplySpatialCoherence;
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
    
    % SpectrumSynthesizer??
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
        obj.DoApplyModulations      = true;
        
        obj.ModelParameters = NoiseAnalysisSynthesis.ModelParameters();
        obj.NoiseProperties = NoiseAnalysisSynthesis.NoiseProperties();
        obj.StftParameters  = NoiseAnalysisSynthesis.STFTparams();
        
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
                isempty(obj.ModelParameters.MarkovTransition) && ...
                isempty(obj.ModelParameters.MarkovStateBoundaries) && ...
                isempty(obj.ModelParameters.MeanPSD) && ...
                isempty(obj.ModelParameters.Quantiles) && ...
                isempty(obj.ModelParameters.CDF)
            
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
            end
        else
            
            if obj.ModelParameters.DoApplyClicks
            end
        end
    end
    
    
    
    function [noiseBlock] = generateCoherentNoise(obj)
        noiseBlock = cellfun(...
            obj.generateBaseNoise(), ...
            cell(obj.NumSensorSignals, 1), ...
            'uni', false ...
            );
        
        if obj.DoApplyModulations
            
        end
    end
    
    function [noise] = generateBaseNoise(obj)
        uniformPhaseNoise = 2*pi * rand(obj.numBins, 1) - pi;
        uniformPhaseNoise([1,end],:) = 0;
        
        if obj.DoApplyColoration
            if iscell(obj.NoiseProperties.MeanPSD)
                meanPSD = freqz(...
                    obj.ModelParameters.MeanPSD{1}, ...
                    obj.ModelParameters.MeanPSD{2}, ...
                    obj.StftParameters.Nfft/2+1, ...
                    obj.SampleRate ...
                    );
                
                meanPSD = abs(meanPSD);
                
            else
                meanPSD = obj.ModelParameters.MeanPSD;
                
            end
            
            noise = sqrt(meanPSD) * exp(1j * uniformPhaseNoise);
            
        else
            noise = exp(1j * uniformPhaseNoise);
        end
    end
    
end
end





% End of file: NoiseSynthesis.m
