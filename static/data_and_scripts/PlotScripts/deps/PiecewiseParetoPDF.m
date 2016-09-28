function [vPDF, vQuantiles] = PiecewiseParetoPDF(self,numPoints)
%PIECEWISEPARETOPDF <purpose in one line!>
% -------------------------------------------------------------------------
% <Detailed description of the function>
% 
% Usage: [y] = PiecewiseParetoPDF(input)
% 
%   Input:   ---------
% 
%  Output:   ---------
% 
% 
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  22-Sep-2015 18:43:54
% Updated:  <>
% 



vQuantiles = linspace(...
    self.ModelParameters.Quantiles(1),...
    self.ModelParameters.Quantiles(4),...
    numPoints);

vLowerParams = self.ModelParameters.CDF(1,:);
vMidParams   = self.ModelParameters.CDF(2,:);
vUpperParams = self.ModelParameters.CDF(3,:);

QL  = self.ModelParameters.Quantiles(2);
QU  = self.ModelParameters.Quantiles(3);

[vLowerPDF,vUpperPDF] = computeParetoTailPDF(...
    vQuantiles,...
    vLowerParams,...
    vUpperParams,...
    [self.ModelParameters.Quantiles(5),self.ModelParameters.Quantiles(6)],...
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

function [vSigmoid] = sigmoidfun(x,x0,alpha)
vSigmoid = 1./(1 + exp(-(x - x0) / alpha));
% vSigmoid = 0.5 + 0.5*tanh((x-x0)/alpha);
end



%-------------------- Licence ---------------------------------------------
% Copyright (c) 2015, J.-A. Adrian
% Institute for Hearing Technology and Audiology
% Jade University of Applied Sciences
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
%
%	1. Redistributions of source code must retain the above copyright
%	   notice, this list of conditions and the following disclaimer.
%
%	2. Redistributions in binary form must reproduce the above copyright
%	   notice, this list of conditions and the following disclaimer in
%	   the documentation and/or other materials provided with the
%	   distribution.
%
%	3. Neither the name of the copyright holder nor the names of its
%	   contributors may be used to endorse or promote products derived
%	   from this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
% IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
% TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
% PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
% HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
% TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

% End of file: PiecewiseParetoPDF.m
