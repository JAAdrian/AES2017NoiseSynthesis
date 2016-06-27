classdef ErrorMeasures < handle
%ERRORMEASURES Error measure class for the NoiseAnalysisSynthesis class
% -------------------------------------------------------------------------
% This class provides error measures between a desired analysis and a
% synthesis signal hosted by the NoiseAnalysisSynthesis parent class. It is
% supposed to be used within the NoiseAnalysisSynthesis class.
%
% Usage: obj = ErrorMeasures(objNoise)
%
%   Input:   ---------------
%           objNoise: The object ('self') provided by the
%                     NoiseAnalysisSynthesis class.
%
%   Output:  ---------------
%           obj: created ErrorMeasures object
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  13-Jul-2015 17:59:12
%
    
    
    properties (Access = private)
        Noise; % NoiseAnalysisSynthesis object passed by the parent class
        
        blocklenSec  = 30e-3; % Block length in seconds
        overlapRatio = 0.5; % Overlap as a ratio
    end
    
    properties (Access = private, Dependent)
        blocklen; % Block length in samples
        overlap; % Overlap in samples
        frameshift; % Frame shift (or hopsize) in samples
        vWindow; % Window function vector
        nfft; % DFT size in samples
        
        AnalysisIdx; % Parts of the condisered signals to be evaluated in samples
    end
    
    
    properties (SetAccess = private, GetAccess = public)
        ColorationError; % Spectral COSH distance
        SpatialCoherenceError; % Spatial coherence MSE
        ComodulationsError; % Comodulation matrix-MSE
        AmplitudeDistributionError; % Amplitude distribution MSE
        ModulationSpecError; % Modulation spectrum matrix-MSE
    end
    
    
    properties (Access = public)
        AmplitudeErrorMethod = 'Bhattacharyya';
        PsdErrorMethod = 'cosh';
        ModulationErrorMethod = 'KullbackLeibler';
    end
    
    
    
    methods
        % Class constructor
        function self = ErrorMeasures(objNoise)
            if nargin,
                self.Noise = objNoise;
            end
        end
        
        function [error] = get.ColorationError(self)
            error = nan;
            
            if ~isempty(self.Noise.SensorSignals) && ~isempty(self.Noise.AnalysisSignal),
                error = computePSDerror(self);
            end
        end
        
        function [error] = get.SpatialCoherenceError(self)
            error = nan;
            
            if ~isempty(self.Noise.SensorSignals) && ...
                    ~isempty(self.Noise.AnalysisSignal) && ...
                    self.Noise.bApplySpatialCoherence,
                
                error = computeCoherenceError(self);
            end
        end
        
        function [error] = get.AmplitudeDistributionError(self)
            error = nan;
            
            if ~isempty(self.Noise.SensorSignals) && ~isempty(self.Noise.AnalysisSignal),
                error = computeDistributionError(self);
            end
        end
        
        function [error] = get.ComodulationsError(self)
            error = nan;
            
            if ~isempty(self.Noise.SensorSignals) && ...
                    ~isempty(self.Noise.AnalysisSignal) && ...
                    self.Noise.bApplyModulations && ...
                    self.Noise.bApplyComodulation,
                
                error = computeComodulationError(self);
            end
        end
        
        function [error] = get.ModulationSpecError(self)
            error = nan;
            
            if ~isempty(self.Noise.SensorSignals) && ~isempty(self.Noise.AnalysisSignal),
                error = computeModulationError(self);
            end
        end
        
        
        
        
        
        function [bl] = get.blocklen(self)
            bl = round(self.blocklenSec * self.Noise.Fs);
        end
        
        function [nfft] = get.nfft(self)
            nfft = pow2(nextpow2(self.blocklen));
        end
        
        function [ol] = get.overlap(self)
            ol = round(self.blocklen * self.overlapRatio);
        end
        
        function [frs] = get.frameshift(self)
            frs = self.blocklen - self.overlap;
        end
        
        function [vWin] = get.vWindow(self)
            vWin = hann(self.blocklen,'periodic');
        end
        
        function [vIdx] = get.AnalysisIdx(self)
            vIdx = ...
                round(length(self.Noise.AnalysisSignal)*0.2) : ...
                min(...
                    round(length(self.Noise.AnalysisSignal)*0.8),...
                    round(self.Noise.DesiredSignalLenSamples*0.8)...
                    );
        end
    end
    
    
    methods (Access = private)
        function [error] = computePSDerror(self)
            import NoiseSynthesis.spectralsmoothing.*
            
            method = validatestring(...
                self.PsdErrorMethod, ...
                {'cosh', 'logMSE'} ...
                );
            
            self.blocklenSec  = 50e-3;
            self.overlapRatio = 0.5;
            
            vPSDReference = pwelch(...
                self.Noise.AnalysisSignal,...
                self.vWindow,...
                self.overlap,...
                self.nfft,...
                self.Noise.Fs,...
                'power'...
                );
            
            vPSDSynthesis = pwelch(...
                self.Noise.SensorSignals(:, 1),...
                self.vWindow,...
                self.overlap,...
                self.nfft,...
                self.Noise.Fs,...
                'power'...
                );

            switch method,
                case 'cosh',
                    % from
                    % Gray and Markel, Distance Measures for Speech Processing
                    error = distchpf(vPSDReference(:).',vPSDSynthesis(:).');
                case 'logMSE',
                    error = mean( ...
                        (log10(abs(vPSDReference)) - log10(abs(vPSDSynthesis))).^2 ...
                        );
            end
        end
        
        function [error] = computeCoherenceError(self)
            evalfun = @real;
            
            self.blocklenSec  = 50e-3;
            self.overlapRatio = 0.5;
            
            iSensor1 = 1;
            iSensor2 = min(self.Noise.NumSensorSignals,2);
            
            
            vPpp = cpsd(self.Noise.SensorSignals(:, iSensor1),...
                self.Noise.SensorSignals(:, iSensor1),self.vWindow,self.overlap,self.nfft);
            vPqq = cpsd(self.Noise.SensorSignals(:, iSensor2),...
                self.Noise.SensorSignals(:, iSensor2),self.vWindow,self.overlap,self.nfft);
            vPpq = cpsd(self.Noise.SensorSignals(:, iSensor1),...
                self.Noise.SensorSignals(:, iSensor2),self.vWindow,self.overlap,self.nfft);
            
            vFreq     = linspace(0,self.Noise.Fs/2,self.nfft/2+1);
            vGammaEst = vPpq ./ sqrt(vPpp .* vPqq);
            
            
            d = norm(...
                self.Noise.ModelParameters.SensorPositions(:,iSensor1) - ...
                self.Noise.ModelParameters.SensorPositions(:,iSensor2));
            
            mPSD   = [1 1];
            vGamma = self.Noise.hCohereFun(vFreq,d,self.Noise.mTheta(iSensor1,iSensor2,:),mPSD);
            
            error = mean( (evalfun(vGammaEst(:)) - evalfun(vGamma(:))).^2 );
        end
        
        function [error] = computeDistributionError(self)
            method = validatestring(self.AmplitudeErrorMethod, ...
                {...
                'KullbackLeibler', ...
                'ResistorAverage', ...
                'KullbackLeiblerSymmetric', ...
                'Bhattacharyya', ...
                'Hellinger' ...
                });
            
            caNPoints = {'NumPoints', 1000};
            
            [pdfP, quantilesP] = ksdensity(self.Noise.AnalysisSignal,caNPoints{:});
            [pdfQ, quantilesQ] = ksdensity(self.Noise.SensorSignals(:, 1),caNPoints{:});
            
            pdfQ = interp1(quantilesQ, pdfQ, quantilesP, 'linear', 'extrap').';
            pdfQ(pdfQ < 0) = 0;
            
            
            switch method,
                case 'KullbackLeibler',
                    error = KullbackLeibler(quantilesP, pdfP, pdfQ);
                    
                case 'Bhattacharyya',
                    error = bhattacharyya(pdfP(:), pdfQ(:));
                    
                case 'Hellinger',
                    error = sqrt(1 - bhattacharyya(pdfP, pdfQ));
                    
                case 'ResistorAverage',
                    p = KullbackLeibler(quantilesP, pdfP, pdfQ);
                    q = KullbackLeibler(quantilesP, pdfQ, pdfP);
                    
                    error = (1/p + 1/q)^-1;
                    
                case 'KullbackLeiblerSymmetric',
                    p = KullbackLeibler(quantilesP, pdfP, pdfQ);
                    q = KullbackLeibler(quantilesP, pdfQ, pdfP);
                    
                    error = mean([p q]);
            end
        end
        
        function [error] = computeComodulationError(self)
            corrAnalysis  = computeBandCoherence(self.Noise.mLevelCurves);
            corrSynthesis = computeBandCoherence(self.Noise.mArtificialLevelCurves);
            
            error = MatrixMSE(corrAnalysis, corrSynthesis);
        end
        
        function [error] = computeModulationError(self)
            import NoiseSynthesis.external.*
            
            self.blocklenSec  = 15e-3;
            self.overlapRatio = 0.8;
            
            len = min(length(self.Noise.AnalysisSignal),self.Noise.DesiredSignalLenSamples);
            
            mModSpecAnal = ...
                ModulationSpectrogram(self.Noise.AnalysisSignal(1:len),...
                self.vWindow,self.overlap,self.nfft,self.Noise.Fs);
            mModSpecSynth = ...
                ModulationSpectrogram(self.Noise.SensorSignals(1:len, 1),...
                self.vWindow,self.overlap,self.nfft,self.Noise.Fs);
            
            error = MatrixMSE(abs(mModSpecAnal), abs(mModSpecSynth));
        end
    end
    
    
    
    
    
    
    
end



function [mGamma] = computeBandCoherence(mBands)
numBands = size(mBands,2);

mGamma = zeros(numBands);
for ppBand = 1:numBands,
    for qqBand = ppBand+1:numBands,
        mTmp = corrcoef(mBands(:,ppBand),mBands(:,qqBand));
        mGamma(ppBand,qqBand) = mTmp(2,1);
    end
end
mGamma = mGamma + mGamma';
mGamma(logical(eye(numBands))) = 1;
end

function [MSE] = MatrixMSE(mat1,mat2)
mErr = abs(mat1 - mat2).^2;
MSE  = sum(mErr(:)) / numel(mErr);
end

function dist = KullbackLeibler(quantiles, p, q)
    dist = trapz(quantiles, p .* log2(max(p ./ max(q, eps), eps)));
end


% End of file: ErrorMeasures.m
