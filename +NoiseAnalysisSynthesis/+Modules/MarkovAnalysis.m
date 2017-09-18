classdef MarkovAnalysis < matlab.System
%MARKOVANALYSIS <purpose in one line!>
% -------------------------------------------------------------------------
% <Detailed description of the function>
%
% MarkovAnalysis Properties:
%	propA - <description>
%	propB - <description>
%
% MarkovAnalysis Methods:
%	doThis - <description>
%	doThat - <description>
%
% Author :  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date   :  09-Sep-2017 23:23:18
%

% History:  v0.1.0   initial version, 09-Sep-2017 (JA)
%
    
    
properties (Access = public)
    LevelFluctuationCurves;
    ModelParameters;
    
    GammaBands;
    
    StateBoundaries;
    MaxMarkovRmsLevel;
end


properties (SetAccess = protected, GetAccess = public)
    MarkovTransition;
end


properties (Access = protected)
    LevelFluctuationCurvesDecorr;
end

properties (Access = protected, Dependent)
    LenLevelCurve;
end


methods
    function [obj] = MarkovAnalysis(varargin)
        obj.setProperties(nargin, varargin{:})
    end
end


methods (Access = protected)
    function [] = stepImpl(obj)
        obj.decorrelateLevelFluctuations();
        
        obj.updateMarkovParameters(...
            min(min(20*log10(obj.LevelFluctuationCurvesDecorr + eps))),...
            max(max(20*log10(obj.LevelFluctuationCurvesDecorr + eps)))...
            );
        
        idxDefaultState = find(obj.StateBoundaries >= 0, 1, 'first');
        
        obj.MarkovTransition = cell(obj.NumBands,1);
        for iBand = 1:obj.NumBands
            currLevels = 20*log10(obj.LevelFluctuationCurvesDecorr(:, iBand));
            
            % prevent dead paths and transients in the transition matrix
            obj.MarkovTransition{iBand} = zeros(obj.numStates);
            obj.MarkovTransition{iBand}(...
                [1:idxDefaultState-1, idxDefaultState+1:end], idxDefaultState) = 1;
            obj.MarkovTransition{iBand}(idxDefaultState, idxDefaultState+1) = 1;
            for jState = 1:obj.NumStates
                % index of samples in the current state
                idxCurrState = find(...
                    currLevels >= obj.StateBoundaries(jState, 1) & ...
                    currLevels <  obj.StateBoundaries(jState, 2)...
                    );
                
                % index of the following samples
                idxFollowingEmission = idxCurrState + 1;
                % compensate for indices greater than the total length
                % of the level curve
                idxFollowingEmission(idxFollowingEmission > obj.LenLevelCurve) = [];
                
                % go through all samples that originate from the
                % current state and determine in which state they
                % change
                numSamplesToThisFollowing = zeros(obj.NumStates, 1);
                for kFollowingState = 1:obj.NumStates
                    changedToThisFollowingState = ...
                        currLevels(idxFollowingEmission)...
                        >= obj.StateBoundaries(kFollowingState,1) &...
                        currLevels(idxFollowingEmission)...
                        < obj.StateBoundaries(kFollowingState,2);
                    % count the samples which changed to this next
                    % state
                    numSamplesToThisFollowing(kFollowingState) = sum(...
                        changedToThisFollowingState ...
                        );
                end
                % prevent some unrobust cases and
                % estimate the probability by dividing by the number of
                % samples that come from the current state
                % -> because every row of the transition matrix sums to
                %    one.
                if ...
                        ~isempty(idxCurrState) && ...
                        ~isempty(idxFollowingEmission) && ...
                        sum(numSamplesToThisFollowing) > 0
                    
                    obj.MarkovTransition{iBand}(jState, :) = ...
                        numSamplesToThisFollowing / length(idxFollowingEmission);
                end
                
                % just to be sure that every row sums up to exactly one
                obj.MarkovTransition{iBand} = ...
                    bsxfun(...
                    @rdivide, ...
                    obj.MarkovTransition{iBand}, ...
                    sum(obj.MarkovTransition{iBand}, 2) ...
                    );
            end
            
            if any(sum(obj.MarkovTransition{iBand},2)) <= 0.999
                warning(['An anomaly occured while learning Markov ',...
                    'Transitions in Band %d and State %d'], iBand, jState);
            end
            
            obj.MarkovTransition{iBand} = sparse(obj.MarkovTransition{iBand});
        end
    end
    
    
    
    function [] = decorrelateLevelFluctuations(obj)
        import NoiseSynthesis.External.*
        
        % compute nonparametric location parameter -> median
        medianValues = median(obj.LevelFluctuationCurves, 1);
        
        % get the mixing matrix based on the inter-band correlation
        mixingMatrix = computeBandMixingMatrix(...
            obj.GammaBands ...
            );
        
        % initialize the decorrelated bands
        obj.LevelFluctuationCurvesDecorr = obj.LevelFluctuationCurves;
        
        % zscore for equal energy
        obj.LevelFluctuationCurvesDecorr = bsxfun(...
            @minus, ...
            obj.LevelFluctuationCurvesDecorr, ...
            mean(obj.LevelFluctuationCurvesDecorr, 1) ...
            );
        obj.LevelFluctuationCurvesDecorr = bsxfun(...
            @rdivide, ...
            obj.LevelFluctuationCurvesDecorr, ...
            std(obj.LevelFluctuationCurvesDecorr, [], 1) ...
            );
        
        % decorrelate using numberically robust pseudo-inverse of the mixing matrix
        obj.LevelFluctuationCurvesDecorr = ...
            (pinv(mixingMatrix') * obj.LevelFluctuationCurvesDecorr.').';
        
        % normalize by the largest value over all values of the decorr. level
        % fluctuations
        maxVal = max(max(abs(obj.LevelFluctuationCurvesDecorr)));
        obj.LevelFluctuationCurvesDecorr = obj.LevelFluctuationCurvesDecorr / maxVal;
        
        %restore previous median
        obj.LevelFluctuationCurvesDecorr = bsxfun(...
            @plus, ...
            obj.LevelFluctuationCurvesDecorr, ...
            medianValues - median(obj.LevelFluctuationCurvesDecorr, 1) ...
            );
        
        % set values smaller than the smallest Markov state and simply add 1
        idxOutOfRange = find(...
            obj.LevelFluctuationCurvesDecorr < 10^(obj.StateBoundaries(1)/20) ...
            );
        obj.LevelFluctuationCurvesDecorr(idxOutOfRange) = abs(obj.LevelFluctuationCurvesDecorr(idxOutOfRange)) + 1;
    end
    
    function [] = updateMarkovParameters(obj)
        obj.MaxMarkovRmsLevel = maxVal;
        
        centralPart = -3:3;
        lowerPart   = [minVal, (minVal + centralPart(1))/2];
        upperPart   = [(maxVal + centralPart(end))/2, maxVal];
        
        obj.StateBoundaries = [lowerPart, centralPart, upperPart].';
        
        obj.StateBoundaries = [
            obj.StateBoundaries(1:end-1), ...
            obj.StateBoundaries(2:end)
            ];
    end
end
end




% End of file: MarkovAnalysis.m
