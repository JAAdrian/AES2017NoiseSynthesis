function [] = mixNoiseAndClicks(obj)
%MIXNOISEANDCLICKS Mix base noise and clicks with correct noise-click-ratio
% -------------------------------------------------------------------------
%
% Usage: [] = mixNoiseAndClicks(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:10:16
%

import NoiseSynthesis.External.*


if obj.ModelParameters.bApplyClicks,
    if obj.ModelParameters.bReducePSD,
        b = obj.ModelParameters.MeanPSD{1};
        a = obj.ModelParameters.MeanPSD{2};
        
        vTF = freqz(b,a,obj.STFTParameters.NFFT/2+1);
        % don't square it because the coefficients describe already
        % a power spectrum
        powSignal = mean(abs(vTF) / (2 * norm(obj.STFTParameters.Window)^2));
    else
        powSignal = mean(obj.ModelParameters.MeanPSD / (2 * norm(obj.STFTParameters.Window)^2));
    end
    
    for aaSignal = 1:obj.NumSensorSignals,
        obj.ClickTracks{aaSignal} = ISTFT(...
            obj.ClickTracks{aaSignal},...
            obj.STFTParameters...
            );
        
        if ~all(obj.ClickTracks{aaSignal} == 0),
            obj.ClickTracks{aaSignal} = obj.ClickTracks{aaSignal} * ...
                sqrt(powSignal) / std(obj.ClickTracks{aaSignal}) * ...
                10^(-obj.ModelParameters.SNRclick/20);
        end
        
        obj.SensorSignals(:, aaSignal) = ...
            obj.SensorSignals(:, aaSignal) + obj.ClickTracks{aaSignal};
    end
end


% End of file: mixNoiseAndClicks.m
