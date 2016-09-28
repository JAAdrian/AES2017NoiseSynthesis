function [] = plotNSAndLine(hBoxes,hAxes,yOffset,WingletLen,cLineParams,cAstParams)
%PLOTNSANDLINE <purpose in one line!>
% -------------------------------------------------------------------------
% <Detailed description of the function>
%
% Usage: [] = plotNSAndLine(hBox1,hBox2,hAxes,yOffset,WingletLength,cLineParams,cAstParams)
%
%   Input:   ---------
%
%  Output:   ---------
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  04-Feb-2016 14:48:52
% Updated:  <>
%


if nargin < 6 || isempty(cAstParams),
    cAstParams = {'HorizontalAlignment','center'};
end
if nargin < 5 || isempty(cLineParams),
    cLineParams = {'linewidth',2};
end
if nargin < 4 || isempty(WingletLen),
    WingletLen = 1.3;
end
if nargin < 3 || isempty(yOffset),
    yOffset = 0;
end
if nargin < 2 || isempty(hAxes),
    hAxes = gca;
end

numBoxes = length(hBoxes);

vXBoxes = get(hBoxes,'XData');

lineHeight = get(hAxes,'ylim');
lineHeight = lineHeight(2) * (1 - 0.02) + yOffset;

vLineStarts = cellfun(@(x) mean([x(2), x(3)]),vXBoxes);
vLineStartsTmp = mean([vLineStarts(1), cellfun(@(x) x(3),vXBoxes(1))]);
vLineStartsTmp(end+1:numBoxes) = ...
    mean([vLineStarts(2:end), cellfun(@(x) x(2),vXBoxes(2:end))],2);
vLineStarts = vLineStartsTmp;

WingletLen = WingletLen * ones(numBoxes,1);
WingletLen(1) = WingletLen(1) * (1 + 0.6);

for aaBox = 1:numBoxes-1,
    thisLineStart  = vLineStarts(aaBox);
    thisLineEnd    = vLineStarts(aaBox + 1);
    
    vX = [thisLineStart,              thisLineStart, thisLineEnd, thisLineEnd];
    vY = [lineHeight-WingletLen(aaBox), lineHeight,    lineHeight,  lineHeight-WingletLen(aaBox+1)];
    
    hold(hAxes,'on');
    plot(vX,vY,'-k',cLineParams{:});
end

astPosition = mean([vLineStarts(1), vLineStarts(end)]);
astHeight   = lineHeight + 2;

% text(astPosition,astHeight,'n.s.',cAstParams{:});
hold(hAxes,'off');


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

% End of file: plotNSAndLine.m
