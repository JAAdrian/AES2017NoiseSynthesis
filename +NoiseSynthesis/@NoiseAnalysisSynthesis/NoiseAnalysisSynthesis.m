classdef NoiseAnalysisSynthesis < matlab.System
%NOISEANALYSISSYNTHESIS Class to do analysis and synthesis on noise files
% -------------------------------------------------------------------------
% This class provides means to analyze noise disturbances and synthesize
% new noise signals. This can also be done under a spatial coherence
% constraint. Please see README.md or runDemo.m for examples how to start.
%
% Usage: obj = NoiseSynthesis.NoiseAnalysisSynthesis()
%        obj = NoiseSynthesis.NoiseAnalysisSynthesis(signal, samplingRate)
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


properties (Nontunable)
    SampleRate = 44.1e3; % Sampling rate in Hz [default: 44.1kHz]
    
    DesiredSignalLenSamples = 44100; % Desired synthesis length in samples [default: 1sec -> 44100]
end

properties (Logical, Nontunable)
    DoApplyColoration       = true; % Bool whether to apply coloration in the synthesis [default: true]
    DoApplyAmplitudeDistr   = true; % Bool whether to apply an amplitude distribution in the synthesis [default: true]
    DoApplyModulations      = true; % Bool whether to apply modulations in the synthesis [default: true]
    DoApplyComodulation     = true; % Bool whether to apply comodulation in the synthesis [default: true]
    DoApplySpatialCoherence = true; % Bool whether to apply spatial coeherence in the synthesis [default: true]
    
    DoEstimateClickSpec = true; % Bool whether to estimate the click cutoff frequency in the analysis. Dependent on bApplyClicks [default: true]
    
    DoDeClick = true; % Bool whether to declick the analysis file [default: true]
end

properties (SetAccess = protected)
    ModelParameters; % Parameter object for the noise model
    ErrorMeasures;   % Error measures object
end

properties (Logical, Hidden, Nontunable)
    Verbose = false; % Bool whether to plot verbose information during processing
end

properties (Dependent)
    NumSources; % Number of acoustic sources in the noise field ((dependent on size of the sources position matrix))
end

properties (Access = private, Constant)
    SOUND_VELOCITY = 343; % Velocity of sound
    OVERLAP_RATIO  = 0.5; % Fixed overlap for analysis and synthesis
    MOD_NORM_FUN   = @(x) mad(x, 1, 1); % Normalization function for level fluctuations
    SOUND_LEVEL_DB = -35; % Default sound level for playback in dB FS
end

properties (Access = protected)
    FrequencyBands; % Frequency bands
    LevelCurvesDecorr; % Decorrelated level fluctuations for all bands
    
    Blocklen = 1024; % Block length for STFT
    StftParameters;  % Parameter object for the STFT
    ModulationParams; % Parameter object for the modulations
end

properties (Access = protected, Dependent)
    NumBands; % Number of frequency bands
    LenLevelCurve; % Length of the RMS level fluctuations curve
    NumBlocks; % Number of signal blocks with chosen STFT parameters
    NumBins; % Number of DFT bins with chosen STFT parameters
    
    LenLevelCurvePlot; % Length of the RMS level fluctuations curve for plotting purposes
    LenSignalPlotAudio; % Length of the signal in samples for plotting and playback purposes
end

properties (Access = protected, Logical)
    DoAnalysis = true;
    DoChangeSampleRate = true;
end





    
methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CLASS CONSTRUCTOR
    function obj = NoiseAnalysisSynthesis(signal, sampleRate)
        % Create auxiliary objects
        obj.StftParameters = NoiseSynthesis.STFTparams(...
            obj.Blocklen/obj.SampleRate,...
            obj.OVERLAP_RATIO,...
            obj.SampleRate,...
            'synthesis');
        obj.StftParameters.OriginalSignalLength = obj.DesiredSignalLenSamples;
        
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
            
            obj.AnalysisSignal = signal - mean(signal);
            obj.SampleRate     = sampleRate;
            
            obj.DesiredSignalLenSamples = length(signal);
            
            % Check if FFT size is OK based on sample rate
            checkFFTlength(obj);
            
            obj.DoChangeSampleRate = false;
        end
        
        obj.ModelParameters = NoiseSynthesis.ModelParameters();
        obj.ErrorMeasures   = NoiseSynthesis.ErrorMeasures(obj);
        
        % Based on current parameters create the modulation parameter
        % object
        updateModulationParameters(obj);
        
        % Initialize angles between source(s) and sensor(s)
        obj.Theta = pi/2 * ones(obj.NumSensorSignals);
        
        % Initialize Markov modulation states
        updateMarkovParams(obj, -12, 12);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%% Public methods %%%%%%%%%%%%%%%%%%%
    [] = analyze(obj);
    [SensorSignalsOut] = synthesize(obj);
    
    [] = saveSignals(obj, szSaveFilename, bStereo, bRandPhase, szExt);
    
    [] = sound(obj,leveldB,bStereo);
    [] = soundsc(obj,bStereo);
    
    [] = playAnalyzed(obj,leveldB);
    [] = playSynthesized(obj,leveldB,bStereo);
    
    [] = plot(obj,bSave,szSavePath,szPlotProfile);

    [] = saveParameters(obj,szFilename);
    
    [] = flushParameters(obj);
    [] = readParameters(obj,szFilename);
    
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%% setter/getter methods %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    
    
    function [numSources] = get.NumSources(obj)
        numSources = size(obj.ModelParameters.SourcePosition, 2);
    end
    
    function [nBands] = get.NumBands(obj)
        nBands = length(obj.CenterFreqs);
    end
    
    function [nb] = get.NumBins(obj)
        nb = obj.StftParameters.Nfft/2+1;
    end
    
    function [nb] = get.NumBlocks(obj)
        nb = computeNumberOfBlocks(obj.StftParameters, obj.DesiredSignalLenSamples);
    end
    
    function [nb] = get.LenLevelCurve(obj)
        nb = ceil((obj.NumBlocks - obj.ModulationParams.Overlap)...
            / obj.ModulationParams.Frameshift);
    end
    
    function [len] = get.LenLevelCurvePlot(obj)
        len = min(obj.LenLevelCurve, size(obj.LevelCurves, 1));
    end
    
    function [len] = get.LenSignalPlotAudio(obj)
        if ~isempty(obj.AnalysisSignal)
            len = min(...
                obj.DesiredSignalLenSamples, ...
                min(length(obj.AnalysisSignal), obj.DesiredSignalLenSamples) ...
                );
        else
            len = obj.DesiredSignalLenSamples;
        end
    end
    
    function [] = set.DesiredSignalLenSamples(obj, lenSamples)
        validateattributes(...
            lenSamples, ...
            {'numeric'}, ...
            {'nonzero', 'nonnegative'});
        
        obj.DesiredSignalLenSamples = lenSamples;
        
        obj.StftParameters.OriginalSignalLength = lenSamples;
    end
    
    function [] = set.SampleRate(obj, sampleRate)
        if ~obj.DoChangeSampleRate
            error(['At the moment, you cannot change the sampling rate ', ...
                'when an analysis signal has been used!']);
        else
            validateattributes(...
                sampleRate, ...
                {'numeric'}, ...
                {'scalar', 'integer', 'positive', 'nonnan', 'real', ...
                 '>=', 16e3, '<=', 48e3}...
                );
            
            obj.SampleRate = sampleRate;
        end
    end
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
end
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
methods (Access = private)
    [] = DeClickAnalysisSignal(obj);
    [] = learnMarkovClickParams(obj,vClicks);
    
    [] = AnalysisFilterbank(obj,vSigIn);
    [vTimeSignal] = SynthesisFilterbank(obj);
    
    [] = GammatoneApprox(obj);
    [] = MelTransformation(obj);
    [mTransform] = STFTGammatone(obj);
    [mTransformation] = MelMatrix(obj);
    
    [] = analyzeAmplitudeDistribution(obj);
    
    [] = analyzeModulations(obj);
    [] = computeLevelFluctuations(obj);
    [] = learnMarkovModulationParams(obj);
    [] = updateMarkovParams(obj,minVal,maxVal);
    
    [] = analyzeMeanBandPower(obj);
    
    [] = analyzeCorrelationBands(obj);
    [] = decorrelateLevelFluctuations(obj);
    [] = analyzeModulationDepth(obj);
    
    [] = applyModulations(obj);
    [] = computeArtificialModulations(obj);
    
    [] = applyAmplitudeDistribution(obj);
    [vSigOut] = shapeAmplitudeDistr(obj,vSigIn);
    
    [] = mixNoiseAndClicks(obj);
    
    [vNoise] = generateNoise(obj,iNoiseMode);
    [] = generateCoherentNoise(obj);
    [] = generateIncoherentNoise(obj);
    
    [] = generateIncoherentClicks(obj);
    [] = generateCoherentClicks(obj);
    
    [] = computeSensorDistances(obj);
    [] = computeTheta(obj);
    [mMixingMatrix] = computeMixingMatrix(obj,Freq,SourcePSDbin);
    [mFreqNoiseMix] = mixSignals(obj,caSTFTNoise,bComputePSD);
    [mGamma] = computeBandCorrelation(mBands);
    [vCohere] = binaural2d(obj,dist,vFreqDesired);
    [vCohere] = binaural3d(obj,dist,vFreqDesired);
    
    [] = generateLevelCurves(obj);
    
    [] = mixBands(obj);
    [] = normalizeBands(obj);
    [mMixingMatrix] = computeBandMixingMatrix(mGamma);
    
    [] = generateGaussBands(obj);
    [] = generateMarkovBands(obj);
    [vModulationCurve] = genmarkov(obj,idxBand);
    
    [] = checkFFTlength(obj);
    
    [mClickSTFT] = genArtificialClicks(obj);
    [vClicks] = genclickmarkov(obj);
    
    [vCohere] = anisotropicCoherence(obj,vFreq,dist,theta,mPSD);
    
    [vCDF, vQuantiles] = PiecewiseParetoCDF(obj,numPoints);
    [vPDF, vQuantiles] = PiecewiseParetoPDF(obj,numPoints);
    [vSigmoid] = sigmoidfun(x,x0,alpha);
    
    [] = updateModulationParameters(obj);
    
    [] = showMsg(obj,szMessage);
    [x,y] = makeCDFrobust(x,y);
    
    [rms] = rms(mSignal,dim);
end

end







% End of file: NoiseAnalysisSynthesis.m
