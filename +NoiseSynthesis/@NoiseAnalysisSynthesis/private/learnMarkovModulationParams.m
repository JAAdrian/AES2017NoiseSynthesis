function [] = learnMarkovModulationParams(obj)
%LEARNMARKOVMODULATIONPARAMS Learn the transition matrix for the modulation model
% -------------------------------------------------------------------------
%
% Usage: [] = learnMarkovModulationParams(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:03:02
%


decorrelateLevelFluctuations(obj);

updateMarkovParams(obj,...
    min(min(20*log10(obj.mLevelCurvesDecorr + eps))),...
    max(max(20*log10(obj.mLevelCurvesDecorr + eps)))...
    );

idxDefaultState = find(obj.ModelParameters.MarkovStateBoundaries >= 0,1,'first');

lenLevCurve = obj.lenLevelCurve;

obj.ModelParameters.MarkovTransition = cell(obj.numBands,1);
for aaBand = 1:obj.numBands
    vCurrLevels = 20*log10(obj.mLevelCurvesDecorr(:,aaBand));
    
    % prevent dead paths and transients in the transition matrix
    obj.ModelParameters.MarkovTransition{aaBand} = zeros(obj.numStates);
    obj.ModelParameters.MarkovTransition{aaBand}(...
        [1:idxDefaultState-1, idxDefaultState+1:end],idxDefaultState) = 1;
    obj.ModelParameters.MarkovTransition{aaBand}(idxDefaultState,idxDefaultState+1) = 1;
    for bbState = 1:obj.numStates
        % index of samples in the current state
        vIdxCurrState = find(...
            vCurrLevels >= obj.ModelParameters.MarkovStateBoundaries(bbState,1) & ...
            vCurrLevels <  obj.ModelParameters.MarkovStateBoundaries(bbState,2)...
            );
        
        % index of the following samples
        vIdxFollowingEmission = vIdxCurrState + 1;
        % compensate for indices greater than the total length
        % of the level curve
        vIdxFollowingEmission(vIdxFollowingEmission > lenLevCurve) = [];
        
        % go through all samples that originate from the
        % current state and determine in which state they
        % change
        vNumSamplesToThisFollowing = zeros(obj.numStates,1);
        for ccFollowingState = 1:obj.numStates
            vChangedToThisFollowingState = ...
                vCurrLevels(vIdxFollowingEmission)...
                >= obj.ModelParameters.MarkovStateBoundaries(ccFollowingState,1) &...
                vCurrLevels(vIdxFollowingEmission)...
                < obj.ModelParameters.MarkovStateBoundaries(ccFollowingState,2);
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
                sum(vNumSamplesToThisFollowing) > 0
            
            obj.ModelParameters.MarkovTransition{aaBand}(bbState,:) = ...
                vNumSamplesToThisFollowing / length(vIdxFollowingEmission);
        end
        
        % just to be sure that every row sums up to exactly one
        obj.ModelParameters.MarkovTransition{aaBand} = ...
            bsxfun(...
                @rdivide, ...
                obj.ModelParameters.MarkovTransition{aaBand}, ...
                sum(obj.ModelParameters.MarkovTransition{aaBand}, 2) ...
                );
    end
    
    if any(sum(obj.ModelParameters.MarkovTransition{aaBand},2)) <= 0.999
        warning(['An anomaly occured while learning Markov ',...
            'Transitions in Band %d and State %d'],aaBand,bbState);
    end
    
    obj.ModelParameters.MarkovTransition{aaBand} = ...
        sparse(obj.ModelParameters.MarkovTransition{aaBand});
end


% End of file: learnMarkovModulationParams.m
