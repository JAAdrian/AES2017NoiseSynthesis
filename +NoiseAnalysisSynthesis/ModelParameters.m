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
    AmplitudeModelSet = matlab.system.StringSet({...
        'Full', ...
        'Percentile', ...
        'Pareto' ...
        });
    
    % Possible values for the desired modulation speed and FB type
    ModulationSpeedSet = matlab.system.StringSet({'Slow', 'Fast'});
    
    % Possible values for the desired spatial coherence model
    CoherenceModelSet = matlab.system.StringSet({...
        'Cylindrical', ...
        'Spherical', ...
        'Anisotropic', ...
        'Binaural2d', ...
        'Binaural3d' ...
        });
end

properties (Access = public)
    Model = 'Manual'; % Noise type model of a preset if loaded
    
    ModulationSpeed = 'Fast'; % Modulation speed. Use 'slow' for speech-like types
    
    ColorNumOrd   = 8; % Number of b coefficients in the PSD modeling
    ColorDenumOrd = 8; % Number of a coefficients in the PSD modeling
    
    AmplitudeModel = 'Pareto'; % Method to model the amplitude distribution
    
    CoherenceModel = 'Cylindrical'; % Spatial coherence model
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
    MaxMarkovRMSlevel = 4; % Maximum Markov state boundary in dB
end

properties (Hidden, Logical)
    DoReducePSD       = true; % Should the FDLS approach be used?
    DoUseMarkovChains = true; % Should the modulation Markov chain approach be used?
end



methods    
    function [] = set.SensorPositions(obj, val)
        validateattributes(val, {'numeric'}, {'2d', 'nrows', 3});
        
        obj.SensorPositions = val;
    end
    
    function [] = set.SourcePosition(obj, val)
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
