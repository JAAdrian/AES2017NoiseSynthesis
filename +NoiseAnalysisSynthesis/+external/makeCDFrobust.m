function [x,y] = makeCDFrobust(x,y)
%MAKECDFROBUST Make an empiric CDF numerically more robust
% -------------------------------------------------------------------------
% This function finds parts in the CDF which lead to unrobust inversion
% when used, for instance, in the percentile method.
%
% Usage: [x,y] = makeCDFrobust(x,y)
%
%   Input:   ---------
%           x: Vector of the independent variable
%           y: Vector of the dependent variable
%
%  Output:   ---------
%           x: Robust vector of the independent variable
%           y: Robust vector of the dependent variable
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:52:08
%


vIdxZero    = find(y(2:end) == 0);
y(vIdxZero) = [];
x(vIdxZero) = [];

vIdxInconsistent    = find(abs(diff(y)) <= eps);
y(vIdxInconsistent) = [];
x(vIdxInconsistent) = [];




% End of file: makeCDFrobust.m
