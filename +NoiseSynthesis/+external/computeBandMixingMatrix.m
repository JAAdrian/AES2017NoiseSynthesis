function [mMixingMatrix] = computeBandMixingMatrix(mGamma)
%COMPUTEBANDMIXINGMATRIX Compute mixing matrix for freq. bands
% -------------------------------------------------------------------------
% Computes the mixing matrix to introduce comodulation using eigenvalues
% and -vectors from the correlation matrix.
%
% Usage: [mMixingMatrix] = computeBandMixingMatrix(mGamma)
%
%   Input:   ---------
%           mGamma: (numBands x numBands) correlation matrix
%
%  Output:   ---------
%           mMixingMatrix: (numBands x numBands) mixing matrix
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:27:06
%


[mEigVecs,mEigVals] = eig(mGamma);
mMixingMatrix       = (sign(mEigVals) .* sqrt(abs(mEigVals))) * mEigVecs';






% End of file: computeBandMixingMatrix.m
