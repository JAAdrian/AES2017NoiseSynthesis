% Script to generate the box plot of the listening test in Fig. 8.
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  25-Jan-2016 17:51:33
% Updated:  <>


% source of boxplot tricks
% http://stackoverflow.com/a/22779695


clear;

szFilename = fullfile('..', 'ListeningTest', '2016_NoiseListeningTest.csv');

T = readtable(szFilename);
T.Subject   = categorical(T.Subject);
T.Condition = categorical(T.Condition);
T.NoiseType = categorical(T.NoiseType);
T.Set       = categorical(T.Set);
T.File      = categorical(T.File);

szFilenameSigni = fullfile('..', 'ListeningTest','2016_NoiseListeningTest_notsigni.csv');

T_signi = readtable(szFilenameSigni);
T_signi.NoiseType  = categorical(T_signi.NoiseType);
T_signi.GroupAName = categorical(T_signi.GroupAName);
T_signi.GroupBName = categorical(T_signi.GroupBName);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

szPlotName = 'ListeningResults';


caszNoiseType = {...
    'Schallplatte',...
    'Kassette',...
    'Filmton'...
    'Regen',...
    'Applaus',...
    };

caszPlotNoiseType = {...
    'Vinyl/Shellac',...
    'Cassette/Tape',...
    'Optical Sound'...
    'Rain',...
    'Applause',...
    };

caszConditions = {...
    'orig',...
    'synth',...
    'synsmall',...
    'gauss',...
    'white'...
    };

caszLegend = {...
    'Original',...
    'Synth. Full',...
    'Synth. Reduced',...
    'Colored Gaussian',...
    'White Gaussian'...
    };


caszVarNames = T.Properties.VariableNames;
numVars = width(T);

numTypes = length(categories(T.NoiseType));
numCond  = length(categories(T.Condition));

numSubjects    = length(categories(T.Subject));
numSets        = length(categories(T.Set));
numFilesInSets = length(categories(T.File));

numRows = numSubjects * numSets * numFilesInSets;

%%% Normalize Subjectes
% T = normalizeSubjects(T);
% T = standardizeVariables(T);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% group positions
stretchFactor = 1.75;
factorGap     = 0.25;

vBase = ones(numCond,1) * (1:stretchFactor:numTypes*stretchFactor);
vAdd  = (0:factorGap:1).' * ones(1,numTypes);
vPositions = vBase + vAdd;
vMeans     = mean(vPositions);

vPositions = vPositions(:);

mPlotData = [];
groupcounter = 1;
for aaType = 1:numTypes,
    for bbCondition = 1:numCond,
        vIdxType = T.NoiseType == caszNoiseType{aaType};
        vIdxCond = T.Condition == caszConditions{bbCondition};
        vIdxRow  = vIdxType & vIdxCond;

        mData  = T.Score(vIdxRow);
        mData  = [mData(:); nan(numRows - numel(mData),1)];
        vGroup = groupcounter * ones(numRows,1);

        mPlotData = [...
            mPlotData; ...
            mData, vGroup...
            ]; %#ok<AGROW>
        groupcounter = groupcounter + 1;
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot that jazz

hf = figure(1);
clf;
boxplot(...
    mPlotData(:,1),...
    mPlotData(:,2),...
    'positions',vPositions,...
    'colors','k',...
    'symbol','o',...
    'outliersize',2,...
    'medianstyle','line'...
    );
axis([0 vPositions(end)+1 -5 105]);

ha = gca;

% ticks and tick labels
set(ha,...
    'xtick',vMeans,...
    'xticklabel',caszPlotNoiseType,...
    'ytick',0:10:100 ...
    );

% colors
mColors = [
    1*ones(1,3);...
    0.8*ones(1,3);...
    0.6*ones(1,3);...
    0.4*ones(1,3);...
    0.2*ones(1,3);...
    ];
mColors = repmat(mColors,numTypes,1);

hBoxes   = findobj(ha,'Tag','Box');
numBoxes = length(hBoxes);
for aaBox = 1:numBoxes,
   patch(...
       get(hBoxes(aaBox),'XData'),get(hBoxes(aaBox),'YData'),...
       mColors(length(hBoxes)-aaBox+1,:)...
       );
end

% color of the outliers
hOutliers = findobj(ha,'Tag','Outliers');
for aaOutlier = 1:length(hOutliers),
    set(hOutliers(aaOutlier),...
        'MarkerEdgeColor',[0 0 0]);
end

% color and linewidth of the medians
hMedians = findobj(ha,'Tag','Median');
for aaMedian = 1:length(hMedians),
    set(hMedians(aaMedian),...
        'Color',[0 0 0],...
        'LineWidth',2 ...
    )
end

% legend
hC = get(ha,'Children');
hl = legend(...
    hC(1:numCond),caszLegend,...
    'Location','northoutside',...
    'Orientation','Horizontal'...
    );

ylabel('Opinion Score (OS) in %');
grid on;

% flip children to set the patch into the background
set(ha,'Children',flipud(get(ha,'Children')));

% mark not significantly different pairs
numSignBoxes = height(T_signi);

caszSigniNoiseTypes = categories(T_signi.NoiseType);
numTypeBoxes = length(caszSigniNoiseTypes);
GroupBmaxOld = -inf;
yOffset      = 0;
for aaType = 1:numTypeBoxes,
    Ttype = T_signi(T_signi.NoiseType == caszNoiseType{aaType},:);

    for GroupA = min(Ttype.GroupA):max(Ttype.GroupA),
        GroupBmax = max(Ttype{Ttype.GroupA == GroupA,'GroupB'});

        if GroupBmax <= GroupBmaxOld,
            continue;
        elseif GroupA < GroupBmaxOld,
            yOffset = -5.5;
        end

        if isempty(GroupBmax),  continue;   end

        plotNSAndLine(...
            hBoxes(numBoxes - (GroupA:GroupBmax) + 1),...
            ha,...
            yOffset...
            );

        GroupBmaxOld = GroupBmax;
        yOffset = 0;
    end
end





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

% End of file: plotListeningResults.m
