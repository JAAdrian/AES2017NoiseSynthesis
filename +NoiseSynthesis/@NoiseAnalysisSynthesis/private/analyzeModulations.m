function [] = analyzeModulations(self)
%ANALYZEMODULATIONS Retrieve the analysis signal's modulation parameters
% -------------------------------------------------------------------------
%
% Usage: [] = analyzeModulations(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:01:58
%


% apply Mel or Gammatone weighting for modulation analysis
if strcmp(self.ModelParameters.ModulationFilterbank,'gammatone'),
    GammatoneApprox(self);
else
    MelTransformation(self);
end

computeLevelFluctuations(self);

analyzeModulationDepth(self);
analyzeCorrelationBands(self);
learnMarkovModulationParams(self);





% End of file: analyzeModulations.m
