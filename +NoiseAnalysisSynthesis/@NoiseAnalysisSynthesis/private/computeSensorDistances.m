function [] = computeSensorDistances(obj)
%COMPUTESENSORDISTANCES Compute the inter-sensor distances
% -------------------------------------------------------------------------
%
% Usage: [] = computeSensorDistances(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:13:51
%


% compute euclidean distances
for ppSensor = 1:obj.NumSensorSignals
    for qqSensor = 1:obj.NumSensorSignals
        obj.mDistances(ppSensor,qqSensor) = ...
            norm( obj.ModelParameters.SensorPositions(:,ppSensor) -...
            obj.ModelParameters.SensorPositions(:,qqSensor) );
    end
end




% End of file: computeSensorDistances.m
