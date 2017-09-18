function [vSigmoid] = sigmoidfun(x,x0,alpha)
%SIGMOIDFUN Compute a Sigmoid signal vector
% -------------------------------------------------------------------------
% <Detailed description of the function>
%
% Usage: [vSigmoid] = sigmoidfun(x,x0,alpha)
%
%   Input:   ---------
%           x: Vector of indpependent variable
%           x0: location parameter
%           alpha: scale parameter
%
%  Output:   ---------
%           vSigmoid: Sigmoid signal vector
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:29:42
%


vSigmoid = 1./(1 + exp(-(x - x0) / alpha));




% End of file: sigmoidfun.m
