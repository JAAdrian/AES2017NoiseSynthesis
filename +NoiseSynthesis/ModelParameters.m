classdef ModelParameters < matlab.System
%MODELPARAMETERSSET Model parameter class for NoiseAnalysisSynthesis
% -------------------------------------------------------------------------
% This class holds the model parameters used by the synthesis of the
% NoiseAnalysisSynthesis class. It is implemented as a class to provide
% autocompletion for all string parameters and to check correctness of
% passed parameters.
%
% Usage: obj = ModelParameters()
%
%   Input:   -----------
%           none
%
%   Output:  -----------
%           obj: created ModelParameters object
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  05-Jul-2015 00:29:19
%

properties (Constant, Hidden)
    muLog      = 1.2811; % Location parameter for click distribution
    sigmaLog   = 0.9387; % Scale parameter for click distribution
    
    clickBlocklenSec = 25e-3; % Block length of the click processor in seconds
    clickOverlap     = 0; % Overlap of the click processor as a ratio
    
    clickFilterOrder = 3; % Order of the HP filter of the click processor
end

properties (Transient, Hidden)
    % Possible values for the desired amplitude modeling method
    AmplitudeModelSet = matlab.system.StringSet({'full','percentile','pareto'});
    
    % Possible values for the desired modulation speed and FB type
    ModulationSpeedSet      = matlab.system.StringSet({'slow','fast'});
    ModulationFilterbankSet = matlab.system.StringSet({'mel','gammatone'});
    
    % Possible values for the desired spatial coherence model
    CohereModelSet = matlab.system.StringSet({...
        'cylindrical', ...
        'spherical', ...
        'anisotropic', ...
        'binaural2d', ...
        'binaural3d' ...
        });
end

properties (Access = public)
    Model = 'manual'; % Noise type model of a preset if loaded
    
    ModulationFilterbank = 'mel'; % Modulation filterbank type
    ModulationDepth = 0.2 * exp(-(0:15)/2).'; % Modulation depth for all freq. bands
    ModulationSpeed = 'fast'; % Modulation speed. Use 'slow' for speech-like types
    MarkovTransition; % Transition matrix for the modulation modeling
    MarkovStateBoundaries; % Markov state boundaries in dB
    
    GammaBands; % Inter-band correlation matrix
    
    ClickTransition; % Transition matrix for the click model
    fLowerClick = 2000; % Lower cutoff freq. for HP filter
    fUpperClick = 6000; % upper cutoff freq. for HP filter
    SNRclick = inf; % SNR between base noise and click signal
    
    MeanPSD; % PSD vector
    ColorNumOrd   = 8; % Number of b coefficients in the PSD modeling
    ColorDenumOrd = 8; % Number of a coefficients in the PSD modeling
    
    AmplitudeModel = 'pareto'; % Method to model the amplitude distribution
    Quantiles; % Independent variable of ECDF or holds information for other models
    CDF; % Dependent variable of ECDF or holds information for other models
    
    CohereModel = 'cylindrical'; % Spatial coherence model
    % Sensor position(s) in meters
    SensorPositions = [
        0,  0.17
        0,  0.00
        0,  0.00
        ];
    SourcePosition = [0.2, 1, 0]'; % Source position(s) in meters
end

properties (Logical)
    DoApplyClicks = false; % Bool whether to apply clicks in the synthesis [default: false]
end

properties (Dependent)
    ModulationWinLen; % Window length of the modulation processor in STFT domain
end

properties (Hidden)
    NumGaussModels    = 4; % Number of Gaussian components when using GMM approach
    maxMarkovRMSlevel = 4; % Maximum Markov state boundary in dB
end

properties (Hidden, Logical)
    DoReducePSD       = true; % Should the FDLS approach be used?
    DoUseMarkovChains = true; % Should the modulation Markov chain approach be used?
end



methods
    function [] = set.ModulationSpeed(obj,szVal)
        assert(...
            isa(szVal,'char'), ...
            'Value must be a string containing one of {''slow'', ''fast''}' ...
            );
        
        obj.ModulationSpeed = szVal;
    end
    
    function [] = set.ModulationFilterbank(obj,szFilterBank)
        assert(...
            isa(szFilterBank,'char'), ...
            'Pass a string containing either ''gammatone'' or ''mel''' ...
            );
        
        obj.ModulationFilterbank = lower(szFilterBank);
    end
    
    function [] = set.AmplitudeModel(obj,szMode)
        assert(...
            isa(szMode,'char'), ...
            ['Pass a string containing one of the ',...
            'supported amplitude models: ''full'', ''alpha'', ''gmm'', ',...
            '''percentile'' or ''pareto'''] ...
            );
        
        obj.AmplitudeModel = lower(szMode);
    end
    
    function [] = set.SensorPositions(obj,val)
        validateattributes(val, {'numeric'}, {'2d', 'nrows', 3});
        
        obj.SensorPositions = val;
    end
    
    function [] = set.SourcePosition(obj,val)
        validateattributes(val, {'numeric'}, {'2d', 'nrows', 3});
        
        obj.SourcePosition = val;
    end
    

    function winLen = get.ModulationWinLen(obj)
        switch lower(obj.ModulationSpeed)
            case 'slow'
                winLen = 50e-3;
            case 'fast'
                winLen = 25e-3;
        end
    end
end


end


% End of file: ModelParameters.m
