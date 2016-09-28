% <purpose of this file>
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  10-Mar-2016 18:43:20
%

clear;
close all;

rms = @std;


examplePoint = 0.28;
xStart       = -1;
xStop        = 1.2;


x = linspace(xStart, xStop, 1e4);
F = linspace(eps, 1-1e-4, 1e4);

muGauss    = 0;
sigmaGauss = 0.3;
bRayl   = 0.25;
muRayl  = bRayl * sqrt(pi/2);
medRayl = bRayl * sqrt(2 * log(2));

gaussCDF = normcdf(x, muGauss, sigmaGauss);
raylCDF  = raylcdf(x, bRayl);

[xError, errorCDF] = deal(zeros(size(F)));
for percentile = 1:length(F),
    percGauss = find(gaussCDF >= F(percentile), 1, 'first');
    percRayl  = find(raylCDF >= F(percentile), 1, 'first');

    xError(percentile) = x(percGauss) - x(percRayl);
    errorCDF(percentile) = F(percentile);
end

fprintf('Error RMS: %g\n',rms(xError));

hf = figure;
plot(x, gaussCDF, 'color', 0.6*[1 1 1]); hold on;
plot(x, raylCDF, 'k');
plot(xError, errorCDF, '--k'); hold off;

ha = gca;

xInitial = x(find(gaussCDF >= examplePoint, 1, 'first'));
xTarget  = x(find(raylCDF >= examplePoint, 1, 'first'));
xError   = xError(find(errorCDF >= examplePoint, 1, 'first'));

hold on;
plot(xInitial*[1 1], examplePoint*[0 1], 'k:');
plot(xInitial, examplePoint, 'ok');

plot(xTarget*[1 1], examplePoint*[0 1], 'k:');
plot(xTarget, examplePoint, 'ok');
hold off;


xlim([xStart xStop]);
xlabel('Amplitude y');
ylabel('CDF F(y)');
legend('Initial', 'Target', 'Error',...
    'Location', 'northwest');
grid on;

set(ha, 'xtick', -1:0.2:1);

xtick = get(ha, 'xtick');
xtick = sort([xtick, xInitial, xTarget]);

xtick([5,8]) = [];

xticklabel = cellfun(@num2str,num2cell(xtick),'uni',0);
xticklabel{5} = '$\widetilde{y}_g(n)$';
xticklabel{7} = '$y_g(n)$';

set(ha,...
    'xtick',xtick,...
    'xticklabel',xticklabel...
    );




set(ha, 'xgrid', 'off');
set(ha, 'TickLabelInterpreter', 'latex');

plotMarker = findobj('marker','o');
set(plotMarker,'MarkerSize',5);

xArrow = [xInitial + 0.05, xTarget - 0.05];
yArrow = [examplePoint, examplePoint];
hAnno = myannotation(...
    'textarrow', xArrow, yArrow, ...
    'HeadLength', 6, 'HeadWidth', 6);





%-------------------- Licence ---------------------------------------------
% Copyright (c) 2016, J.-A. Adrian
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

% End of file: plotErrorDistribution.m
