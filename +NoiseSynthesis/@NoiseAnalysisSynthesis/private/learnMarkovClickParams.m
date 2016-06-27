function [] = learnMarkovClickParams(self,vClicks)
%LEARNMARKOVCLICKPARAMS Learn the transition matrix for the click model
% -------------------------------------------------------------------------
%
% Usage: [] = learnMarkovClickParams(self,vClicks)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 19:54:02
%


vClicksTmp = zeros(size(self.AnalysisSignal));
vClicksTmp(vClicks) = 1;
vClicks = vClicksTmp;

lenClicks = length(vClicks);

% 2 states: click or not
% 1...no click
% 2... a click
vStates = [0 1];
for aaState = 1:2,
    vIdxCurrEmission = find(vClicks == vStates(aaState));
    vIdxNextEmission = vIdxCurrEmission + 1;
    vIdxNextEmission(vIdxNextEmission > lenClicks) = [];
    
    numToNoClicks = sum(vClicks(vIdxNextEmission) == vStates(1));
    numToClicks   = sum(vClicks(vIdxNextEmission) == vStates(2));
    
    self.ModelParameters.ClickTransition(aaState,:) = ...
        [numToNoClicks numToClicks] / length(vIdxNextEmission);
end

% just to be sure that every row sums up to exactly one
self.ModelParameters.ClickTransition = ...
    bsxfun(...
        @rdivide, ...
        self.ModelParameters.ClickTransition, ...
        sum(self.ModelParameters.ClickTransition, 2) ...
        );


% End of file: learnMarkovClickParams.m
