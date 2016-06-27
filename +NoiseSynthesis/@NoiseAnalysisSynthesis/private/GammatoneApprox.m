function [] = GammatoneApprox(self)
%GAMMATONEAPPROX Transform into time-frequency representation using Gammatone approx.
% -------------------------------------------------------------------------
%
% Usage: [] = GammatoneApprox(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 19:57:36
%


self.mBands = STFTGammatone(self) * self.mBands;



% End of file: GammatoneApprox.m
