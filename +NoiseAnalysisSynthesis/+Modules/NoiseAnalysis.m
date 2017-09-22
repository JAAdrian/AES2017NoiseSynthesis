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
    
    ModelParameters;
    NoiseProperties;
    StftParameters;
    
    SpectrumAnalyzer;
    AmplitudeAnalyzer;
    ModulationAnalyzer;
    ClickAnalyzer;
end

properties (Logical, Nontunable)
    Verbose;
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
    DoEstimateClickSpec = true;
end

properties (Access = protected)
    CutOffHP;
    
    ModulationParamters;
end



methods
	function [obj] = NoiseAnalysis(varargin)
        obj.NumModulationBands = 16;
        obj.CutOffHP = 100;
        
        obj.NoiseProperties = NoiseAnalysisSynthesis.NoiseProperties();
        
        obj.SpectrumAnalyzer   = NoiseAnalysisSynthesis.Modules.SpectrumAnalysis();
        obj.AmplitudeAnalyzer  = NoiseAnalysisSynthesis.Modules.AmplitudeAnalysis();
        obj.ModulationAnalyzer = NoiseAnalysisSynthesis.Modules.ModulationAnalysis();
        obj.ClickAnalyzer      = NoiseAnalysisSynthesis.Modules.ClickAnalysis();
        
        obj.Verbose = false;
        
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
        
        obj.ClickAnalyzer.SampleRate = obj.SampleRate;
        obj.ClickAnalyzer.Signal     = obj.Signal;
        obj.ClickAnalyzer.Verbose    = obj.Verbose;
    end
    
    function [noiseProperties] = stepImpl(obj)
        %% Pre-Processing
        % declick the analysis signal if desired
        if obj.DoDeClick
            NoiseAnalysisSynthesis.External.showMsg(obj.Verbose, 'DeClicking Analysis Signal');
            obj.Signal = obj.ClickAnalyzer();
        end
        
        % HP filter if desired (true by default)
        if obj.DoHpFilterAnalysis
            [b, a] = butter(2, obj.CutOffHP*2/obj.SampleRate, 'high');
            obj.Signal = filter(b, a, obj.Signal);
        end
        
        %% Estimate Amplitude Distribution
        NoiseAnalysisSynthesis.External.showMsg(...
            obj.Verbose, 'Analyzing Amplitude Distribution' ...
            );
        amplitudeParameters = obj.AmplitudeAnalyzer(obj.Signal);
        
        obj.NoiseProperties.Quantiles = amplitudeParameters.Quantiles;
        obj.NoiseProperties.Cdf       = amplitudeParameters.Cdf;
        
        %% DeCrackle
        if obj.DoDeCrackle
            NoiseAnalysisSynthesis.External.showMsg(obj.Verbose, 'DeCrackling Analysis Signal')
            obj.Signal = deCrackleAnalysisSignal(obj.Signal, obj.SampleRate);
        end
        
        %% Mean PSD
        obj.SpectrumAnalyzer.Signal = obj.Signal;
        obj.NoiseProperties.MeanPsd = obj.SpectrumAnalyzer();
        
        %% Estimate Modulations
        NoiseAnalysisSynthesis.External.showMsg(obj.Verbose, 'Analyzing Modulations');
        obj.ModulationAnalyzer(obj.SpectrumAnalyzer.FrequencyBands);
        
        obj.NoiseProperties.BandCorrelation       = obj.ModulationAnalyzer.BandCorrelation;
        obj.NoiseProperties.ModulationDepth       = obj.ModulationAnalyzer.ModulationDepth;
        obj.NoiseProperties.MarkovStateBoundaries = obj.ModulationAnalyzer.MarkoveStateBoundaries;
        obj.NoiseProperties.MarkovTransition      = obj.ModulationAnalyzer.MarkovTransition;
        
        if nargout
            noiseProperties = obj.NoiseProperties;
        end
    end
    
    
    
    function [] = updateModulationParameters(obj)
        obj.ModulationParamters = NoiseAnalysisSynthesis.STFTparams(...
            obj.ModelParameters.ModulationWinLen,...
            0,...
            obj.StftParameters.FrameRate ...
            );
    end
end

end



function [signalDeCrackled] = deCrackleAnalysisSignal(signal, sampleRate)
import NoiseAnalysisSynthesis.External.*

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
