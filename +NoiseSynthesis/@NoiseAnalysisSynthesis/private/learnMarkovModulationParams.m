function [] = learnMarkovModulationParams(self)
%LEARNMARKOVMODULATIONPARAMS Learn the transition matrix for the modulation model
% -------------------------------------------------------------------------
%
% Usage: [] = learnMarkovModulationParams(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:03:02
%


decorrelateLevelFluctuations(self);

updateMarkovParams(self,...
    min(min(20*log10(self.mLevelCurvesDecorr + eps))),...
    max(max(20*log10(self.mLevelCurvesDecorr + eps)))...
    );

idxDefaultState = find(self.ModelParameters.MarkovStateBoundaries >= 0,1,'first');

lenLevCurve = self.lenLevelCurve;

self.ModelParameters.MarkovTransition = cell(self.numBands,1);
for aaBand = 1:self.numBands,
    vCurrLevels = 20*log10(self.mLevelCurvesDecorr(:,aaBand));
    
    % prevent dead paths and transients in the transition matrix
    self.ModelParameters.MarkovTransition{aaBand} = zeros(self.numStates);
    self.ModelParameters.MarkovTransition{aaBand}(...
        [1:idxDefaultState-1, idxDefaultState+1:end],idxDefaultState) = 1;
    self.ModelParameters.MarkovTransition{aaBand}(idxDefaultState,idxDefaultState+1) = 1;
    for bbState = 1:self.numStates,
        % index of samples in the current state
        vIdxCurrState = find(...
            vCurrLevels >= self.ModelParameters.MarkovStateBoundaries(bbState,1) & ...
            vCurrLevels <  self.ModelParameters.MarkovStateBoundaries(bbState,2)...
            );
        
        % index of the following samples
        vIdxFollowingEmission = vIdxCurrState + 1;
        % compensate for indices greater than the total length
        % of the level curve
        vIdxFollowingEmission(vIdxFollowingEmission > lenLevCurve) = [];
        
        % go through all samples that originate from the
        % current state and determine in which state they
        % change
        vNumSamplesToThisFollowing = zeros(self.numStates,1);
        for ccFollowingState = 1:self.numStates,
            vChangedToThisFollowingState = ...
                vCurrLevels(vIdxFollowingEmission)...
                >= self.ModelParameters.MarkovStateBoundaries(ccFollowingState,1) &...
                vCurrLevels(vIdxFollowingEmission)...
                < self.ModelParameters.MarkovStateBoundaries(ccFollowingState,2);
            % count the samples which changed to this next
            % state
            vNumSamplesToThisFollowing(ccFollowingState) = ...
                sum(vChangedToThisFollowingState);
        end
        % prevent some unrobust cases and
        % estimate the probability by dividing by the number of
        % samples that come from the current state
        % -> because every row of the transition matrix sums to
        %    one.
        if ...
                ~isempty(vIdxCurrState) && ...
                ~isempty(vIdxFollowingEmission) && ...
                sum(vNumSamplesToThisFollowing) > 0,
            
            self.ModelParameters.MarkovTransition{aaBand}(bbState,:) = ...
                vNumSamplesToThisFollowing / length(vIdxFollowingEmission);
        end
        
        % just to be sure that every row sums up to exactly one
        self.ModelParameters.MarkovTransition{aaBand} = ...
            bsxfun(...
                @rdivide, ...
                self.ModelParameters.MarkovTransition{aaBand}, ...
                sum(self.ModelParameters.MarkovTransition{aaBand}, 2) ...
                );
    end
    
    if any(sum(self.ModelParameters.MarkovTransition{aaBand},2)) <= 0.999,
        warning(['An anomaly occured while learning Markov ',...
            'Transitions in Band %d and State %d'],aaBand,bbState);
    end
    
    self.ModelParameters.MarkovTransition{aaBand} = ...
        sparse(self.ModelParameters.MarkovTransition{aaBand});
end


% End of file: learnMarkovModulationParams.m
