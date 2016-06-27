function [] = computeSensorDistances(self)
%COMPUTESENSORDISTANCES Compute the inter-sensor distances
% -------------------------------------------------------------------------
%
% Usage: [] = computeSensorDistances(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:13:51
%


% compute euclidean distances
for ppSensor = 1:self.NumSensorSignals,
    for qqSensor = 1:self.NumSensorSignals,
        self.mDistances(ppSensor,qqSensor) = ...
            norm( self.ModelParameters.SensorPositions(:,ppSensor) -...
            self.ModelParameters.SensorPositions(:,qqSensor) );
    end
end




% End of file: computeSensorDistances.m
