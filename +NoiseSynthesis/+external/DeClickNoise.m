function [vDeClicked,vPositions] = DeClickNoise(vSignal,fs,ThreshDeClick)
%DECLICKNOISE Declick the analysis signal
% -------------------------------------------------------------------------
% <Detailed description of the function>
%
% Usage: [vDeClicked,vPositions] = DeClickNoise(vSignal,fs)
%        [vDeClicked,vPositions] = DeClickNoise(vSignal,fs,ThreshDeClick)
%
%   Input:   ---------
%           vSignal: Signal vector to be declicked
%           fs: Sampling rate in Hz
%           ThreshDeClick: Sensitivity threshold. Lower is more sensitive
%                          [default: 0.3]
%
%  Output:   ---------
%           vDeClicked: Declicked signal vector
%           vPositions: indices of the start of clicks
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  19-Mar-2015 15:47:43
%

import NoiseSynthesis.external.*

if nargin < 3 || isempty(ThreshDeClick),
    ThreshDeClick = 0.3;
end

stAlgo = DeClick(fs,ThreshDeClick);
stAlgo.init();

iNrOfIter = 4;

for nn = 1: iNrOfIter-1
    [vSignal,vPos] = stAlgo.process(vSignal,0);
    
    if nn == 1,
        vPositions = vPos;
    end
end
[vDeClicked] = stAlgo.process(vSignal,1);





% End of file: DeClickNoise.m
