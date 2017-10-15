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
    
	MarkovSynthesizer;
end


properties (SetAccess = protected, GetAccess = public)
	
end


properties (Access = protected)
	
end



methods
	function [obj] = ModulationSynthesis(varargin)
        obj.SampleRate = 44.1e3;
        
        obj.MarkovSynthesizer = NoiseAnalysisSynthesis.Modules.MarkovSynthesis();
        
		obj.setProperties(nargin, varargin{:})
	end
end


methods (Access = protected)
	function [] = setupImpl(obj)
		obj.MarkovSynthesizer.SampleRate = obj.SampleRate;
	end

	function [] = resetImpl(obj)
		
	end

	function [] = stepImpl(obj)
		
	end

	function [] = releaseImpl(obj)
		
	end
end

end





% End of file: ModulationSynthesis.m
