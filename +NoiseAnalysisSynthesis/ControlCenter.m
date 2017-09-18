classdef ControlCenter < matlab.System
%CONTROLCENTER Class to do analysis and synthesis on noise files
% -------------------------------------------------------------------------
% This class provides means to analyze noise disturbances and synthesize
% new noise signals. This can also be done under a spatial coherence
% constraint. Please see README.md or runDemo.m for examples how to start.
%
% Usage: obj = NoiseAnalysisSynthesis.ControlCenter()
%        obj = NoiseAnalysisSynthesis.ControlCenter(signal, samplingRate)
%
%   Input:   --------------
%           signal: Signal vector of the desired analysis signal
%           samplingRate: sampling frequency in Hz
%
%   Output:  --------------
%           obj: created NoiseAnalysisSynthesis object
%
%
% The toolbox is licensed under BSD-3-clause.
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  23-Feb-2016 14:30:33
%



properties (Access = public, Nontunable)
    SampleRate = 44.1e3; % Sampling rate in Hz [default: 44.1kHz]
    
    DesiredSignalLenSamples = 44100; % Desired synthesis length in samples [default: 1sec -> 44100]
end

properties (Access = public, Logical, Nontunable)
    DoApplyColoration       = true; % Bool whether to apply coloration in the synthesis [default: true]
    DoApplyAmplitudeDistr   = true; % Bool whether to apply an amplitude distribution in the synthesis [default: true]
    DoApplyModulations      = true; % Bool whether to apply modulations in the synthesis [default: true]
    DoApplyComodulation     = true; % Bool whether to apply comodulation in the synthesis [default: true]
    DoApplySpatialCoherence = true; % Bool whether to apply spatial coeherence in the synthesis [default: true]
    
    DoEstimateClickSpec = true; % Bool whether to estimate the click cutoff frequency in the analysis. Dependent on bApplyClicks [default: true]
    
    DoDeClick = true; % Bool whether to declick the analysis file [default: true]
end

properties (SetAccess = protected)
    NoiseProperties; % Parameter object of the noise properties
    ModelParameters; % Parameter object for the noise model
    ErrorMeasures;   % Error measures object
end

properties (Logical, Hidden, Nontunable)
    Verbose = false; % Bool whether to plot verbose information during processing
end

properties (Access = protected, Constant)
    OVERLAP_RATIO  = 0.5; % Fixed overlap for analysis and synthesis
    SOUND_LEVEL_DB = -35; % Default sound level for playback in dB FS
end

properties (Access = protected)
    AnalysisEngine;
    SynthesisEngine;
end

properties (Access = protected, Logical)
    DoAnalysis         = true;
    DoChangeSampleRate = true;
end





    
methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CLASS CONSTRUCTOR
    function obj = ControlCenter(signal, sampleRate)
        obj.ModelParameters = NoiseAnalysisSynthesis.ModelParameters();
        obj.NoiseProperties = NoiseAnalysisSynthesis.NoiseProperties();
        
        obj.ErrorMeasures   = NoiseAnalysisSynthesis.ErrorMeasures();
        
        obj.AnalysisEngine  = NoiseAnalysisSynthesis.Modules.NoiseAnalysis(); 
        obj.SynthesisEngine = NoiseAnalysisSynthesis.Modules.NoiseSynthesis();
        
        % If input arguments are passed -> deal them to the properties
        if nargin
            validateattributes(...
                signal, ...
                {'numeric'}, ...
                {'vector', 'finite', 'nonempty', 'nonsparse'}, ...
                'NoiseAnalysisSynthesis', ...
                'signal', ...
                1 ...
                );
            validateattributes(...
                sampleRate, ...
                {'numeric'}, ...
                {'scalar', 'positive'}, ...
                'NoiseAnalysisSynthesis', ...
                'samplingRate', ...
                2 ...
                );
            
            % make sure signal is a row vector
            signal = shiftdim(signal);
            
            signal = signal - mean(signal);
            obj.SampleRate = sampleRate;
            
            obj.DesiredSignalLenSamples = length(signal);
            
            % Check if FFT size is OK based on sample rate
            stftParameters = obj.setupStftParameters();
            
            obj.DoChangeSampleRate = false;
            
            obj.AnalysisEngine.Signal          = signal;
            obj.AnalysisEngine.SampleRate      = sampleRate;
            obj.AnalysisEngine.StftParameters  = stftParameters;
            obj.AnalysisEngine.ModelParameters = obj.ModelParameters;
        end
    end
    
    function [] = analyze(obj)
        obj.AnalysisEngine.DoDeClick = obj.DoDeClick;
        obj.AnalysisEngine.Verbose = obj.Verbose;
        
        obj.NoiseProperties = obj.AnalysisEngine.step();
    end
    
    
%     function [numSources] = get.NumSources(obj)
%         numSources = size(obj.ModelParameters.SourcePosition, 2);
%     end
%     
%     function [nBands] = get.NumBands(obj)
%         nBands = length(obj.CenterFreqs);
%     end
%     
%     function [nb] = get.NumBins(obj)
%         nb = obj.StftParameters.Nfft/2+1;
%     end
%     
%     function [nb] = get.NumBlocks(obj)
%         nb = computeNumberOfBlocks(obj.StftParameters, obj.DesiredSignalLenSamples);
%     end
%     
%     function [nb] = get.LenLevelCurve(obj)
%         nb = ceil((obj.NumBlocks - obj.ModulationParams.Overlap)...
%             / obj.ModulationParams.Frameshift);
%     end
%     
%     function [len] = get.LenLevelCurvePlot(obj)
%         len = min(obj.LenLevelCurve, size(obj.LevelCurves, 1));
%     end
%     
%     function [len] = get.LenSignalPlotAudio(obj)
%         if ~isempty(obj.AnalysisSignal)
%             len = min(...
%                 obj.DesiredSignalLenSamples, ...
%                 min(length(obj.AnalysisSignal), obj.DesiredSignalLenSamples) ...
%                 );
%         else
%             len = obj.DesiredSignalLenSamples;
%         end
%     end
%     
%     function [] = set.DesiredSignalLenSamples(obj, lenSamples)
%         validateattributes(...
%             lenSamples, ...
%             {'numeric'}, ...
%             {'nonzero', 'nonnegative'});
%         
%         obj.DesiredSignalLenSamples = lenSamples;
%         
%         obj.StftParameters.OriginalSignalLength = lenSamples;
%     end
%     
%     function [] = set.SampleRate(obj, sampleRate)
%         if ~obj.DoChangeSampleRate
%             error(['At the moment, you cannot change the sampling rate ', ...
%                 'when an analysis signal has been used!']);
%         else
%             validateattributes(...
%                 sampleRate, ...
%                 {'numeric'}, ...
%                 {'scalar', 'integer', 'positive', 'nonnan', 'real', ...
%                  '>=', 16e3, '<=', 48e3}...
%                 );
%             
%             obj.SampleRate = sampleRate;
%         end
%     end
end

methods (Hidden)
    function [] = applyChangedModel(obj, ~, eventData)
        flushParameters(obj);
        
        readParameters(obj, eventData.Source.Model);
    end
end


methods (Access = protected)
    function [] = setupImpl(obj)
        if obj.DoAnalysis
            obj.analyze();
        end
    end
    
    function [] = resetImpl(obj)
        obj.flushParameters();
    end
    
    function [sensorSignalsOut] = stepImpl(obj)
        if nargout
            sensorSignalsOut = obj.synthesize();
        else
            obj.synthesize();
        end
    end
    
    function [] = releaseImpl(obj)
        obj.AnalysisEngine.release();
        obj.SynthesisEngine.release();
    end
    
    
    
    function [stftParameters] = setupStftParameters(obj)
        blocklenSamples = 1024;
        
        if obj.SampleRate < 16e3 && obj.SampleRate >= 8e3
            blocklenSamples = 256;
        end
        
        if obj.SampleRate < 44.1e3 && obj.SampleRate >= 16e3
            blocklenSamples = 512;
        end
        
        if obj.SampleRate > 48e3
            blocklenSamples = 2048;
        end
        
        stftParameters = NoiseAnalysisSynthesis.STFTparams(...
            blocklenSamples / obj.SampleRate, ...
            obj.OVERLAP_RATIO, ...
            obj.SampleRate, ...
            'synthesis' ...
            );
        stftParameters.OriginalSignalLength = obj.DesiredSignalLenSamples;
    end
end

end







% End of file: ControlCenter.m
