function [varargout] = plotstack(numFigures,iStartHandleNumber)
%PLOTSTACK Creates figures distributed over the monitor
% -------------------------------------------------------------------------
% This function creates MATLAB figures distributed across the (1st) monitor.
% It returns the figure handles either in one handle array or the handles
% can be retrieved indivudally
%
% Usage: [varargout] = plotstack()
%        [varargout] = plotstack(numFigures)
%        [varargout] = plotstack(numFigures,iStartHandleNumber)
%
%   Input:   ---------
%           numFigure: Number of figures to be created on the screen
%                      [default: 1]
%           iStartHandleNumber: Integer offset added to the handle figure
%                               counter [default: 1]
%
%  Output:   ---------
%           handle_array: Array containing all the figure handles
%           'numFigures' output arguments: each figure handle in a separate
%                                          output argument
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  16-Jan-2015 14:55:56
%


if nargin < 2 || isempty(iStartHandleNumber),
    iStartHandleNumber = 1;
end
if nargin < 1 || isempty(numFigures),
    numFigures = 1;
end

mUsableScreen = get(0,'screenSize');
percOffsetHeight  = 0.07;
percOffsetTaskbar = 0.035;

% make sure these funny thingy bars in the upper window section are visible
mUsableScreen(end) = mUsableScreen(end) * (1 - percOffsetHeight);


% make sure the task bar is free from windows
mUsableScreen(1) = mUsableScreen(3) * percOffsetTaskbar;
mUsableScreen(3) = mUsableScreen(3) * (1-percOffsetTaskbar);

maxFigsPerCol = 3;

numFigsPerCol = maxFigsPerCol;
numFigsPerRow = ceil(numFigures / maxFigsPerCol);
while numFigsPerRow <= numFigsPerCol,
    numFigsPerCol = numFigsPerCol - 1;
    numFigsPerRow = ceil(numFigures / numFigsPerCol);
end

figWidth  = floor(mUsableScreen(3) / numFigsPerRow);
figHeight = floor(mUsableScreen(4) / numFigsPerCol);

vStartX = mUsableScreen(1) : figWidth  : mUsableScreen(3);
vStartY = mUsableScreen(2) : figHeight : mUsableScreen(4);

mHandles = zeros(numFigsPerCol,numFigsPerRow);
counterFig = iStartHandleNumber;
for aaRow = numFigsPerCol:-1:1,
    for bbCol = 1:numFigsPerRow,
        hFig = figure(counterFig);
        
        set(hFig,'position',[vStartX(bbCol) vStartY(aaRow) figWidth figHeight]);
        
        mHandles(aaRow,bbCol) = hFig;
        
        counterFig = counterFig + 1;
    end
end

if nargout == 1,
    varargout = {mHandles};
elseif nargout == numFigures,
    mHandles  = fliplr(mHandles');
    varargout = num2cell(mHandles(:),nargout);
end




% End of file: plotstack.m
