function [vCohere] = anisotropicCoherence(self,vFreq,dist,theta,mPSD)
%ANISOTROPICCOHERENCE Compute anisotropic spatial coherence for n sources
% -------------------------------------------------------------------------
%
% Usage: [vCohere] = anisotropicCoherence(self,vFreq,dist,theta,mPSD)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:22:10
%


vFreq = vFreq(:);
theta = squeeze(theta);

[Re, Im] = deal(zeros(length(vFreq),1));
for aaSource = 1:self.NumSources,
    vArgument = (2*pi * vFreq * dist * cos(theta(aaSource))) / self.SoundVelocity;
    
    Re = Re + mPSD(:,aaSource) .* cos(vArgument);
    Im = Im + mPSD(:,aaSource) .* sin(vArgument);
end

vCohere = (Re - 1j*Im) ./ sum(mPSD,2);





% End of file: anisotropicCoherence.m
