function [mTransformation] = MelMatrix(obj)
%MELMATRIX Return the mel transformation matrix
% -------------------------------------------------------------------------
% Calls the FEX function melfilter() from
% http://www.mathworks.com/matlabcentral/fileexchange/23179-melfilter/
%
% Usage: [mTransformation] = MelMatrix(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 19:59:34
%

import NoiseSynthesis.external.*


freq = linspace(0, obj.SampleRate/2, obj.NumBins);

mTransformation = melfilter(obj.NumModulationBands, freq);



% End of file: MelMatrix.m
