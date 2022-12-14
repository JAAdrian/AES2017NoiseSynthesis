function [vModulationCurve] = genmarkov(self,idxBand)
%GENMARKOV Generate Markov chain for modulation synthesis
% -------------------------------------------------------------------------
%
% Usage: [vModulationCurve] = genmarkov(self,idxBand)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:20:07
%


% random vector -> roll dice for the dicision to change the state
vStateChange = rand(1,self.lenLevelCurve);

% CDF of probabilities
mCumTrans = full(cumsum(self.ModelParameters.MarkovTransition{idxBand},2));

% normalize if sum is not 1
mCumTrans = bsxfun(@rdivide,mCumTrans,mCumTrans(:,end));

% first state is around value 1, i.e. no modulation
iCurrentState = find(self.ModelParameters.MarkovStateBoundaries >= 0,1,'first');

% start the chain evolution
vModulationCurve = zeros(self.lenLevelCurve,1);
for aaStep = 1:self.lenLevelCurve,
    % grab the random probability from the dice
    probStateChange = vStateChange(aaStep);
    
    % find the next state that is probable according to the
    % random vector
    vIdx = find(mCumTrans(iCurrentState,:) >= probStateChange);
    
    if vIdx,
        iState = vIdx(1);
    else
        % if the state change fails, take the default state, i.e.
        % no modulation
        iState = find(self.ModelParameters.MarkovStateBoundaries >= 0,1,'first');
    end
    
    % pick an RMS value that originate from the found new state
    vModulationCurve(aaStep) = ...
        (self.ModelParameters.MarkovStateBoundaries(iState,2)...
        - self.ModelParameters.MarkovStateBoundaries(iState,1)) ...
        * rand() + self.ModelParameters.MarkovStateBoundaries(iState,1);
    
    % update the current state
    iCurrentState = iState;
end

vModulationCurve = 10.^(vModulationCurve/20);


% End of file: genmarkov.m
