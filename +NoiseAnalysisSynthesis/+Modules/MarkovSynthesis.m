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


properties (Nontunable)
	TransitionMatrix;
    StateBoundaries;
end


properties (SetAccess = protected)
	State;
    NeutralState;
end


properties (Access = protected)
	CumulativeTransitionMatrix;
end



methods
	function [obj] = MarkovSynthesis(varargin)
        obj.TransitionMatrix = zeros(10);
        obj.State            = 6;
        obj.StateBoundaries  = zeros(10, 2);
        
		obj.setProperties(nargin, varargin{:})
	end
end


methods (Access = protected)
	function [] = setupImpl(obj)
        obj.CumulativeTransitionMatrix = cumsum(obj.TransitionMatrix, 2);
        obj.CumulativeTransitionMatrix = bsxfun(...
            @rdivide, ...
            obj.CumulativeTransitionMatrix, ...
            obj.CumulativeTransitionMatrix(:, end) ...
            );
        
        obj.NeutralState = find(obj.StateBoundaries >= 0, 1, 'first');
	end

	function [] = resetImpl(obj)
		obj.State = obj.NeutralState;
	end

	function [modulation] = stepImpl(obj)
        die = rand();
        
        nextStateCandidates = find(obj.CumulativeTransitionMatrix(obj.State, :) >= die);
        if nextStateCandidates
            nextState = nextStateCandidates(1);
        else
            nextState = obj.NeutralState;
        end
        
        modulation = obj.getModulationFactor(nextState);
        
        obj.State = nextState;
    end
    
    function [modulation] = getModulationFactor(obj, state)
        modulation = ...
            (obj.StateBoundaries(state, 2) - obj.StateBoundaries(state, 1)) ...
            * rand() + ...
            obj.StateBoundaries(state, 1);
        
        modulation = 10^(modulation / 20);
    end
end

end





% End of file: MarkovSynthesis.m
