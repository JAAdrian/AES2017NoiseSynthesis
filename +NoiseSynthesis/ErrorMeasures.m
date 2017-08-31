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
%           objNoise: The object ('obj') provided by the
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
        function obj = ErrorMeasures(objNoise)
            if ~nargin
                return;
            end
            
            obj.Noise = objNoise;
        end
        
        function [error] = get.ColorationError(obj)
            error = nan;
            
            if ~isempty(obj.Noise.SensorSignals) && ~isempty(obj.Noise.AnalysisSignal)
                error = computePSDerror(obj);
            end
        end
        
        function [error] = get.SpatialCoherenceError(obj)
            error = nan;
            
            if ~isempty(obj.Noise.SensorSignals) && ...
                    ~isempty(obj.Noise.AnalysisSignal) && ...
                    obj.Noise.bApplySpatialCoherence
                
                error = computeCoherenceError(obj);
            end
        end
        
        function [error] = get.AmplitudeDistributionError(obj)
            error = nan;
            
            if ~isempty(obj.Noise.SensorSignals) && ~isempty(obj.Noise.AnalysisSignal)
                error = computeDistributionError(obj);
            end
        end
        
        function [error] = get.ComodulationsError(obj)
            error = nan;
            
            if ~isempty(obj.Noise.SensorSignals) && ...
                    ~isempty(obj.Noise.AnalysisSignal) && ...
                    obj.Noise.bApplyModulations && ...
                    obj.Noise.bApplyComodulation
                
                error = computeComodulationError(obj);
            end
        end
        
        function [error] = get.ModulationSpecError(obj)
            error = nan;
            
            if ~isempty(obj.Noise.SensorSignals) && ~isempty(obj.Noise.AnalysisSignal)
                error = computeModulationError(obj);
            end
        end
        
        
        
        
        
        function [bl] = get.blocklen(obj)
            bl = round(obj.blocklenSec * obj.Noise.Fs);
        end
        
        function [nfft] = get.nfft(obj)
            nfft = pow2(nextpow2(obj.blocklen));
        end
        
        function [ol] = get.overlap(obj)
            ol = round(obj.blocklen * obj.overlapRatio);
        end
        
        function [frs] = get.frameshift(obj)
            frs = obj.blocklen - obj.overlap;
        end
        
        function [win] = get.vWindow(obj)
            win = hann(obj.blocklen,'periodic');
        end
        
        function [idx] = get.AnalysisIdx(obj)
            idx = ...
                round(length(obj.Noise.AnalysisSignal)*0.2) : ...
                min(...
                    round(length(obj.Noise.AnalysisSignal)*0.8),...
                    round(obj.Noise.DesiredSignalLenSamples*0.8)...
                    );
        end
    end
    
    
    methods (Access = private)
        function [error] = computePSDerror(obj)
            import NoiseSynthesis.spectralsmoothing.*
            
            method = validatestring(...
                obj.PsdErrorMethod, ...
                {'cosh', 'logMSE'} ...
                );
            
            obj.blocklenSec  = 50e-3;
            obj.overlapRatio = 0.5;
            
            vPSDReference = pwelch(...
                obj.Noise.AnalysisSignal,...
                obj.vWindow,...
                obj.overlap,...
                obj.nfft,...
                obj.Noise.Fs,...
                'power'...
                );
            
            vPSDSynthesis = pwelch(...
                obj.Noise.SensorSignals(:, 1),...
                obj.vWindow,...
                obj.overlap,...
                obj.nfft,...
                obj.Noise.Fs,...
                'power'...
                );

            switch method
                case 'cosh'
                    % from
                    % Gray and Markel, Distance Measures for Speech Processing
                    error = distchpf(vPSDReference(:).',vPSDSynthesis(:).');
                case 'logMSE'
                    error = mean( ...
                        (log10(abs(vPSDReference)) - log10(abs(vPSDSynthesis))).^2 ...
                        );
            end
        end
        
        function [error] = computeCoherenceError(obj)
            evalfun = @real;
            
            obj.blocklenSec  = 50e-3;
            obj.overlapRatio = 0.5;
            
            iSensor1 = 1;
            iSensor2 = min(obj.Noise.NumSensorSignals,2);
            
            
            vPpp = cpsd(obj.Noise.SensorSignals(:, iSensor1),...
                obj.Noise.SensorSignals(:, iSensor1),obj.vWindow,obj.overlap,obj.nfft);
            vPqq = cpsd(obj.Noise.SensorSignals(:, iSensor2),...
                obj.Noise.SensorSignals(:, iSensor2),obj.vWindow,obj.overlap,obj.nfft);
            vPpq = cpsd(obj.Noise.SensorSignals(:, iSensor1),...
                obj.Noise.SensorSignals(:, iSensor2),obj.vWindow,obj.overlap,obj.nfft);
            
            vFreq     = linspace(0,obj.Noise.Fs/2,obj.nfft/2+1);
            vGammaEst = vPpq ./ sqrt(vPpp .* vPqq);
            
            
            d = norm(...
                obj.Noise.ModelParameters.SensorPositions(:,iSensor1) - ...
                obj.Noise.ModelParameters.SensorPositions(:,iSensor2));
            
            mPSD   = [1 1];
            vGamma = obj.Noise.hCohereFun(vFreq,d,obj.Noise.mTheta(iSensor1,iSensor2,:),mPSD);
            
            error = mean( (evalfun(vGammaEst(:)) - evalfun(vGamma(:))).^2 );
        end
        
        function [error] = computeDistributionError(obj)
            method = validatestring(obj.AmplitudeErrorMethod, ...
                {...
                'KullbackLeibler', ...
                'ResistorAverage', ...
                'KullbackLeiblerSymmetric', ...
                'Bhattacharyya', ...
                'Hellinger' ...
                });
            
            caNPoints = {'NumPoints', 1000};
            
            [pdfP, quantilesP] = ksdensity(obj.Noise.AnalysisSignal,caNPoints{:});
            [pdfQ, quantilesQ] = ksdensity(obj.Noise.SensorSignals(:, 1),caNPoints{:});
            
            pdfQ = interp1(quantilesQ, pdfQ, quantilesP, 'linear', 'extrap').';
            pdfQ(pdfQ < 0) = 0;
            
            
            switch method
                case 'KullbackLeibler'
                    error = KullbackLeibler(quantilesP, pdfP, pdfQ);
                    
                case 'Bhattacharyya'
                    error = bhattacharyya(pdfP(:), pdfQ(:));
                    
                case 'Hellinger'
                    error = sqrt(1 - bhattacharyya(pdfP, pdfQ));
                    
                case 'ResistorAverage'
                    p = KullbackLeibler(quantilesP, pdfP, pdfQ);
                    q = KullbackLeibler(quantilesP, pdfQ, pdfP);
                    
                    error = (1/p + 1/q)^-1;
                    
                case 'KullbackLeiblerSymmetric'
                    p = KullbackLeibler(quantilesP, pdfP, pdfQ);
                    q = KullbackLeibler(quantilesP, pdfQ, pdfP);
                    
                    error = mean([p q]);
            end
        end
        
        function [error] = computeComodulationError(obj)
            corrAnalysis  = computeBandCoherence(obj.Noise.mLevelCurves);
            corrSynthesis = computeBandCoherence(obj.Noise.mArtificialLevelCurves);
            
            error = MatrixMSE(corrAnalysis, corrSynthesis);
        end
        
        function [error] = computeModulationError(obj)
            import NoiseSynthesis.external.*
            
            obj.blocklenSec  = 15e-3;
            obj.overlapRatio = 0.8;
            
            len = min(length(obj.Noise.AnalysisSignal),obj.Noise.DesiredSignalLenSamples);
            
            mModSpecAnal = ...
                ModulationSpectrogram(obj.Noise.AnalysisSignal(1:len),...
                obj.vWindow,obj.overlap,obj.nfft,obj.Noise.Fs);
            mModSpecSynth = ...
                ModulationSpectrogram(obj.Noise.SensorSignals(1:len, 1),...
                obj.vWindow,obj.overlap,obj.nfft,obj.Noise.Fs);
            
            error = MatrixMSE(abs(mModSpecAnal), abs(mModSpecSynth));
        end
    end
end



function [mGamma] = computeBandCoherence(mBands)
numBands = size(mBands,2);

mGamma = zeros(numBands);
for ppBand = 1:numBands
    for qqBand = ppBand+1:numBands
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
