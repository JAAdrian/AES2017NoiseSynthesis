classdef ModulationSynthesis < matlab.System
%MODULATIONSYNTHESIS <purpose in one line!>
% -------------------------------------------------------------------------
% <Detailed description of the function>
%
% ModulationSynthesis Properties:
%	propA - <description>
%	propB - <description>
%
% ModulationSynthesis Methods:
%	doThis - <description>
%	doThat - <description>
%
% Author :  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date   :  09-Sep-2017 23:24:26
%

% History:  v0.1.0   initial version, 09-Sep-2017 (JA)
%


properties (Access = public)
    SampleRate;
    
    NoiseProperties;
    ModulationParameters;
    
	MarkovSynthesizer;
    
    NumFrequencyBands;
    NumSynthesisBlocks;
end



methods
	function [obj] = ModulationSynthesis(varargin)
        obj.SampleRate = 44.1e3;
        
        obj.NumFrequencyBands  = 16;
        obj.NumSynthesisBlocks = 2;
        
        obj.MarkovSynthesizer = cell(obj.NumFrequencyBands, 1);
        obj.MarkovSynthesizer = cellfun(...
            @(x) NoiseAnalysisSynthesis.Modules.MarkovSynthesis(), ...
            obj.MarkovSynthesizer, ...
            'uni', false ...
            );
        obj.NoiseProperties   = NoiseAnalysisSynthesis.NoiseProperties();
        
		obj.setProperties(nargin, varargin{:})
    end
end


methods (Access = protected)
	function [] = setupImpl(obj)
        for iBand = 1:obj.NumFrequencyBands
            obj.MarkovSynthesizer{iBand}.TransitionMatrix = ...
                obj.NoiseProperties.MarkovTransition{iBand};
            
            obj.MarkovSynthesizer{iBand}.StateBoundaries = ...
                obj.NoiseProperties.MarkovStateBoundaries;
        end
	end

	function [] = resetImpl(obj)
		cellfun(@(x) x.reset(), obj.MarkovSynthesizer);
	end

	function [modulations] = stepImpl(obj)
        modulations = zeros(obj.NumFrequencyBands, obj.NumSynthesisBlocks);
        for iBand = 1:obj.NumFrequencyBands
            modulations(iBand, :) = obj.MarkovSynthesizer{iBand}();
        end
    end
end

end





% End of file: ModulationSynthesis.m
