function [] = GammatoneApprox(obj)
%GAMMATONEAPPROX Transform into time-frequency representation using Gammatone approx.
% -------------------------------------------------------------------------
%
% Usage: [] = GammatoneApprox(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 19:57:36
%


obj.mBands = STFTGammatone(obj) * obj.mBands;



% End of file: GammatoneApprox.m
