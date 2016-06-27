function [] = MelTransformation(self)
%MELTRANSFORMATION Transform linear frequency bands into Mel bands
% -------------------------------------------------------------------------
%
% Usage: [] = MelTransformation(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 19:58:03
%


self.mBands = MelMatrix(self) * self.mBands;


% End of file: MelTransformation.m
