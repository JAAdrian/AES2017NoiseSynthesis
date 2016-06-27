classdef NoiseAnalysisSynthesis < handle
%NOISEANALYSISSYNTHESIS Class to do analysis and synthesis on noise files
% -------------------------------------------------------------------------
% This class provides means to analyze noise disturbances and synthesize
% new noise signals. This can also be done under a spatial coherence
% constraint. Please see README.md or runDemo.m for examples how to start.
%
% Usage: obj = NoiseSynthesis.NoiseAnalysisSynthesis()
%        obj = NoiseSynthesis.NoiseAnalysisSynthesis(vSignal, fs)
%
%   Input:   --------------
%           vSignal: Signal vector of the desired analysis signal
%           fs: sampling frequency in Hz
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


properties ( Access = private, Constant )
    SoundVelocity = 343; % Velocity of sound
    
    overlapRatio = 0.5; % Fixed overlap for analysis and synthesis
    
    hModNormFun = @(x) mad(x,1,1); % Normalization function for level fluctuations
    
    soundLeveldB = -35; % Default sound level for playback in dB FS
end

properties ( Access = private )
    vOriginalAnalysisSignal;    % Raw analysis signal
    vBeforeDeCrackling;
    
    mBands; % Frequency bands
    mLevelCurvesDecorr; % Decorrelated level fluctuations for all bands
    
    blocklen = 1024; % Block length for STFT
    STFTParameters;  % Parameter object for the STFT
    ModulationParams; % Parameter object for the modulations
    
    bDoNotChangeSampleRate = false;
end

properties (Access = ?NoiseSynthesis.ErrorMeasures)
    mTheta; % Angles between sources and sensors
    mLevelCurves; % Level curves of all bands
    mArtificialLevelCurves; % Generated level curves for all bands
end

properties ( Access = ?NoiseSynthesis.ErrorMeasures, Dependent)
    hCohereFun; % Function handle to the desired coherence model
end

properties ( SetAccess = private, GetAccess = public )
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

properties ( SetAccess = private, Dependent )
    NumSensorSignals; % Number of desired sensor signals (dependent on size of the sensor position matrix)
    NumSources; % Number of acoustic sources in the noise field ((dependent on size of the sources position matrix))
end

properties ( Access = private, Transient)
    mDistances; % Distances between sensors
end

properties ( Access = public )
    Fs = 44.1e3; % Sampling rate in Hz [default: 44.1kHz]
    
    DesiredSignalLenSamples = 44100; % Desired synthesis length in samples [default: 1sec -> 44100]
    
    bApplyColoration       = true; % Bool whether to apply coloration in the synthesis [default: true]
    bApplyAmplitudeDistr   = true; % Bool whether to apply an amplitude distribution in the synthesis [default: true]
    bApplyModulations      = true; % Bool whether to apply modulations in the synthesis [default: true]
    bApplyComodulation     = true; % Bool whether to apply comodulation in the synthesis [default: true]
    bApplySpatialCoherence = true; % Bool whether to apply spatial coeherence in the synthesis [default: true]
    
    bEstimateClickSpec = true; % Bool whether to estimate the click cutoff frequency in the analysis. Dependent on bApplyClicks [default: true]
    
    bDeClick = true; % Bool whether to declick the analysis file [default: true]
end

properties ( Access = private, Dependent )
    vCenterFreqs; % Center frequencies of either the Mel or Gammatone FB
    numBands; % Number of frequency bands
    lenLevelCurve; % Length of the RMS level fluctuations curve
    numBlocks; % Number of signal blocks with chosen STFT parameters
    numBins; % Number of DFT bins with chosen STFT parameters
    numStates; % Number of Markov states
    lenLevelCurvePlot; % Length of the RMS level fluctuations curve for plotting purposes
    lenSignalPlotAudio; % Length of the signal in samples for plotting and playback purposes
end

properties (Access = public, Hidden)
    bVerbose          = false; % Bool whether to plot verbose information during processing
    bHPFilterAnalysis = true;  % Bool whether to apply the HP filter before analysis
end
    
methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CLASS CONSTRUCTOR
    function self = NoiseAnalysisSynthesis(vSignal,fs)
        % Create auxiliary objects
        self.STFTParameters = NoiseSynthesis.STFTparams(...
            self.blocklen/self.Fs,...
            self.overlapRatio,...
            self.Fs,...
            'synthesis');
        self.STFTParameters.OriginalSignalLength = self.DesiredSignalLenSamples;
        
        % If input arguments are passed -> deal them to the properties
        if nargin,
            validateattributes(...
                vSignal, ...
                {'numeric'}, ...
                {'vector', 'finite', 'nonempty', 'nonsparse'}, ...
                'NoiseAnalysisSynthesis', ...
                'vSignal', ...
                1 ...
                );
            validateattributes(...
                fs, ...
                {'numeric'}, ...
                {'scalar', 'positive'}, ...
                'NoiseAnalysisSynthesis', ...
                'fs', ...
                2 ...
                );
            
            % make sure vSignal is a row vector
            vSignal = shiftdim(vSignal);
            
            self.AnalysisSignal = vSignal - mean(vSignal);
            self.Fs             = fs;
            
            self.DesiredSignalLenSamples = length(vSignal);
            
            % Check if FFT size is OK based on sample rate
            checkFFTlength(self);
            
            self.bDoNotChangeSampleRate = true;
        end
        
        self.ModelParameters = NoiseSynthesis.ModelParametersSet();
        self.ErrorMeasures   = NoiseSynthesis.ErrorMeasures(self);
        
        % Based on current parameters create the modulation parameter
        % object
        updateModulationParameters(self);
        
        % Initialize angles between source(s) and sensor(s)
        self.mTheta = pi/2 * ones(self.NumSensorSignals);
        
        % Initialize Markov modulation states
        updateMarkovParams(self,-12,12);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%% Public methods %%%%%%%%%%%%%%%%%%%
    
    [] = analyze(self);
    [SensorSignalsOut] = synthesize(self);
    
    [] = saveSignals(self,szSaveFilename,bStereo,bRandPhase,szExt);
    
    [] = sound(self,leveldB,bStereo);
    [] = soundsc(self,bStereo);
    
    [] = playAnalyzed(self,leveldB);
    [] = playSynthesized(self,leveldB,bStereo);
    
    [] = plot(self,bSave,szSavePath,szPlotProfile);

    [] = saveParameters(self,szFilename);
    
    [] = flushParameters(self);
    [] = readParameters(self,szFilename);
    
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%% setter/getter methods %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [vFreqs] = get.vCenterFreqs(self)
        numBands = self.NumModulationBands; %#ok<PROP>
        
        vFreqs = erbscale2freq(...
            linspace(...
            freq2erbscale(self.GammatoneLowestBand),...
            freq2erbscale(self.GammatoneHighestBand),...
            numBands)...
            ); %#ok<PROP>
    end
    
    function [numSens] = get.NumSensorSignals(self)
        if self.bApplySpatialCoherence,
            numSens = size(self.ModelParameters.SensorPositions,2);
        else
            numSens = 1;
        end
    end
    
    function [numSources] = get.NumSources(self)
        numSources = size(self.ModelParameters.SourcePosition,2);
    end
    
    function hCohereFun = get.hCohereFun(self)
        switch lower(self.ModelParameters.CohereModel),
            case 'cylindrical',
                % zeroth order bessel of first kind
                hCohereFun = @(Freq,dist,theta,vPSD) besselj(0,2*pi * Freq * dist / self.SoundVelocity);
            case 'spherical',
                hCohereFun = @(Freq,dist,theta,vPSD) sinc(2 * Freq * dist / self.SoundVelocity);
            case 'anisotropic',
                hCohereFun = @(Freq,dist,theta,vPSD) anisotropicCoherence(self,Freq,dist,theta,vPSD);
            case 'binaural2d',
                hCohereFun = @(Freq,dist,theta,vPSD) binaural2d(self,dist,Freq);
            case 'binaural3d',
                hCohereFun = @(Freq,dist,theta,vPSD) binaural3d(self,dist,Freq);
            otherwise,
                warning(sprintf('Coherence model not recognized. Switched to default (''%s'')...',...
                    self.ModelParameters.CohereModel)); %#ok<SPWRN>
        end
    end
    
    function [nBands] = get.numBands(self)
        nBands = length(self.vCenterFreqs);
    end
    
    function [nb] = get.numBins(self)
        nb = self.STFTParameters.NFFT/2+1;
    end
    
    function [nb] = get.numBlocks(self)
        nb = computeNumberOfBlocks(self.STFTParameters,self.DesiredSignalLenSamples);
    end
    
    function [ns] = get.numStates(self)
        ns = size(self.ModelParameters.MarkovStateBoundaries,1);
    end
    
    function nb = get.lenLevelCurve(self)
        nb = ceil((self.numBlocks - self.ModulationParams.Overlap)...
            / self.ModulationParams.Frameshift);
    end
    
    function len = get.lenLevelCurvePlot(self)
        len = min(self.lenLevelCurve,size(self.mLevelCurves,1));
    end
    
    function len = get.lenSignalPlotAudio(self)
        if ~isempty(self.AnalysisSignal),
            len = min(...
                self.DesiredSignalLenSamples, ...
                min(length(self.AnalysisSignal),self.DesiredSignalLenSamples) ...
                );
        else
            len = self.DesiredSignalLenSamples;
        end
    end
    
    function [] = set.DesiredSignalLenSamples(self,lenSamples)
        validateattributes(...
            lenSamples, ...
            {'numeric'}, ...
            {'nonzero', 'nonnegative'});
        
        self.DesiredSignalLenSamples = lenSamples;
        
        self.STFTParameters.OriginalSignalLength = lenSamples; %#ok<MCSUP>
    end
    
    function [] = set.Fs(self,SampleRate)
        if self.bDoNotChangeSampleRate, %#ok<MCSUP>
            error(['At the moment, you cannot change the sampling rate ', ...
                'when an analysis signal has been used!']);
        else
            validateattributes(...
                SampleRate, ...
                {'numeric'}, ...
                {'scalar', 'integer', 'positive', 'nonnan', 'real', ...
                 '>=', 16e3, '<=', 48e3}...
                );
            
            self.Fs = SampleRate;
        end
    end
end

methods ( Hidden )
    function [] = applyChangedModel(self,~,eventData)
        flushParameters(self);
        
        readParameters(self, eventData.Source.Model);
    end
end
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
methods (Access = private)
    [] = DeClickAnalysisSignal(self);
    [] = learnMarkovClickParams(self,vClicks);
    
    [] = AnalysisFilterbank(self,vSigIn);
    [vTimeSignal] = SynthesisFilterbank(self);
    
    [] = GammatoneApprox(self);
    [] = MelTransformation(self);
    [mTransform] = STFTGammatone(self);
    [mTransformation] = MelMatrix(self);
    
    [] = analyzeAmplitudeDistribution(self);
    
    [] = analyzeModulations(self);
    [] = computeLevelFluctuations(self);
    [] = learnMarkovModulationParams(self);
    [] = updateMarkovParams(self,minVal,maxVal);
    
    [] = analyzeMeanBandPower(self);
    
    [] = analyzeCorrelationBands(self);
    [] = decorrelateLevelFluctuations(self);
    [] = analyzeModulationDepth(self);
    
    [] = applyModulations(self);
    [] = computeArtificialModulations(self);
    
    [] = applyAmplitudeDistribution(self);
    [vSigOut] = shapeAmplitudeDistr(self,vSigIn);
    
    [] = mixNoiseAndClicks(self);
    
    [vNoise] = generateNoise(self,iNoiseMode);
    [] = generateCoherentNoise(self);
    [] = generateIncoherentNoise(self);
    
    [] = generateIncoherentClicks(self);
    [] = generateCoherentClicks(self);
    
    [] = computeSensorDistances(self);
    [] = computeTheta(self);
    [mMixingMatrix] = computeMixingMatrix(self,Freq,SourcePSDbin);
    [mFreqNoiseMix] = mixSignals(self,caSTFTNoise,bComputePSD);
    [mGamma] = computeBandCorrelation(mBands);
    [vCohere] = binaural2d(self,dist,vFreqDesired);
    [vCohere] = binaural3d(self,dist,vFreqDesired);
    
    [] = generateLevelCurves(self);
    
    [] = mixBands(self);
    [] = normalizeBands(self);
    [mMixingMatrix] = computeBandMixingMatrix(mGamma);
    
    [] = generateGaussBands(self);
    [] = generateMarkovBands(self);
    [vModulationCurve] = genmarkov(self,idxBand);
    
    [] = checkFFTlength(self);
    
    [mClickSTFT] = genArtificialClicks(self);
    [vClicks] = genclickmarkov(self);
    
    [vCohere] = anisotropicCoherence(self,vFreq,dist,theta,mPSD);
    
    [vCDF, vQuantiles] = PiecewiseParetoCDF(self,numPoints);
    [vPDF, vQuantiles] = PiecewiseParetoPDF(self,numPoints);
    [vSigmoid] = sigmoidfun(x,x0,alpha);
    
    [] = updateModulationParameters(self);
    
    [] = showMsg(self,szMessage);
    [x,y] = makeCDFrobust(x,y);
    
    [rms] = rms(mSignal,dim);
end

end

% Auxiliary functions to transform linear frequency scale to ERB scale and
% vice versa
function vFreq = erbscale2freq(vERB)
vFreq = 1000/4.37 * (10.^(vERB/21.4) - 1);
end

function vERB = freq2erbscale(vFreq)
vERB = 21.4 * log10(1 + vFreq/1000 * 4.37);
end





% End of file: NoiseAnalysisSynthesis.m
