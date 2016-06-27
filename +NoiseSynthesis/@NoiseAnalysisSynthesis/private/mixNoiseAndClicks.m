function [] = mixNoiseAndClicks(self)
%MIXNOISEANDCLICKS Mix base noise and clicks with correct noise-click-ratio
% -------------------------------------------------------------------------
%
% Usage: [] = mixNoiseAndClicks(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:10:16
%

import NoiseSynthesis.external.*


if self.ModelParameters.bApplyClicks,
    if self.ModelParameters.bReducePSD,
        b = self.ModelParameters.MeanPSD{1};
        a = self.ModelParameters.MeanPSD{2};
        
        vTF = freqz(b,a,self.STFTParameters.NFFT/2+1);
        % don't square it because the coefficients describe already
        % a power spectrum
        powSignal = mean(abs(vTF) / (2 * norm(self.STFTParameters.Window)^2));
    else
        powSignal = mean(self.ModelParameters.MeanPSD / (2 * norm(self.STFTParameters.Window)^2));
    end
    
    for aaSignal = 1:self.NumSensorSignals,
        self.ClickTracks{aaSignal} = ISTFT(...
            self.ClickTracks{aaSignal},...
            self.STFTParameters...
            );
        
        if ~all(self.ClickTracks{aaSignal} == 0),
            self.ClickTracks{aaSignal} = self.ClickTracks{aaSignal} * ...
                sqrt(powSignal) / std(self.ClickTracks{aaSignal}) * ...
                10^(-self.ModelParameters.SNRclick/20);
        end
        
        self.SensorSignals(:, aaSignal) = ...
            self.SensorSignals(:, aaSignal) + self.ClickTracks{aaSignal};
    end
end


% End of file: mixNoiseAndClicks.m
