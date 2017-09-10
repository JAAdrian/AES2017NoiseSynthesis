function [vPDF, vQuantiles] = PiecewiseParetoPDF(obj,numPoints)
%PIECEWISEPARETOPDF Create piecewise Pareto PDF
% -------------------------------------------------------------------------
%
% Usage: [vPDF, vQuantiles] = PiecewiseParetoPDF(obj,numPoints)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:23:13
%

import NoiseSynthesis.external.*


vQuantiles = linspace(...
    obj.ModelParameters.Quantiles(1),...
    obj.ModelParameters.Quantiles(4),...
    numPoints);

vLowerParams = obj.ModelParameters.CDF(1,:);
vMidParams   = obj.ModelParameters.CDF(2,:);
vUpperParams = obj.ModelParameters.CDF(3,:);

QL  = obj.ModelParameters.Quantiles(2);
QU  = obj.ModelParameters.Quantiles(3);

[vLowerPDF,vUpperPDF] = computeParetoTailPDF(...
    vQuantiles,...
    vLowerParams,...
    vUpperParams,...
    [obj.ModelParameters.Quantiles(5),obj.ModelParameters.Quantiles(6)],...
    [QL,QU]);

QL2 = find(vQuantiles >= QL, 1, 'first');
QU2 = find(vQuantiles >= QU, 1, 'first');

vLowerPDF(QL2:end) = vLowerPDF(QL2-1);
vUpperPDF(1:QU2-1)   = vUpperPDF(QU2);

vMidPDF = normpdf(vQuantiles,vMidParams(1),vMidParams(2));

% source for joining the 3 curves:
% http://matlab.cheme.cmu.edu/2011/10/30/smooth-transitions-between-discontinuous-functions/
% or
% http://www.j-raedler.de/2010/10/smooth-transition-between-functions-with-tanh/

% to get in the correct range of magnitude I use the sigmas of the
% Pareto distributions.
alphaLow  = vLowerParams(2)/10;
alphaHigh = vUpperParams(2)/10;

% compute the smoothing sigmoids
vSigmoidLow  = sigmoidfun(vQuantiles,QL,alphaLow);
vSigmoidHigh = sigmoidfun(vQuantiles,QU,alphaHigh);

% smooth the PDFs
vLowerSmoothed = (1 - vSigmoidLow) .* vLowerPDF + vSigmoidLow .* vMidPDF;
vPDF = (1 - vSigmoidHigh) .* vLowerSmoothed + vSigmoidHigh .* vUpperPDF;

% scale to ensure a density
vPDF = vPDF.' / trapz(vQuantiles,vPDF);

%         figure(3);
%         plot(vQuantiles,[vLowerPDF', vMidPDF', vUpperPDF']);
%
%         figure(4);
%         plot(vQuantiles,vPDF/max(vPDF),'-o',...
%             vQuantiles,vSigmoidLow,vQuantiles,vSigmoidHigh);
%         legend('CDF','Lower Sigmoid','Upper Sigmoid');
%         grid on;
%
%         keyboard;
end


function [vLowerPDF,vUpperPDF] = computeParetoTailPDF(vQuantiles,vLowerParams,vUpperParams,vP,vQ)

vLowerPDF = vP(1) * gppdf(vQ(1)-vQuantiles, vLowerParams(1), vLowerParams(2));
vUpperPDF = (1-vP(2)) * gppdf(vQuantiles-vQ(2), vUpperParams(1), vUpperParams(2));

end


% End of file: PiecewiseParetoPDF.m
