function [cohere] = binaural2d(obj, dist, freqDesired)
%BINAURAL2D Get binaural coherence function for cylindrical noise field
% -------------------------------------------------------------------------
% Based on Marco Jeub's MATLAB FEX package from
% http://www.mathworks.com/matlabcentral/fileexchange/30167-binaural-coherence-of-noise-fields
%
% Only for the following sampling rates of fs = (16, 44.1, 48) kHz
%
% Usage: [vCohere] = binaural2d(obj,dist,vFreqDesired)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  02-Dec-2015 16:43:27
%


if obj.NumSensorSignals > 2
    error('This coherence model only works with 2 sensors!');
end

if ~dist
    cohere = ones(size(freqDesired));
else
    try
        data = load(sprintf('BinauralCoherence_%gkHz.mat', obj.SampleRate/1000));
    catch
        error('The file containing pre computed coherence data is missing or cannot be found!');
    end
    
    if norm(obj.ModelParameters.SensorPositions(:,2) - obj.ModelParameters.SensorPositions(:,1)) > data.d_mic
        error('The distance of the two(!) sensors must not be greater than %gm!', data.d_mic);
    end
    
    freq    = linspace(0, data.fs, data.nfft/2+1);
    cohere = interp1(freq, data.bin_coh_2d, freqDesired, 'linear', 'extrap');
    cohere = cohere(:);
end



% End of file: binaural2d.m
