function [] = analyzeModulations(obj)
%ANALYZEMODULATIONS Retrieve the analysis signal's modulation parameters
% -------------------------------------------------------------------------
%
% Usage: [] = analyzeModulations(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:01:58
%


% apply Mel or Gammatone weighting for modulation analysis
if strcmp(obj.ModelParameters.ModulationFilterbank, 'gammatone')
    GammatoneApprox(obj);
else
    MelTransformation(obj);
end

computeLevelFluctuations(obj);

analyzeModulationDepth(obj);
analyzeCorrelationBands(obj);
learnMarkovModulationParams(obj);





% End of file: analyzeModulations.m
