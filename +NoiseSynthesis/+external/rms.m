function [rms] = rms(mSignal,dim)
%RMS Root-Mean-Square of a Signal
% -------------------------------------------------------------------------
% Computes RMS for signal vectors or computes the RMS along dimension 'dim'
% for signal matrices. If 'dim' is ommitted, mSignal has to be a vector.
% Works also for complex signals.
%
% Usage: [rms] = rms(mSignal)
%        [rms] = rms(mSignal,dim)
%
%   Input:   ---------
%           mSignal: Signal matrix or vector
%           dim: if mSignal is a matrix: dimension to compute along
%
%  Output:   ---------
%           rms: scalar or vector RMS
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  02-Dec-2015 16:35:33
%


if min(size(mSignal)) > 1,
    rms = sqrt( mean( mSignal .* conj(mSignal), dim) );
else
    rms = sqrt( mean( mSignal .* conj(mSignal) ) );
end




% End of file: rms.m
