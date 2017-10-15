classdef SpectrumSynthesis < matlab.System
%SPECTRUMSYNTHESIS <purpose in one line!>
% -------------------------------------------------------------------------
% <Detailed description of the function>
%
% SpectrumSynthesis Properties:
%	propA - <description>
%	propB - <description>
%
% SpectrumSynthesis Methods:
%	doThis - <description>
%	doThat - <description>
%
% Author :  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date   :  15-Oct-2017 20:51:23
%

% History:  v0.1.0   initial version, 15-Oct-2017 (JA)
%


properties (Nontunable)
    SampleRate;
	Nfft;
    MeanPsd;
end

properties (Logical, Nontunable)
    DoApplyColoration;
end

properties (Access = protected, Dependent)
	NumBins
end



methods
	function [obj] = SpectrumSynthesis(varargin)
        obj.SampleRate = 44.1e3;
        obj.Nfft = 1024;
        obj.DoApplyColoration = true;
        
		obj.setProperties(nargin, varargin{:})
    end
    
    
    function [numBins] = get.NumBins(obj)
        numBins = obj.Nfft / 2 + 1;
    end
end


methods (Access = protected)
	function [noise] = stepImpl(obj)
		uniformPhaseNoise = 2*pi * rand(obj.NumBins, 1) - pi;
        uniformPhaseNoise([1,end],:) = 0;
        
        if obj.DoApplyColoration
            if iscell(obj.MeanPsd)
                meanPsd = freqz(...
                    obj.MeanPsd{1}, ...
                    obj.MeanPsd{2}, ...
                    obj.NumBins, ...
                    obj.SampleRate ...
                    );
                
                meanPsd = abs(meanPsd);
                
            else
                meanPsd = obj.MeanPsd;
                
            end
            
            noise = sqrt(meanPsd) .* exp(1j * uniformPhaseNoise);
            
        else
            noise = exp(1j * uniformPhaseNoise);
        end
	end
end

end





% End of file: SpectrumSynthesis.m
