classdef MarkovSynthesis < matlab.System
%MARKOVSYNTHESIS <purpose in one line!>
% -------------------------------------------------------------------------
% <Detailed description of the function>
%
% MarkovSynthesis Properties:
%	propA - <description>
%	propB - <description>
%
% MarkovSynthesis Methods:
%	doThis - <description>
%	doThat - <description>
%
% Author :  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date   :  09-Sep-2017 23:23:10
%

% History:  v0.1.0   initial version, 09-Sep-2017 (JA)
%


properties (Access = public)
	
end


properties (SetAccess = protected, GetAccess = public)
	
end


properties (Access = protected)
	
end



methods
	function [obj] = MarkovSynthesis(varargin)
		obj.setProperties(nargin, varargin{:})
	end
end


methods (Access = protected)
	function [] = setupImpl(obj)
		
	end

	function [] = resetImpl(obj)
		
	end

	function [] = stepImpl(obj)
		
	end

	function [] = releaseImpl(obj)
		
	end
end

end





% End of file: MarkovSynthesis.m