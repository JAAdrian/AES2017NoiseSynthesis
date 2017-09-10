function [] = computeTheta(obj)
%COMPUTETHETA Compute the incident angles theta between sources and sensors
% -------------------------------------------------------------------------
%
% Usage: [] = computeTheta(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:14:55
%


for aaSource = 1:obj.NumSources
    for ppSensor = 1:obj.NumSensorSignals
        for qqSensor = 1:obj.NumSensorSignals
            
            if ppSensor ~= qqSensor
                % central point between both sensors
                vCenterBetweenSensors = ...
                    0.5*(...
                    obj.ModelParameters.SensorPositions(:,ppSensor)...
                    + obj.ModelParameters.SensorPositions(:,qqSensor)...
                    );
                
                %{
                                tau = d * cos(theta) / c
                                tau == pi/2 -> no delay


                           y
                            ^                     S
                            |                   o
                            |                  *
                            |                 *
                            |                * )
                            |               * theta
                            |              *   )
                            ---o---------x--------o--------> x
                              M1         Mm       M2

                            dot product:
                            a * b = |a|*|b| * cos(theta)
                            theta = acos(a * b / (|a|*|b|));

                            with
                                a = vec(Mm -> M2)
                                b = vec(Mm ->  S)
                    %}
                    
                    a = obj.ModelParameters.SourcePosition(:,aaSource) - ...
                        vCenterBetweenSensors;
                    b = abs(obj.ModelParameters.SensorPositions(:,ppSensor) ...
                        - obj.ModelParameters.SensorPositions(:,qqSensor));
                    
                    % angle between (vCenter to 2nd sensor)
                    % and (vCenter to Source) in 2D plane via
                    % dot product
                    angle = acos( dot(a,b) / (norm(a) * norm(b)) );
                    
                    obj.mTheta(ppSensor,qqSensor,aaSource) = angle;
            end
        end % ppSensor
    end % qqSensor
end % aaSource


% End of file: computeTheta.m
