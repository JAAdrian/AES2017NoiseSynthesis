function [cdf, quantiles] = PiecewiseParetoCDF(obj, numPoints)
%PIECEWISEPARETOCDF Create piecewise Pareto CDF
% -------------------------------------------------------------------------
%
% Usage: [vCDF, vQuantiles] = PiecewiseParetoCDF(obj,numPoints)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:22:39
%

import NoiseSynthesis.External.*


quantiles = linspace(...
    obj.ModelParameters.Quantiles(1), ...
    obj.ModelParameters.Quantiles(4), ...
    numPoints ...
    );

lowerParams = obj.ModelParameters.CDF(1, :);
midParams   = obj.ModelParameters.CDF(2, :);
upperParams = obj.ModelParameters.CDF(3, :);

ql  = obj.ModelParameters.Quantiles(2);
qu  = obj.ModelParameters.Quantiles(3);

[lowerCDF, upperCDF] = computeParetoTailCDF(...
    quantiles, ...
    lowerParams, ...
    upperParams, ...
    [obj.ModelParameters.Quantiles(5), obj.ModelParameters.Quantiles(6)],...
    [ql, qu] ...
    );

midCDF = normcdf(quantiles,midParams(1), midParams(2));

% source for joining the curves:
% http://matlab.cheme.cmu.edu/2011/10/30/smooth-transitions-between-discontinuous-functions/
% or
% http://www.j-raedler.de/2010/10/smooth-transition-between-functions-with-tanh/

% to get in the correct range of magnitude we use the sigmas of the
% Pareto distributions.
alphaLow  = lowerParams(2)/20;
alphaHigh = upperParams(2)/20;

% compute the smoothing sigmoids
vSigmoidLow  = sigmoidfun(quantiles, ql, alphaLow);
vSigmoidHigh = sigmoidfun(quantiles, qu, alphaHigh);

% smooth the CDFs
vLowerSmoothed = (1 - vSigmoidLow) .* lowerCDF + vSigmoidLow .* midCDF;
cdf = (1 - vSigmoidHigh) .* vLowerSmoothed + vSigmoidHigh .* upperCDF;

% scale to ensure a max of 1
cdf = cdf.' / max(cdf);

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

function [lowerCDF, upperCDF] = computeParetoTailCDF(quantiles, lowerParams, upperParams, p, q)

lowerCDF = p(1) * (1 - gpcdf(q(1)-quantiles, lowerParams(1), lowerParams(2)));
upperCDF = p(2) + (1-p(2)) * gpcdf(quantiles-q(2), upperParams(1), upperParams(2));

end


% End of file: PiecewiseParetoCDF.m
