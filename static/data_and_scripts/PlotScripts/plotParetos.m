% <purpose of this file>
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  22-Sep-2015 17:56:01
% Updated:  <>

clear;
close all;


addpath('deps');


[vSignal,fs] = returnPlotSignal();
vSignal      = vSignal(1:min(round(5*fs),length(vSignal)),1);


numPoints  = 1000;
vQuantiles = linspace(min(vSignal),max(vSignal),numPoints);

PL = 0.05;
PU = 0.95;

partails = paretotails(vSignal,PL,PU);

normmean = mean(vSignal);
normstd  = std(vSignal);

vMidPDF = normpdf(vQuantiles,normmean,normstd);

[dens,densx] = ksdensity(vSignal,'npoints',numPoints);

percRangeLower = [0.001 0.20];
percRangeUpper = [0.80 0.999];

idxLower = find(vQuantiles >= prctile(vSignal,...
    percRangeLower(2)*100),1,'first');
idxUpper = find(vQuantiles >= prctile(vSignal,...
    percRangeUpper(1)*100),1,'first');

[perclower] = intersections(...
    densx(1:idxLower),dens(1:idxLower),...
    vQuantiles(1:idxLower),vMidPDF(1:idxLower) ...
    );

[percupper] = intersections(...
    vQuantiles(idxUpper:end),vMidPDF(idxUpper:end),...
    densx(idxUpper:end),dens(idxUpper:end) ...
    );

[y,x] = ecdf(vSignal);
x = (x(1:end-1) + x(2:end)) / 2;
y = (y(1:end-1) + y(2:end)) / 2;

perclower = interp1(x,y,perclower,'linear');
percupper = interp1(x,y,percupper,'linear');


% if no intersections found: use defaults
if isempty(perclower),
    perclower = 0.05;
else
    perclower  = perclower(...
        perclower >= percRangeLower(1) & ...
        perclower <= percRangeLower(2));
    perclower = perclower(1);
end
if isempty(percupper),
    percupper = 0.95;
else
    percupper = percupper(...
        percupper >= percRangeUpper(1) & ...
        percupper <= percRangeUpper(2));
    percupper = percupper(end);
end


partailsadjusted = paretotails(vSignal,perclower,percupper);

vLowerParams = partailsadjusted.lowerparams;
vUpperParams = partailsadjusted.upperparams;

PL = partailsadjusted.boundary(1);
PU = partailsadjusted.boundary(2);

self.ModelParameters.Quantiles = ...
    prctile(...
    vSignal, ...
    [0, PL*100, PU*100, 100]);
self.ModelParameters.Quantiles(end+1:end+2) = [PL; PU];

self.ModelParameters.CDF = [
    vLowerParams;
    normmean, normstd;
    vUpperParams];

vParetoPDF     = PiecewiseParetoPDF(self,numPoints);
[vDens,vXDens] = ksdensity(vSignal,'npoints',numPoints);

MSE = mean( (vDens.' - vParetoPDF) .^ 2);
p   = bhattacharyya(vDens.',vParetoPDF);

lMSE = mean((log10(vDens.') - log10(vParetoPDF)).^2);


%% plot that jazz
close all;
hf = figure(1);

ha(1) = axes('position',[0.13 0.11 0.775 0.8]);

hold(ha(1),'on');
plot(ha(1),vXDens,vDens,'color',0.7*[1 1 1]);
plot(ha(1),vQuantiles,normpdf(vQuantiles,normmean,normstd),'k--');
plot(ha(1),vQuantiles,vParetoPDF,'k');
hold(ha(1),'off');

set(ha(1),'YScale','log');
axis(ha(1),[-0.024,vQuantiles(end),10^-5,inf]);
xlabel(ha(1),'Amplitude x');
ylabel(ha(1),'Probability Density p(x) (log)');
legend(ha(1),...
    'Kernel Density Estimate',...
    'Normal Distribution',...
    'Piecewise Pareto Distribution',...
    'location','southwest');
grid on;





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

% End of file: plotParetos.m
