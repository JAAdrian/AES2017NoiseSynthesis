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


properties (Access = public)
    SampleRate = 44.1e3; % Sampling rate in Hz [default: 44.1kHz]
    
    DesiredSignalLenSamples = 44100; % Desired synthesis length in samples [default: 1sec -> 44100]
end

properties (Logical)
    DoApplyColoration       = true; % Bool whether to apply coloration in the synthesis [default: true]
    DoApplyAmplitudeDistr   = true; % Bool whether to apply an amplitude distribution in the synthesis [default: true]
    DoApplyModulations      = true; % Bool whether to apply modulations in the synthesis [default: true]
    DoApplyComodulation     = true; % Bool whether to apply comodulation in the synthesis [default: true]
    DoApplySpatialCoherence = true; % Bool whether to apply spatial coeherence in the synthesis [default: true]
    
    DoEstimateClickSpec = true; % Bool whether to estimate the click cutoff frequency in the analysis. Dependent on bApplyClicks [default: true]
    
    DoDeClick = true; % Bool whether to declick the analysis file [default: true]
end

properties (SetAccess = private)
    AnalysisSignal; % Analysis signal (HP filtered and zero-mean)
    SensorSignals = []; % Final sensor signals after synthesis
    ClickTracks   = {}; % Click track if desired (which is also already added to SensorSignals)
    
    ModelParameters; % Parameter object for the noise model
    ErrorMeasures;   % Error measures object
    
    GammatoneLowestBand  = 64; % Lowest center freq. if Gammatone FB is desired [default: 64Hz]
    GammatoneHighestBand = 16e3; % Highestapply center freq. if Gammatone FB is desired [default: 16kHz]
    NumModulationBands   = 16; % Number of modulation bands [default: 16]
    
    CutOffHP = 100; % Cutoff frequency of the HP filter applied to the analysis signal
end

properties (Logical, Hidden)
    Verbose            = false; % Bool whether to plot verbose information during processing
    DoHpFilterAnalysis = true;  % Bool whether to apply the HP filter before analysis
end

properties (SetAccess = private, Dependent)
    NumSensorSignals; % Number of desired sensor signals (dependent on size of the sensor position matrix)
    NumSources; % Number of acoustic sources in the noise field ((dependent on size of the sources position matrix))
end

properties (Access = private, Constant)
    SoundVelocity = 343; % Velocity of sound
    OverlapRatio  = 0.5; % Fixed overlap for analysis and synthesis
    ModNormFun    = @(x) mad(x, 1, 1); % Normalization function for level fluctuations
    SoundLeveldB  = -35; % Default sound level for playback in dB FS
end

properties (Access = private)
    OriginalAnalysisSignal;    % Raw analysis signal
    BeforeDeCrackling;
    
    FrequencyBands; % Frequency bands
    LevelCurvesDecorr; % Decorrelated level fluctuations for all bands
    
    Blocklen = 1024; % Block length for STFT
    StftParameters;  % Parameter object for the STFT
    ModulationParams; % Parameter object for the modulations
end

properties (Access = private, Dependent)
    CenterFreqs; % Center frequencies of either the Mel or Gammatone FB
    NumBands; % Number of frequency bands
    LenLevelCurve; % Length of the RMS level fluctuations curve
    NumBlocks; % Number of signal blocks with chosen STFT parameters
    NumBins; % Number of DFT bins with chosen STFT parameters
    NumStates; % Number of Markov states
    LenLevelCurvePlot; % Length of the RMS level fluctuations curve for plotting purposes
    LenSignalPlotAudio; % Length of the signal in samples for plotting and playback purposes
end

properties (Access = private, Logical)
    DoAnalysis = true;
    DoChangeSampleRate = true;
end

properties (Access = private, Transient)
    SensorDistances; % Distances between sensors
end

properties (Access = ?NoiseSynthesis.ErrorMeasures)
    Theta; % Angles between sources and sensors
    LevelCurves; % Level curves of all bands
    ArtificialLevelCurves; % Generated level curves for all bands
end

properties (Access = ?NoiseSynthesis.ErrorMeasures, Dependent)
    CohereFun; % Function handle to the desired coherence model
end



    
methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CLASS CONSTRUCTOR
    function obj = NoiseAnalysisSynthesis(signal, sampleRate)
        % Create auxiliary objects
        obj.StftParameters = NoiseSynthesis.STFTparams(...
            obj.Blocklen/obj.SampleRate,...
            obj.OverlapRatio,...
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
            
            obj.DoNotChangeSampleRate = true;
        end
        
        obj.ModelParameters = NoiseSynthesis.ModelParametersSet();
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
    function [freqs] = get.CenterFreqs(obj)
        numBands = obj.NumModulationBands;
        
        freqs = erbscale2freq(...
            linspace(...
            freq2erbscale(obj.GammatoneLowestBand),...
            freq2erbscale(obj.GammatoneHighestBand),...
            numBands)...
            );
    end
    
    function [numSens] = get.NumSensorSignals(obj)
        if obj.DoApplySpatialCoherence
            numSens = size(obj.ModelParameters.SensorPositions, 2);
        else
            numSens = 1;
        end
    end
    
    function [numSources] = get.NumSources(obj)
        numSources = size(obj.ModelParameters.SourcePosition,2);
    end
    
    function CohereFun = get.CohereFun(obj)
        switch lower(obj.ModelParameters.CohereModel)
            case 'cylindrical'
                % zeroth order bessel of first kind
                CohereFun = @(freq, dist, theta, vPSD) besselj(0, 2*pi * freq * dist / obj.SoundVelocity);
            case 'spherical'
                CohereFun = @(freq, dist, theta, vPSD) sinc(2 * freq * dist / obj.SoundVelocity);
            case 'anisotropic'
                CohereFun = @(freq, dist, theta, vPSD) anisotropicCoherence(obj, freq, dist, theta, vPSD);
            case 'binaural2d'
                CohereFun = @(freq, dist, theta, vPSD) binaural2d(obj, dist, freq);
            case 'binaural3d'
                CohereFun = @(freq, dist, theta, vPSD) binaural3d(obj, dist, freq);
            otherwise
                warning(sprintf('Coherence model not recognized. Switched to default (''%s'')...',...
                    obj.ModelParameters.CohereModel)); %#ok<SPWRN>
        end
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
    
    function [ns] = get.NumStates(obj)
        ns = size(obj.ModelParameters.MarkovStateBoundaries, 1);
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
        if obj.DoNotChangeSampleRate
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
    
    function [block] = stepImpl(obj)
        
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

% Auxiliary functions to transform linear frequency scale to ERB scale and
% vice versa
function freq = erbscale2freq(erb)
freq = 1000/4.37 * (10.^(erb/21.4) - 1);
end

function erb = freq2erbscale(freq)
erb = 21.4 * log10(1 + freq/1000 * 4.37);
end





% End of file: NoiseAnalysisSynthesis.m
