function [] = applyModulations(obj)
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


for aaSignal = 1:obj.NumSensorSignals
    obj.mArtificialLevelCurves = [];
    
    % generate the artificial modulation curves
    showMsg(obj,'Generating Modulations');
    computeArtificialModulations(obj);
    
    % setup the time vectors for interpolation
    vTimeSub = (0:obj.lenLevelCurve-1).' / obj.ModulationParams.FrameRate;
    vTime    = (0:obj.numBlocks-1).'     / obj.STFTParameters.FrameRate;
    
    % interpolate along time dimension
    mInterpEnvelope = interp1(vTimeSub,obj.mArtificialLevelCurves,vTime,...
        'linear','extrap');
    
    % setup the freq. vectors for interpolation
    vFreqSub = obj.vCenterFreqs;
    vFreq    = linspace(0,obj.Fs/2,obj.numBins);
    
    % interpolate along frequency dimension
    mInterpEnvelope = interp1(vFreqSub,mInterpEnvelope.',vFreq,...
        'nearest','extrap');
    
    mIdx = isnan(mInterpEnvelope);
    mInterpEnvelope(mIdx) = 1;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % extract the phase and, weight the magnitudes and apply again
    mPhase = angle(obj.SensorSignals{aaSignal});
    
    obj.SensorSignals{aaSignal} = abs(obj.SensorSignals{aaSignal}) .* mInterpEnvelope;
    
    obj.SensorSignals{aaSignal} = obj.SensorSignals{aaSignal} .* exp(1j * mPhase);
end


% End of file: applyModulations.m
