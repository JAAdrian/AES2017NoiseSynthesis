function [] = applyModulations(self)
%APPLYMODULATIONS Apply the modulation parameter to the sythesis signals
% -------------------------------------------------------------------------
%
% Usage: [y] = applyModulations(input)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:07:21
%

import NoiseSynthesis.external.*


for aaSignal = 1:self.NumSensorSignals,
    self.mArtificialLevelCurves = [];
    
    % generate the artificial modulation curves
    showMsg(self,'Generating Modulations');
    computeArtificialModulations(self);
    
    % setup the time vectors for interpolation
    vTimeSub = (0:self.lenLevelCurve-1).' / self.ModulationParams.FrameRate;
    vTime    = (0:self.numBlocks-1).'     / self.STFTParameters.FrameRate;
    
    % interpolate along time dimension
    mInterpEnvelope = interp1(vTimeSub,self.mArtificialLevelCurves,vTime,...
        'linear','extrap');
    
    % setup the freq. vectors for interpolation
    vFreqSub = self.vCenterFreqs;
    vFreq    = linspace(0,self.Fs/2,self.numBins);
    
    % interpolate along frequency dimension
    mInterpEnvelope = interp1(vFreqSub,mInterpEnvelope.',vFreq,...
        'nearest','extrap');
    
    mIdx = isnan(mInterpEnvelope);
    mInterpEnvelope(mIdx) = 1;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % extract the phase and, weight the magnitudes and apply again
    mPhase = angle(self.SensorSignals{aaSignal});
    
    self.SensorSignals{aaSignal} = abs(self.SensorSignals{aaSignal}) .* mInterpEnvelope;
    
    self.SensorSignals{aaSignal} = self.SensorSignals{aaSignal} .* exp(1j * mPhase);
end


% End of file: applyModulations.m
