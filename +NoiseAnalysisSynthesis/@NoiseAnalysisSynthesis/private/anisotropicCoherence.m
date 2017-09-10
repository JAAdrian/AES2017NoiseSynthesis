function [cohere] = anisotropicCoherence(obj, freq, dist, theta, psd)
%ANISOTROPICCOHERENCE Compute anisotropic spatial coherence for n sources
% -------------------------------------------------------------------------
%
% Usage: [cohere] = anisotropicCoherence(obj, freq, dist, theta, psd)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:22:10
%


freq = freq(:);
theta = squeeze(theta);

[re, im] = deal(zeros(length(freq), 1));
for iSource = 1:obj.NumSources
    argument = (2*pi * freq * dist * cos(theta(iSource))) / obj.SOUND_VELOCITY;
    
    re = re + psd(:,iSource) .* cos(argument);
    im = im + psd(:,iSource) .* sin(argument);
end

cohere = (re - 1j*im) ./ sum(psd, 2);





% End of file: anisotropicCoherence.m
