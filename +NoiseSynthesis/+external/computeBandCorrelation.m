function [mGamma] = computeBandCorrelation(mBands)
%COMPUTEBANDCORRELATION Compute Pearson correlation between freq. bands
% -------------------------------------------------------------------------
% This function computes the correlation, and therefore comodulation
% strength between a number of frequency bands.
%
% Usage: [mGamma] = computeBandCorrelation(mBands)
%
%   Input:   -------------
%           mBands: (lenBand x numBands)
%
%   Output:  -------------
%           mGamma: (numBands x numBands) correlation matrix
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:49:46
%


mGamma = corrcoef(mBands);

% this is a dumb, dirty but also cheap trick to enforce true symmetry,
% since MATLAB's eig() comes up with complex eigenvalues due to round-off
% errors resulting from not perfect symmetry at machine precision in mGamma
mGamma = double(single(mGamma));




% End of file: computeBandCorrelation.m
