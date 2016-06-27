function [vCDF, vQuantiles] = PiecewiseParetoCDF(self,numPoints)
%PIECEWISEPARETOCDF Create piecewise Pareto CDF
% -------------------------------------------------------------------------
%
% Usage: [vCDF, vQuantiles] = PiecewiseParetoCDF(self,numPoints)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:22:39
%

import NoiseSynthesis.external.*


vQuantiles = linspace(...
    self.ModelParameters.Quantiles(1),...
    self.ModelParameters.Quantiles(4),...
    numPoints);

vLowerParams = self.ModelParameters.CDF(1,:);
vMidParams   = self.ModelParameters.CDF(2,:);
vUpperParams = self.ModelParameters.CDF(3,:);

QL  = self.ModelParameters.Quantiles(2);
QU  = self.ModelParameters.Quantiles(3);

[vLowerCDF,vUpperCDF] = computeParetoTailCDF(...
    vQuantiles,...
    vLowerParams,...
    vUpperParams,...
    [self.ModelParameters.Quantiles(5),self.ModelParameters.Quantiles(6)],...
    [QL,QU]);

vMidCDF = normcdf(vQuantiles,vMidParams(1),vMidParams(2));

% source for joining the curves:
% http://matlab.cheme.cmu.edu/2011/10/30/smooth-transitions-between-discontinuous-functions/
% or
% http://www.j-raedler.de/2010/10/smooth-transition-between-functions-with-tanh/

% to get in the correct range of magnitude I use the sigmas of the
% Pareto distributions.
alphaLow  = vLowerParams(2)/20;
alphaHigh = vUpperParams(2)/20;

% compute the smoothing sigmoids
vSigmoidLow  = sigmoidfun(vQuantiles,QL,alphaLow);
vSigmoidHigh = sigmoidfun(vQuantiles,QU,alphaHigh);

% smooth the CDFs
vLowerSmoothed = (1 - vSigmoidLow) .* vLowerCDF + vSigmoidLow .* vMidCDF;
vCDF = (1 - vSigmoidHigh) .* vLowerSmoothed + vSigmoidHigh .* vUpperCDF;

% scale to ensure a max of 1
vCDF = vCDF.' / max(vCDF);

%         figure(1);
%         plot([vLowerCDF', vMidCDF', vUpperCDF']);
%
%         figure(2);
%         plot(vQuantiles,vCDF,'-o',vQuantiles,gradient(vCDF)/max(gradient(vCDF)),...
%             vQuantiles,vSigmoidLow,vQuantiles,vSigmoidHigh,...
%             QL*[1 1],[0 1],'--',QU*[1 1],[0 1],'--');
%         legend('CDF','PDF','Lower Sigmoid','Upper Sigmoid',...
%             'Lower Bound','Upper Bound');
%         grid on;
%
%         keyboard;
end

function [vLowerCDF,vUpperCDF] = computeParetoTailCDF(vQuantiles,vLowerParams,vUpperParams,vP,vQ)

vLowerCDF = vP(1) * (1 - gpcdf(vQ(1)-vQuantiles, vLowerParams(1), vLowerParams(2)));
vUpperCDF = vP(2) + (1-vP(2)) * gpcdf(vQuantiles-vQ(2), vUpperParams(1), vUpperParams(2));

end


% End of file: PiecewiseParetoCDF.m
