function [vSigOut] = shapeAmplitudeDistr(obj,vSigIn)
%SHAPEAMPLITUDEDISTR Use percentile transform. method to shape amplitude distribution
% -------------------------------------------------------------------------
%
% Usage: [y] = shapeAmplitudeDistr(input)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:09:33
%

import NoiseSynthesis.External.*


% 'inverse method' or 'percentile transformation method' stated
% in Papoulis.

[vCDFsignal,vXSignal] = ecdf(vSigIn);
vXSignal  = vXSignal(2:end);
vCDFsignal = (vCDFsignal(1:end-1) + vCDFsignal(2:end))/2;

vUniformlyDistrNoise = interp1(vXSignal,vCDFsignal,vSigIn,'linear','extrap');

numPoints = 1000;
switch obj.ModelParameters.AmplitudeModel
    case 'gmm'
        vQuantiles = linspace(...
            obj.ModelParameters.Quantiles(1),...
            obj.ModelParameters.Quantiles(2),...
            numPoints).';
        
        mCDFs = zeros(numPoints,obj.ModelParameters.NumGaussModels);
        for aaGauss = 1:obj.ModelParameters.NumGaussModels
            mCDFs(:,aaGauss) = ...
                obj.ModelParameters.CDF{2}(aaGauss) * ...
                normcdf(...
                vQuantiles,...
                obj.ModelParameters.CDF{1}(aaGauss),...
                sqrt(obj.ModelParameters.CDF{3}(aaGauss))...
                );
        end
        vCDF = sum(mCDFs,2);
        
    case 'alpha'
        import NoiseSynthesis.stbl_matlab.*
        
        vQuantiles = linspace(...
            obj.ModelParameters.Quantiles(1),...
            obj.ModelParameters.Quantiles(2),...
            numPoints);
        
        vCDF = stblcdf(...
            vQuantiles,...
            obj.ModelParameters.CDF(1),...
            obj.ModelParameters.CDF(2),...
            obj.ModelParameters.CDF(3),...
            obj.ModelParameters.CDF(4)...
            );
        
        %%%% make that jazz robust %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [vQuantiles,vCDF] = makeCDFrobust(vQuantiles,vCDF);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case {'full','percentile'}
        vCDF       = obj.ModelParameters.CDF;
        vQuantiles = obj.ModelParameters.Quantiles;
        
    case 'pareto'
        [vCDF, vQuantiles] = PiecewiseParetoCDF(obj,numPoints);
        
        %%%% make that jazz robust %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [vQuantiles,vCDF] = makeCDFrobust(vQuantiles,vCDF);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

vSigOut = interp1(vCDF,vQuantiles,...
    vUniformlyDistrNoise,...
    'linear','extrap');



% End of file: shapeAmplitudeDistr.m
