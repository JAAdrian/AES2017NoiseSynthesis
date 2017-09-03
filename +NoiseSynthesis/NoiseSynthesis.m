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
	ArtificialLevelCurves; % Generated level curves for all bands
	
	Theta; % Angles between sources and sensors
    CohereFun; % Function handle to the desired coherence model
end

properties (Access = protected, Transient)
    SensorDistances; % Distances between sensors
end

properties (SetAccess = protected, GetAccess = public)
	SensorSignals = []; % Final sensor signals after synthesis
	ClickTracks   = {}; % Click track if desired (which is also already added to SensorSignals)
end

properties (SetAccess = protected, Dependent)
	NumSensorSignals; % Number of desired sensor signals (dependent on size of the sensor position matrix)
end

properties (Access = protected)
	
end




methods
	function [obj] = NoiseSynthesis(varargin)
		obj.setProperties(nargin, varargin{:})
	end
	
	
	function [numSens] = get.NumSensorSignals(obj)
        if obj.DoApplySpatialCoherence
            numSens = size(obj.ModelParameters.SensorPositions, 2);
        else
            numSens = 1;
        end
    end
	
	function CohereFun = get.CohereFun(obj)
        switch lower(obj.ModelParameters.CohereModel)
            case 'cylindrical'
                % zeroth order bessel of first kind
                CohereFun = @(freq, dist, theta, vPSD) besselj(0, 2*pi * freq * dist / obj.SoundVelocity);
            case 'spherical'
                CohereFun = @(freq, dist, theta, vPSD) sinc(2 * freq * dist / obj.SoundVelocity);
            case 'anisotropic'
                CohereFun = @(freq, dist, theta, vPSD) anisotropicCoherence(obj, freq, dist, theta, vPSD);
            case 'binaural2d'
                CohereFun = @(freq, dist, theta, vPSD) binaural2d(obj, dist, freq);
            case 'binaural3d'
                CohereFun = @(freq, dist, theta, vPSD) binaural3d(obj, dist, freq);
            otherwise
                warning(sprintf('Coherence model not recognized. Switched to default (''%s'')...',...
                    obj.ModelParameters.CohereModel)); %#ok<SPWRN>
        end
    end
end


end





% End of file: NoiseSynthesis.m
