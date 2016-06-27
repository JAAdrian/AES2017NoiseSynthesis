function [vSigOut] = shapeAmplitudeDistr(self,vSigIn)
%SHAPEAMPLITUDEDISTR Use percentile transform. method to shape amplitude distribution
% -------------------------------------------------------------------------
%
% Usage: [y] = shapeAmplitudeDistr(input)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:09:33
%

import NoiseSynthesis.external.*


% 'inverse method' or 'percentile transformation method' stated
% in Papoulis.

[vCDFsignal,vXSignal] = ecdf(vSigIn);
vXSignal  = vXSignal(2:end);
vCDFsignal = (vCDFsignal(1:end-1) + vCDFsignal(2:end))/2;

vUniformlyDistrNoise = interp1(vXSignal,vCDFsignal,vSigIn,'linear','extrap');

numPoints = 1000;
switch self.ModelParameters.AmplitudeModel,
    case 'gmm',
        vQuantiles = linspace(...
            self.ModelParameters.Quantiles(1),...
            self.ModelParameters.Quantiles(2),...
            numPoints).';
        
        mCDFs = zeros(numPoints,self.ModelParameters.NumGaussModels);
        for aaGauss = 1:self.ModelParameters.NumGaussModels,
            mCDFs(:,aaGauss) = ...
                self.ModelParameters.CDF{2}(aaGauss) * ...
                normcdf(...
                vQuantiles,...
                self.ModelParameters.CDF{1}(aaGauss),...
                sqrt(self.ModelParameters.CDF{3}(aaGauss))...
                );
        end
        vCDF = sum(mCDFs,2);
        
    case 'alpha'
        import NoiseSynthesis.stbl_matlab.*
        
        vQuantiles = linspace(...
            self.ModelParameters.Quantiles(1),...
            self.ModelParameters.Quantiles(2),...
            numPoints);
        
        vCDF = stblcdf(...
            vQuantiles,...
            self.ModelParameters.CDF(1),...
            self.ModelParameters.CDF(2),...
            self.ModelParameters.CDF(3),...
            self.ModelParameters.CDF(4)...
            );
        
        %%%% make that jazz robust %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [vQuantiles,vCDF] = makeCDFrobust(vQuantiles,vCDF);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case {'full','percentile'},
        vCDF       = self.ModelParameters.CDF;
        vQuantiles = self.ModelParameters.Quantiles;
        
    case 'pareto',
        [vCDF, vQuantiles] = PiecewiseParetoCDF(self,numPoints);
        
        %%%% make that jazz robust %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [vQuantiles,vCDF] = makeCDFrobust(vQuantiles,vCDF);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

vSigOut = interp1(vCDF,vQuantiles,...
    vUniformlyDistrNoise,...
    'linear','extrap');



% End of file: shapeAmplitudeDistr.m
