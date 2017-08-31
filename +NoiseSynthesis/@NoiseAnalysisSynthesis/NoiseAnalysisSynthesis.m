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
    bApplyColoration       = true; % Bool whether to apply coloration in the synthesis [default: true]
    bApplyAmplitudeDistr   = true; % Bool whether to apply an amplitude distribution in the synthesis [default: true]
    bApplyModulations      = true; % Bool whether to apply modulations in the synthesis [default: true]
    bApplyComodulation     = true; % Bool whether to apply comodulation in the synthesis [default: true]
    bApplySpatialCoherence = true; % Bool whether to apply spatial coeherence in the synthesis [default: true]
    
    bEstimateClickSpec = true; % Bool whether to estimate the click cutoff frequency in the analysis. Dependent on bApplyClicks [default: true]
    
    bDeClick = true; % Bool whether to declick the analysis file [default: true]
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
    bVerbose          = false; % Bool whether to plot verbose information during processing
    bHPFilterAnalysis = true;  % Bool whether to apply the HP filter before analysis
end

properties (SetAccess = private, Dependent)
    NumSensorSignals; % Number of desired sensor signals (dependent on size of the sensor position matrix)
    NumSources; % Number of acoustic sources in the noise field ((dependent on size of the sources position matrix))
end

properties (Access = private, Constant)
    SoundVelocity = 343; % Velocity of sound
    overlapRatio  = 0.5; % Fixed overlap for analysis and synthesis
    hModNormFun   = @(x) mad(x, 1, 1); % Normalization function for level fluctuations
    soundLeveldB  = -35; % Default sound level for playback in dB FS
end

properties (Access = private)
    vOriginalAnalysisSignal;    % Raw analysis signal
    vBeforeDeCrackling;
    
    mBands; % Frequency bands
    mLevelCurvesDecorr; % Decorrelated level fluctuations for all bands
    
    blocklen = 1024; % Block length for STFT
    STFTParameters;  % Parameter object for the STFT
    ModulationParams; % Parameter object for the modulations
    
    bDoNotChangeSampleRate = false;
end

properties (Access = private, Dependent)
    vCenterFreqs; % Center frequencies of either the Mel or Gammatone FB
    numBands; % Number of frequency bands
    lenLevelCurve; % Length of the RMS level fluctuations curve
    numBlocks; % Number of signal blocks with chosen STFT parameters
    numBins; % Number of DFT bins with chosen STFT parameters
    numStates; % Number of Markov states
    lenLevelCurvePlot; % Length of the RMS level fluctuations curve for plotting purposes
    lenSignalPlotAudio; % Length of the signal in samples for plotting and playback purposes
end

properties (Access = private, Transient)
    mDistances; % Distances between sensors
end

properties (Access = ?NoiseSynthesis.ErrorMeasures)
    mTheta; % Angles between sources and sensors
    mLevelCurves; % Level curves of all bands
    mArtificialLevelCurves; % Generated level curves for all bands
end

properties (Access = ?NoiseSynthesis.ErrorMeasures, Dependent)
    hCohereFun; % Function handle to the desired coherence model
end



    
methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CLASS CONSTRUCTOR
    function obj = NoiseAnalysisSynthesis(signal, samplingRate)
        % Create auxiliary objects
        obj.STFTParameters = NoiseSynthesis.STFTparams(...
            obj.blocklen/obj.SampleRate,...
            obj.overlapRatio,...
            obj.SampleRate,...
            'synthesis');
        obj.STFTParameters.OriginalSignalLength = obj.DesiredSignalLenSamples;
        
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
                samplingRate, ...
                {'numeric'}, ...
                {'scalar', 'positive'}, ...
                'NoiseAnalysisSynthesis', ...
                'samplingRate', ...
                2 ...
                );
            
            % make sure signal is a row vector
            signal = shiftdim(signal);
            
            obj.AnalysisSignal = signal - mean(signal);
            obj.SampleRate     = samplingRate;
            
            obj.DesiredSignalLenSamples = length(signal);
            
            % Check if FFT size is OK based on sample rate
            checkFFTlength(obj);
            
            obj.bDoNotChangeSampleRate = true;
        end
        
        obj.ModelParameters = NoiseSynthesis.ModelParametersSet();
        obj.ErrorMeasures   = NoiseSynthesis.ErrorMeasures(obj);
        
        % Based on current parameters create the modulation parameter
        % object
        updateModulationParameters(obj);
        
        % Initialize angles between source(s) and sensor(s)
        obj.mTheta = pi/2 * ones(obj.NumSensorSignals);
        
        % Initialize Markov modulation states
        updateMarkovParams(obj, -12,12);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%% Public methods %%%%%%%%%%%%%%%%%%%
    
    [] = analyze(obj);
    [SensorSignalsOut] = synthesize(obj);
    
    [] = saveSignals(obj,szSaveFilename,bStereo,bRandPhase,szExt);
    
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
    function [vFreqs] = get.vCenterFreqs(obj)
        numBands = obj.NumModulationBands; %#ok<PROP>
        
        vFreqs = erbscale2freq(...
            linspace(...
            freq2erbscale(obj.GammatoneLowestBand),...
            freq2erbscale(obj.GammatoneHighestBand),...
            numBands)...
            ); %#ok<PROP>
    end
    
    function [numSens] = get.NumSensorSignals(obj)
        if obj.bApplySpatialCoherence
            numSens = size(obj.ModelParameters.SensorPositions,2);
        else
            numSens = 1;
        end
    end
    
    function [numSources] = get.NumSources(obj)
        numSources = size(obj.ModelParameters.SourcePosition,2);
    end
    
    function hCohereFun = get.hCohereFun(obj)
        switch lower(obj.ModelParameters.CohereModel)
            case 'cylindrical'
                % zeroth order bessel of first kind
                hCohereFun = @(freq, dist, theta, vPSD) besselj(0, 2*pi * freq * dist / obj.SoundVelocity);
            case 'spherical'
                hCohereFun = @(freq, dist, theta, vPSD) sinc(2 * freq * dist / obj.SoundVelocity);
            case 'anisotropic'
                hCohereFun = @(freq, dist, theta, vPSD) anisotropicCoherence(obj, freq, dist, theta, vPSD);
            case 'binaural2d'
                hCohereFun = @(freq, dist, theta, vPSD) binaural2d(obj, dist, freq);
            case 'binaural3d'
                hCohereFun = @(freq, dist, theta, vPSD) binaural3d(obj, dist, freq);
            otherwise
                warning(sprintf('Coherence model not recognized. Switched to default (''%s'')...',...
                    obj.ModelParameters.CohereModel)); %#ok<SPWRN>
        end
    end
    
    function [nBands] = get.numBands(obj)
        nBands = length(obj.vCenterFreqs);
    end
    
    function [nb] = get.numBins(obj)
        nb = obj.STFTParameters.NFFT/2+1;
    end
    
    function [nb] = get.numBlocks(obj)
        nb = computeNumberOfBlocks(obj.STFTParameters,obj.DesiredSignalLenSamples);
    end
    
    function [ns] = get.numStates(obj)
        ns = size(obj.ModelParameters.MarkovStateBoundaries,1);
    end
    
    function nb = get.lenLevelCurve(obj)
        nb = ceil((obj.numBlocks - obj.ModulationParams.Overlap)...
            / obj.ModulationParams.Frameshift);
    end
    
    function len = get.lenLevelCurvePlot(obj)
        len = min(obj.lenLevelCurve,size(obj.mLevelCurves,1));
    end
    
    function len = get.lenSignalPlotAudio(obj)
        if ~isempty(obj.AnalysisSignal)
            len = min(...
                obj.DesiredSignalLenSamples, ...
                min(length(obj.AnalysisSignal),obj.DesiredSignalLenSamples) ...
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
        
        obj.STFTParameters.OriginalSignalLength = lenSamples; %#ok<MCSUP>
    end
    
    function [] = set.SampleRate(obj,SampleRate)
        if obj.bDoNotChangeSampleRate %#ok<MCSUP>
            error(['At the moment, you cannot change the sampling rate ', ...
                'when an analysis signal has been used!']);
        else
            validateattributes(...
                SampleRate, ...
                {'numeric'}, ...
                {'scalar', 'integer', 'positive', 'nonnan', 'real', ...
                 '>=', 16e3, '<=', 48e3}...
                );
            
            obj.SampleRate = SampleRate;
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
        
    end
    
    function [] = stepImpl(obj)
        
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
