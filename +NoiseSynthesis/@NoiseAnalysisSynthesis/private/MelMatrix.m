function [mTransformation] = MelMatrix(self)
%MELMATRIX Return the mel transformation matrix
% -------------------------------------------------------------------------
% Calls the FEX function melfilter() from
% http://www.mathworks.com/matlabcentral/fileexchange/23179-melfilter/
%
% Usage: [mTransformation] = MelMatrix(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 19:59:34
%

import NoiseSynthesis.external.*


vFreq = linspace(0,self.Fs/2,self.numBins);

mTransformation = melfilter(self.NumModulationBands,vFreq);



% End of file: MelMatrix.m
