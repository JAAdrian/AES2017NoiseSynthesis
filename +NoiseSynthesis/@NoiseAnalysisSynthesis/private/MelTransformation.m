function [] = MelTransformation(obj)
%MELTRANSFORMATION Transform linear frequency bands into Mel bands
% -------------------------------------------------------------------------
%
% Usage: [] = MelTransformation(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 19:58:03
%


obj.Bands = MelMatrix(obj) * obj.Bands;


% End of file: MelTransformation.m
