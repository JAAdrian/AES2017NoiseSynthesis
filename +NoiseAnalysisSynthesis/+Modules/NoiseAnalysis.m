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

properties (Nontunable)
	RawSignal;
    SampleRate;
    
    Signal; % Analysis signal (HP filtered and zero-mean)

    ModelParameters;
    NoiseProperties;
    StftParameters;
	
	NumModulationBands; % Number of modulation bands [default: 16]
    
    SpectrumAnalyzer;
    AmplitudeAnalyzer;
    ModulationAnalyzer;
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
        NoiseAnalysisSynthesis.externalshowMsg(obj.Verbose, 'Analyzing Amplitude Distribution');
        amplitudeParameters = obj.AmplitudeAnalyzer();
        
        obj.NoiseProperties.Quantiles = amplitudeParameters.Quantiles;
        obj.NoiseProperties.Cdf       = amplitudeParameters.Cdf;
        
        %% DeCrackle
        if obj.DoDeCrackle
            showMsg(obj, 'DeCrackling Analysis Signal')
            obj.Signal = deCrackleAnalysisSignal(obj.Signal, obj.SampleRate);
        end
        
        %% Mean PSD
        obj.NoiseProperties.MeanPsd = obj.SpectrumAnalyzer();
        
        %% Estimate Modulations
        showMsg(obj, 'Analyzing Modulations');
        obj.ModulationAnalyzer();
    end
    
    
    
    function [] = updateModulationParameters(obj)
        obj.ModulationParamters = NoiseAnalysisSynthesis.STFTparams(...
            obj.ModelParameters.ModulationWinLen,...
            0,...
            obj.StftParameters.FrameRate ...
            );
    end
    
    function [] = deClickAnalysisSignal(obj)
        import NoiseSynthesis.external.*
        
        threshDeClick = 0.15;
        
        % save the raw analysis signal in private property and declick
        % obj.AnalysisSignal
        obj.RawSignal = obj.Signal;
        [obj.Signal, clickPositions] = DeClickNoise(...
            obj.AnalysisSignal, ...
            obj.SampleRate, ...
            threshDeClick ...
            );
        
        clicks = obj.Signal - obj.RawSignal;
        
        if obj.ModelParameters.DoApplyClicks && any(clicks) && obj.DoEstimateClickSpec
            obj.estimateClickBandwidth(clicks);
        end
        
        obj.ModelParameters.SnrClick = snr(obj.Signal, clicks);
        
        obj.learnMarkovClickParams(clickPositions);
        
        showMsg(obj.Verbose, ...
            sprintf('Error signal energy of (Clicked-DeClicked): %g\n', ...
            norm(obj.vOriginalAnalysisSignal - obj.AnalysisSignal)^2) ...
            );
    end
    
    function [snrValue] = snr(signal, noise)
        energySignal = norm(signal);
        energyNoise  = norm(noise);
        
        snrValue = 20*log10(energySignal / energyNoise);
    end
end

end



function [signalDeCrackled] = deCrackleAnalysisSignal(signal, sampleRate)
import NoiseSynthesis.external.*

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
