function [] = computeTheta(self)
%COMPUTETHETA Compute the incident angles theta between sources and sensors
% -------------------------------------------------------------------------
%
% Usage: [] = computeTheta(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:14:55
%


for aaSource = 1:self.NumSources,
    for ppSensor = 1:self.NumSensorSignals,
        for qqSensor = 1:self.NumSensorSignals,
            
            if ppSensor ~= qqSensor,
                % central point between both sensors
                vCenterBetweenSensors = ...
                    0.5*(...
                    self.ModelParameters.SensorPositions(:,ppSensor)...
                    + self.ModelParameters.SensorPositions(:,qqSensor)...
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
                    
                    a = self.ModelParameters.SourcePosition(:,aaSource) - ...
                        vCenterBetweenSensors;
                    b = abs(self.ModelParameters.SensorPositions(:,ppSensor) ...
                        - self.ModelParameters.SensorPositions(:,qqSensor));
                    
                    % angle between (vCenter to 2nd sensor)
                    % and (vCenter to Source) in 2D plane via
                    % dot product
                    angle = acos( dot(a,b) / (norm(a) * norm(b)) );
                    
                    self.mTheta(ppSensor,qqSensor,aaSource) = angle;
            end
        end % ppSensor
    end % qqSensor
end % aaSource


% End of file: computeTheta.m
