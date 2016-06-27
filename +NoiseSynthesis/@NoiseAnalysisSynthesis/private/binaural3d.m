function [vCohere] = binaural3d(self,dist,vFreqDesired)
%BINAURAL3D Get binaural coherence function for spherical noise field
% -------------------------------------------------------------------------
% Based on Marco Jeub's MATLAB FEX package from
% http://www.mathworks.com/matlabcentral/fileexchange/30167-binaural-coherence-of-noise-fields
%
% Only for the following sampling rates of fs = (16, 44.1, 48) kHz
%
% Usage: [vCohere] = binaural3d(self,dist,vFreqDesired)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  02-Dec-2015 16:41:59
%


if self.NumSensorSignals > 2,
    error('This coherence model only works with 2 sensors!');
end

if ~dist,
    vCohere = ones(size(vFreqDesired));
else
    try
        stData = load(sprintf('BinauralCoherence_%gkHz.mat',self.Fs/1000));
    catch
        error('The file containing pre computed coherence data is missing or cannot be found!');
    end
    
    if norm(self.ModelParameters.SensorPositions(:,2) - self.ModelParameters.SensorPositions(:,1)) > stData.d_mic,
        error('The distance of the two(!) sensors must not be greater than %gm!',stData.d_mic);
    end
    
    vFreq   = linspace(0,stData.fs,stData.nfft/2+1);
    vCohere = interp1(vFreq,stData.bin_coh_3d,vFreqDesired,'linear','extrap');
    vCohere = vCohere(:);
end



% End of file: binaural3d.m
