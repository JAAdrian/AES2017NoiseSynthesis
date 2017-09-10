function [] = estimateClickBandwidth(obj, clicks)
%ESTIMATECLICKBANDWIDTH Estimate the range of upper cutoff freq. in the extracted click signal
% -------------------------------------------------------------------------
%
% Usage: [] = estimateClickBandwidth(obj,vClicks)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  11-Dec-2015 14:02:36
%

blocklenSec  = 32e-3;
overlapRatio = 0.5;
params       = STFTparams(blocklenSec,overlapRatio,obj.Fs);
mSTFT        = STFT(clicks,params);

vFreq = linspace(0,obj.Fs/2,params.NFFT/2+1);

stAlgo.fs   = obj.Fs;              % sampling rate
stAlgo.type = 'fractional-octave';  % type of spectral smoothing
                                    % . 'fractional-octave' or
                                    % . 'fixed-bandwidth'

stAlgo.bandwidth = 1;           % bandwidth
                                % . in octaves for 'fractional-octave'
                                % . in Hz for 'fixed-bandwidth'

stAlgo.L_FFT = params.NFFT;            % length of the DFT

% initialize the smoothing algorithm
stAlgo = NoiseSynthesis.spectralsmoothing.spectralsmoothing_init(stAlgo);


thresh   = eps^2;
vCuttOff = [];

idxStart     = 1;
idxStop      = 1;
iGroupShift  = 1;
counterClick = 1;
while idxStart + idxStop < size(mSTFT,2)
    % click start found
    if mean(abs(mSTFT(:,idxStart)).^2) > thresh
        idxStop = 1;
        
        vClickGroup(1) = idxStart;
        while ...
                idxStart + idxStop < size(mSTFT,2) && ...
                mean(abs(mSTFT(:,idxStart+idxStop)).^2) > thresh
            
            vClickGroup(idxStop+1) = idxStart + idxStop;
            
            idxStop = idxStop + 1;
        end
        % click end found
        
        % if the click group is a vector compute the smoothed mean spectrum
        % and estimate the upper cutoff frequency
        if ~isscalar(vClickGroup)
            for aaBlock = 1:length(vClickGroup)
                vSmoothPSD(:,aaBlock) = ...
                    NoiseSynthesis.spectralsmoothing.spectralsmoothing_process(...
                    abs(mSTFT(:,vClickGroup(aaBlock))).^2, ...
                    stAlgo);
            end
            vMeanPSD = mean(vSmoothPSD,2);
            
            cfThresh = prctile(10*log10(vMeanPSD) + eps^2,98);
            vCuttOff = [vCuttOff; ...
                vFreq(find(10*log10(vMeanPSD + eps^2) >= cfThresh,1,'last'))];
            
            iGroupShift  = vClickGroup(end) - vClickGroup(1) + 1;
            counterClick = counterClick + 1;
        end
        vClickGroup = [];
    end
    
    idxStart = idxStart + iGroupShift;
    iGroupShift = 1;
end

obj.ModelParameters.fLowerClick = min(vCuttOff);
obj.ModelParameters.fUpperClick = max(vCuttOff);


% End of file: estimateClickBandwidth.m
