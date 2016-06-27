function [mMixingMatrix] = computeMixingMatrix(self,Freq,SourcePSDbin)
%COMPUTEMIXINGMATRIX Compute the mixing matrix for the desired spatial coherence
% -------------------------------------------------------------------------
%
% Usage: [mMixingMatrix] = computeMixingMatrix(self,Freq,SourcePSDbin)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:15:23
%


mGamma = zeros(self.NumSensorSignals);
for ppSensor = 1:self.NumSensorSignals,
    for qqSensor = 1:ppSensor-1,
        % account for possible complex conjugate sensor-sensor pairings
        % if a coherence of a directive sound source is desired
        mGamma(ppSensor,qqSensor) = conj(self.hCohereFun(...
            Freq,...
            self.mDistances(ppSensor,qqSensor),...
            self.mTheta(ppSensor,qqSensor,:),...
            SourcePSDbin...
            ));
    end
    for qqSensor = ppSensor:self.NumSensorSignals,
        mGamma(ppSensor,qqSensor) = self.hCohereFun(...
            Freq,...
            self.mDistances(ppSensor,qqSensor),...
            self.mTheta(ppSensor,qqSensor,:),...
            SourcePSDbin...
            );
    end
end

[mEigVecs,mEigVals]            = eig(mGamma);
mEigVals(abs(mEigVals) <= eps) = 0; % prevent numerical issues

mMixingMatrix = sqrt(mEigVals) * mEigVecs';



% End of file: computeMixingMatrix.m
