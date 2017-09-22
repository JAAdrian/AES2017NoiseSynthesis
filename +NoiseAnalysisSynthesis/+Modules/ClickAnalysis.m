classdef ClickAnalysis < matlab.System
%CLICKANALYSIS <purpose in one line!>
% -------------------------------------------------------------------------
% <Detailed description of the function>
%
% ClickAnalysis Properties:
%	propA - <description>
%	propB - <description>
%
% ClickAnalysis Methods:
%	doThis - <description>
%	doThat - <description>
%
% Author :  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date   :  18-Sep-2017 21:30:16
%

% History:  v0.1.0   initial version, 18-Sep-2017 (JA)
%


properties (Access = public)
    Signal;
	RawSignal;
    ClickSignal;
    
    ThreshDeClick;
end

properties (Logical, Nontunable)
    Verbose;
end

properties (SetAccess = protected)
    LowerEdgeClick;
    UpperEdgeClick;
    
    SnrClick;
    
    ClickTransition;
end

properties (Nontunable)
    SampleRate;
end

properties (Logical)
    DoApplyClicks = true;
    DoEstimateClickSpec = true;
end

properties (Hidden, Logical, Nontunable)
    Verbose;
end



methods
	function [obj] = ClickAnalysis(varargin)
        obj.ThreshDeClick = 0.15;
        
		obj.setProperties(nargin, varargin{:})
    end
end


methods (Access = protected)    
    function [signal] = stepImpl(obj)
        import NoiseAnalysisSynthesis.External.*
        
        % save the raw analysis signal in private property and declick
        % obj.AnalysisSignal
        obj.RawSignal = obj.Signal;
        [obj.Signal, clickPositions] = DeClickNoise(...
            obj.Signal, ...
            obj.SampleRate, ...
            obj.ThreshDeClick ...
            );
        
        obj.ClickSignal = obj.Signal - obj.RawSignal;
        
        if obj.DoApplyClicks && any(obj.ClickSignal) && obj.DoEstimateClickSpec
            obj.estimateClickBandwidth();
        end
        
        obj.SnrClick = snr(obj.Signal, obj.ClickSignal);
        
        obj.ClickTransition = ...
            obj.learnMarkovClickParams(clickPositions);
        
        NoiseAnalysisSynthesis.External.showMsg(obj.Verbose, ...
            sprintf('Error signal energy of (Clicked-DeClicked): %g\n', ...
            norm(obj.RawSignal - obj.Signal)^2) ...
            );

        if nargout
            signal = obj.Signal - obj.ClickSignal;
        end
    end
    
    function [clickTransition] = learnMarkovClickParams(obj, clicks)
        clicksTmp = zeros(size(obj.Signal));
        clicksTmp(clicks) = 1;
        clicks = clicksTmp;
        
        lenClicks = length(clicks);
        
        % 2 states: click or not
        % 1...no click
        % 2... a click
        states = [0 1];
        clickTransition = zeros(length(states));
        for iState = 1:2
            idxCurrEmission = find(clicks == states(iState));
            idxNextEmission = idxCurrEmission + 1;
            idxNextEmission(idxNextEmission > lenClicks) = [];
            
            numToNoClicks = sum(clicks(idxNextEmission) == states(1));
            numToClicks   = sum(clicks(idxNextEmission) == states(2));
            
            clickTransition(iState, :) = ...
                [numToNoClicks numToClicks] / length(idxNextEmission);
        end
        
        % just to be sure that every row sums up to exactly one
        clickTransition = bsxfun(...
            @rdivide, ...
            clickTransition, ...
            sum(clickTransition, 2) ...
            );
    end
    
    function [] = estimateClickBandwidth(obj)
        blocklenSec  = 32e-3;
        overlapRatio = 0.5;
        params       = NoiseAnalysisSynthesis.STFTparams(blocklenSec, overlapRatio, obj.SampleRate);
        stftSignal   = NoiseAnalysisSynthesis.External.STFT(obj.ClickSignal, params);
        
        freq = linspace(0, obj.SampleRate/2, params.Nfft/2+1);
        
        algo.fs   = obj.SampleRate;       % sampling rate
        algo.type = 'fractional-octave';  % type of spectral smoothing
                                          % . 'fractional-octave' or
                                          % . 'fixed-bandwidth'
        
        algo.bandwidth = 1;  % bandwidth
                             % . in octaves for 'fractional-octave'
                             % . in Hz for 'fixed-bandwidth'
        
        algo.L_FFT = params.Nfft;            % length of the DFT
        
        % initialize the smoothing algorithm
        algo = NoiseAnalysisSynthesis.External.SpectralSmoothing.spectralsmoothing_init(algo);
        
        
        thresh   = eps^2;
        cuttOff = [];
        
        idxStart     = 1;
        idxStop      = 1;
        groupShift   = 1;
        counterClick = 1;
        while idxStart + idxStop < size(stftSignal, 2)
            % click start found
            if mean(abs(stftSignal(:, idxStart)).^2) > thresh
                idxStop = 1;
                
                clickGroup(1) = idxStart;
                while ...
                        idxStart + idxStop < size(stftSignal, 2) && ...
                        mean(abs(stftSignal(:, idxStart+idxStop)).^2) > thresh
                    
                    clickGroup(idxStop+1) = idxStart + idxStop; %#ok<AGROW>
                    
                    idxStop = idxStop + 1;
                end
                % click end found
                
                % if the click group is a vector compute the smoothed mean spectrum
                % and estimate the upper cutoff frequency
                if ~isscalar(clickGroup)
                    for iBlock = 1:length(clickGroup)
                        smoothPSD(:, iBlock) = ...
                            NoiseAnalysisSynthesis.External.SpectralSmoothing.spectralsmoothing_process(...
                            abs(stftSignal(:,clickGroup(iBlock))).^2, ...
                            algo ...
                            ); %#ok<AGROW>
                    end
                    meanPSD = mean(smoothPSD,2);
                    
                    cfThresh = prctile(10*log10(meanPSD) + eps^2, 98);
                    cuttOff = [
                        cuttOff; ...
                        freq(find(10*log10(meanPSD + eps^2) >= cfThresh, 1, 'last'))
                        ]; %#ok<AGROW>
                    
                    groupShift  = clickGroup(end) - clickGroup(1) + 1;
                    counterClick = counterClick + 1;
                end
                clickGroup = [];
            end
            
            idxStart = idxStart + groupShift;
            groupShift = 1;
        end
        
        obj.LowerEdgeClick = min(cuttOff);
        obj.UpperEdgeClick = max(cuttOff);
    end
end

end


function [snrValue] = snr(signal, noise)
energySignal = norm(signal);
energyNoise  = norm(noise);

snrValue = 20*log10(energySignal / energyNoise);
end




% End of file: ClickAnalysis.m
