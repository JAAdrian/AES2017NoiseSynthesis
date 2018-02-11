classdef ClickSynthesis < matlab.System
%CLICKSYNTHESIS <purpose in one line!>
% -------------------------------------------------------------------------
% <Detailed description of the function>
%
% ClickSynthesis Properties:
%	propA - <description>
%	propB - <description>
%
% ClickSynthesis Methods:
%	doThis - <description>
%	doThat - <description>
%
% Author :  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date   :  03-Oct-2017 21:51:00
%

% History:  v0.1.0   initial version, 03-Oct-2017 (JA)
%


properties (Access = public)
	
end

properties (SetAccess = protected, GetAccess = public)
	
end

properties (Access = protected)
	
end



methods
	function [obj] = ClickSynthesis(varargin)
		obj.setProperties(nargin, varargin{:})
	end
end


methods (Access = protected)
	function [] = setupImpl(obj)
		
	end

	function [] = resetImpl(obj)
		
	end

	function [noiseBlock] = stepImpl(obj, noiseBlock)
		
	end

	function [] = releaseImpl(obj)
		
	end
end

end





% End of file: ClickSynthesis.m
