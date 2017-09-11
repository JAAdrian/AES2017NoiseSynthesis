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



properties (Constant)
    MOD_NORM_FUN = @(x) mad(x, 1, 1);
end

properties (Access = public)
    Signal; % Analysis signal (HP filtered and zero-mean)
    RawSignal;
    
    ModelParameters;
    NoiseProperties;
    StftParameters;
    
    SpectrumAnalyzer;
    AmplitudeAnalyzer;
    ModulationAnalyzer;
end

properties (Nontunable)
    SampleRate;
    
	NumModulationBands; % Number of modulation bands [default: 16]
end

properties (Dependent)
end

properties (Logical, Hidden, Nontunable)
	DoHpFilterAnalysis = true;  % Bool whether to apply the HP filter before analysis
    Verbose = false;
end

properties(Nontunable, Logical)
    DoDeClick   = true;
    DoDeCrackle = true;
end

properties (Access = protected)
    CutOffHP;
    
    ModulationParamters;
end



methods
	function [obj] = NoiseAnalysis(varargin)
        obj.NumModulationBands = 16;
        obj.CutOffHP = 100;
        
        obj.SpectrumAnalyzer   = NoiseAnalysisSynthesis.Modules.SpectrumAnalysis();
        obj.AmplitudeAnalyzer  = NoiseAnalysisSynthesis.Modules.AmplitudeAnalysis();
        obj.ModulationAnalyzer = NoiseAnalysisSynthesis.Modules.ModulationAnalysis();
        
		obj.setProperties(nargin, varargin{:})
    end
	
% 	function [ns] = get.NumStates(obj)
%         ns = size(obj.ModelParameters.MarkovStateBoundaries, 1);
%     end
end

methods (Access = protected)
    function [] = setupImpl(obj)
        obj.SpectrumAnalyzer.Signal          = obj.Signal;
        obj.SpectrumAnalyzer.SampleRate      = obj.SampleRate;
        obj.SpectrumAnalyzer.StftParameters  = obj.StftParameters;
        obj.SpectrumAnalyzer.ModelParameters = obj.ModelParameters;
        
        obj.updateModulationParameters();
        
        obj.ModulationAnalyzer.Signal               = obj.Signal;
        obj.ModulationAnalyzer.SampleRate           = obj.SampleRate;
        obj.ModulationAnalyzer.NumModulationBands   = obj.NumModulationBands;
        obj.ModulationAnalyzer.ModulationParameters = obj.ModulationParamters;
        obj.ModulationAnalyzer.ModelParameters      = obj.ModelParameters;
        obj.ModulationAnalyzer.ModNormFun           = obj.MOD_NORM_FUN;
    end
    
    function [] = stepImpl(obj)
        %% Pre-Processing
        % declick the analysis signal if desired
        if obj.DoDeClick
            NoiseAnalysisSynthesis.external.showMsg(obj.Verbose, 'DeClicking Analysis Signal');
            obj.deClickAnalysisSignal();
        end
        
        % HP filter if desired (true by default)
        if obj.DoHpFilterAnalysis
            [b, a] = butter(2, obj.CutOffHP*2/obj.SampleRate, 'high');
            obj.Signal = filter(b, a, obj.Signal);
        end
        
        %% Estimate Amplitude Distribution
        NoiseAnalysisSynthesis.external.showMsg(...
            obj.Verbose, 'Analyzing Amplitude Distribution' ...
            );
        amplitudeParameters = obj.AmplitudeAnalyzer(obj.Signal);
        
        obj.NoiseProperties.Quantiles = amplitudeParameters.Quantiles;
        obj.NoiseProperties.Cdf       = amplitudeParameters.Cdf;
        
        %% DeCrackle
        if obj.DoDeCrackle
            NoiseAnalysisSynthesis.external.showMsg(obj.Verbose, 'DeCrackling Analysis Signal')
            obj.Signal = deCrackleAnalysisSignal(obj.Signal, obj.SampleRate);
        end
        
        %% Mean PSD
        obj.NoiseProperties.MeanPsd = obj.SpectrumAnalyzer();
        
        %% Estimate Modulations
        NoiseAnalysisSynthesis.external.showMsg(obj.Verbose, 'Analyzing Modulations');
        obj.ModulationAnalyzer(obj.SpectrumAnalyzer.FrequencyBands);
    end
    
    
    
    function [] = updateModulationParameters(obj)
        obj.ModulationParamters = NoiseAnalysisSynthesis.STFTparams(...
            obj.ModelParameters.ModulationWinLen,...
            0,...
            obj.StftParameters.FrameRate ...
            );
    end
    
    function [] = deClickAnalysisSignal(obj)
        import NoiseAnalysisSynthesis.external.*
        
        threshDeClick = 0.15;
        
        % save the raw analysis signal in private property and declick
        % obj.AnalysisSignal
        obj.RawSignal = obj.Signal;
        [obj.Signal, clickPositions] = DeClickNoise(...
            obj.Signal, ...
            obj.SampleRate, ...
            threshDeClick ...
            );
        
        clicks = obj.Signal - obj.RawSignal;
        
        if obj.ModelParameters.DoApplyClicks && any(clicks) && obj.DoEstimateClickSpec
            obj.estimateClickBandwidth(clicks);
        end
        
        obj.ModelParameters.SnrClick = snr(obj.Signal, clicks);
        
        obj.ModelParameters.ClickTransition = ...
            obj.learnMarkovClickParams(clickPositions);
        
        showMsg(obj.Verbose, ...
            sprintf('Error signal energy of (Clicked-DeClicked): %g\n', ...
            norm(obj.RawSignal - obj.Signal)^2) ...
            );
    end
    
    function [snrValue] = snr(signal, noise)
        energySignal = norm(signal);
        energyNoise  = norm(noise);
        
        snrValue = 20*log10(energySignal / energyNoise);
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
end

end



function [signalDeCrackled] = deCrackleAnalysisSignal(signal, sampleRate)
import NoiseAnalysisSynthesis.external.*

rmsOriginal = std(signal);

threshold = 90;

signalDeCrackled = DeCrackleNoise(...
    signal, ...
    sampleRate, ...
    threshold ...
    );

% adjust level
signalDeCrackled = signalDeCrackled / std(signalDeCrackled) * rmsOriginal;
end


% End of file: NoiseAnalysis.m
