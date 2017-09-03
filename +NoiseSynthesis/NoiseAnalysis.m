classdef NoiseAnalysis < matlab.System
%NOISEANALYSIS <purpose in one line!>
% -------------------------------------------------------------------------
% <Detailed description of the function>
%
% NoiseAnalysis Properties:
%	propA - <description>
%	propB - <description>
%
% NoiseAnalysis Methods:
%	doThis - <description>
%	doThat - <description>
%
% Author :  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date   :  03-Sep-2017 21:02:19
%

% History:  v0.1.0   initial version, 03-Sep-2017 (JA)
%


properties (Access = protected)
	
end


properties (SetAccess = protected, GetAccess = public)
	
end

properties (Dependent)
	CenterFreqs; % Center frequencies of either the Mel or Gammatone FB
	NumStates; % Number of Markov states
end


properties (Nontunable)
	OriginalAnalysisSignal;    % Raw analysis signal
	AnalysisSignal; % Analysis signal (HP filtered and zero-mean)
	BeforeDeCrackling;
	GammatoneLowestBand  = 64; % Lowest center freq. if Gammatone FB is desired [default: 64Hz]
	GammatoneHighestBand = 16e3; % Highestapply center freq. if Gammatone FB is desired [default: 16kHz]
	
	LevelCurves; % Level curves of all bands
	
	NumModulationBands = 16; % Number of modulation bands [default: 16]
	
	CutOffHP = 100; % Cutoff frequency of the HP filter applied to the analysis signal
end

properties (Logical, Hidden, Nontunable)
	DoHpFilterAnalysis = true;  % Bool whether to apply the HP filter before analysis
end



methods
	function [obj] = NoiseAnalysis(varargin)
		obj.setProperties(nargin, varargin{:})
	end
	
	
	function [freqs] = get.CenterFreqs(obj)
        numBands = obj.NumModulationBands;
        
        freqs = erbscale2freq(...
            linspace(...
            freq2erbscale(obj.GammatoneLowestBand),...
            freq2erbscale(obj.GammatoneHighestBand),...
            numBands)...
            );
    end
	
	function [ns] = get.NumStates(obj)
        ns = size(obj.ModelParameters.MarkovStateBoundaries, 1);
    end
end

end

% Auxiliary functions to transform linear frequency scale to ERB scale and
% vice versa
function freq = erbscale2freq(erb)
freq = 1000/4.37 * (10.^(erb/21.4) - 1);
end

function erb = freq2erbscale(freq)
erb = 21.4 * log10(1 + freq/1000 * 4.37);
end



% End of file: NoiseAnalysis.m
