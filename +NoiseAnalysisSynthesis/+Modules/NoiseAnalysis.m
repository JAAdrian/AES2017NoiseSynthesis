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
    
    DesiredLengthSignalSamples;
    
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
    
	NumFrequencyBands; % Number of modulation bands [default: 16]
end

properties (Logical, Hidden, Nontunable)
	DoHpFilterAnalysis = true;  % Bool whether to apply the HP filter before analysis
end

properties(Nontunable, Logical)
    DoDeClick   = true;
    DoDeCrackle = true;
    DoEstimateClickSpec = true;
end

properties (Access = protected)
    CutOffHP;
    
    ModulationParameters;
end



methods
	function [obj] = NoiseAnalysis(varargin)
        obj.SampleRate = 44.1e3;
        
        obj.NumFrequencyBands = 16;
        obj.CutOffHP = 100;
        
        obj.DesiredLengthSignalSamples = 44.1e3;
        
        obj.NoiseProperties = NoiseAnalysisSynthesis.NoiseProperties();
        obj.ModelParameters = NoiseAnalysisSynthesis.ModelParameters();
        obj.StftParameters  = NoiseAnalysisSynthesis.STFTparams();
        
        obj.SpectrumAnalyzer   = NoiseAnalysisSynthesis.Modules.SpectrumAnalysis();
        obj.AmplitudeAnalyzer  = NoiseAnalysisSynthesis.Modules.AmplitudeAnalysis();
        obj.ModulationAnalyzer = NoiseAnalysisSynthesis.Modules.ModulationAnalysis();
        obj.ClickAnalyzer      = NoiseAnalysisSynthesis.Modules.ClickAnalysis();
        
        obj.Verbose = false;
        
		obj.setProperties(nargin, varargin{:})
    end
end

methods (Access = protected)
    function [] = setupImpl(obj)
        obj.ModulationParameters = NoiseAnalysisSynthesis.STFTparams(...
            obj.ModelParameters.ModulationWinLen,...
            0,...
            obj.StftParameters.FrameRate ...
            );
        
        obj.SpectrumAnalyzer.Signal          = obj.Signal;
        obj.SpectrumAnalyzer.SampleRate      = obj.SampleRate;
        obj.SpectrumAnalyzer.StftParameters  = obj.StftParameters;
        obj.SpectrumAnalyzer.ModelParameters = obj.ModelParameters;
        obj.SpectrumAnalyzer.Verbose         = obj.Verbose;
        
        obj.ModulationAnalyzer.Signal               = obj.Signal;
        obj.ModulationAnalyzer.SampleRate           = obj.SampleRate;
        obj.ModulationAnalyzer.NumFrequencyBands    = obj.NumFrequencyBands;
        obj.ModulationAnalyzer.ModulationParameters = obj.ModulationParameters;
        obj.ModulationAnalyzer.ModelParameters      = obj.ModelParameters;
        obj.ModulationAnalyzer.ModNormFun           = obj.MOD_NORM_FUN;
        obj.ModulationAnalyzer.Verbose              = obj.Verbose;
        
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
            
            obj.NoiseProperties.ClickTransition = obj.ClickAnalyzer.ClickTransition;
            obj.NoiseProperties.SnrClick        = obj.ClickAnalyzer.SnrClick;
            obj.NoiseProperties.LowerEdgeClick  = obj.ClickAnalyzer.LowerEdgeClick;
            obj.NoiseProperties.UpperEdgeClick  = obj.ClickAnalyzer.UpperEdgeClick;
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
        
        obj.NoiseProperties.BandCorrelationMatrix = obj.ModulationAnalyzer.BandCorrelationMatrix;
        obj.NoiseProperties.ModulationDepth       = obj.ModulationAnalyzer.ModulationDepth;
        obj.NoiseProperties.MarkovStateBoundaries = obj.ModulationAnalyzer.StateBoundaries;
        obj.NoiseProperties.MarkovTransition      = obj.ModulationAnalyzer.MarkovTransition;
        
        if nargout
            noiseProperties = obj.NoiseProperties;
        end
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
