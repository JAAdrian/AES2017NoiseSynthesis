function [mMixingMatrix] = computeMixingMatrix(obj, freq, sourcePsdBin)
%COMPUTEMIXINGMATRIX Compute the mixing matrix for the desired spatial coherence
% -------------------------------------------------------------------------
%
% Usage: [mMixingMatrix] = computeMixingMatrix(obj,Freq,SourcePSDbin)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:15:23
%


mGamma = zeros(obj.NumSensorSignals);
for ppSensor = 1:obj.NumSensorSignals
    for qqSensor = 1:ppSensor-1
        % account for possible complex conjugate sensor-sensor pairings
        % if a coherence of a directive sound source is desired
        mGamma(ppSensor,qqSensor) = conj(obj.hCohereFun(...
            freq,...
            obj.mDistances(ppSensor,qqSensor),...
            obj.mTheta(ppSensor,qqSensor,:),...
            sourcePsdBin...
            ));
    end
    for qqSensor = ppSensor:obj.NumSensorSignals
        mGamma(ppSensor,qqSensor) = obj.hCohereFun(...
            freq,...
            obj.mDistances(ppSensor,qqSensor),...
            obj.mTheta(ppSensor,qqSensor,:),...
            sourcePsdBin...
            );
    end
end

[mEigVecs,mEigVals]            = eig(mGamma);
mEigVals(abs(mEigVals) <= eps) = 0; % prevent numerical issues

mMixingMatrix = sqrt(mEigVals) * mEigVecs';



% End of file: computeMixingMatrix.m
