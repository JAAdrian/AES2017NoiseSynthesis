% Script to find significantly and NOT signficantly differing condition
% groups in the listening test.
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  29-Jan-2016 11:04:33
% Updated:  <>

clear;
close all;


alpha = 0.05;



szFilename = '2016_NoiseListeningTest.csv';

T = readtable(szFilename);
T.Subject   = categorical(T.Subject);
T.Condition = categorical(T.Condition);
T.NoiseType = categorical(T.NoiseType);
T.Set       = categorical(T.Set);
T.File      = categorical(T.File);

caszVarNames = T.Properties.VariableNames;
numVars = width(T);

numTypes = length(categories(T.NoiseType));
numCond  = length(categories(T.Condition));

numSubjects    = length(categories(T.Subject));
numSets        = length(categories(T.Set));
numFilesInSets = length(categories(T.File));

numRows = numSubjects * numSets * numFilesInSets;


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
    'Filmtone'...
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


stStat = struct(...
    'NoiseType',{},...
    'GroupAName',{},...
    'GroupA',{},...
    'GroupBName',{},...
    'GroupB',{},...
    'p_Signi',{}...
    );


groupcounter = 1;
hyp_norm = zeros(numTypes,numCond);
p_norm   = zeros(numTypes,numCond);
for aaType = 1:numTypes,
    cStatData = cell(1,4);
    
    for bbCondition = 1:numCond,
        vIdxType = T.NoiseType == caszNoiseType{aaType};
        vIdxCond = T.Condition == caszConditions{bbCondition};
        vIdxRow  = vIdxType & vIdxCond;
        
        vData  = T.Score(vIdxRow);
        vGroup = groupcounter * ones(length(vData),1);
        
        cStatData{1} = [cStatData{1}; vData];
        cStatData{2} = [cStatData{2}; vGroup];
        cStatData{3} = [cStatData{3}; T.Subject(vIdxRow)];
        cStatData{4} = [
            cStatData{4};
            categorical(double(T.File(vIdxRow)) + (double(T.Set(vIdxRow))-1)*numFilesInSets)
            ];

        groupcounter = groupcounter + 1;
        
        [hyp_norm(aaType,bbCondition),p_norm(aaType,bbCondition)] = ...
            kstest(zscore(vData));
    end
    
    [p,tbl,stats] = kruskalwallis(cStatData{1},cStatData{2},'off');
  
    [mComparedSign,mMedians] = multcompare(...
        stats,...
        'CType','hsd dunn-sidak bonferroni',...
        'Display','off',...
        'Alpha',alpha...
        );
    
    for bbCombination = 1:numCond*2,
        stNewStat.NoiseType  = caszNoiseType{aaType};
        stNewStat.GroupAName = caszConditions{mComparedSign(bbCombination,1)};
        stNewStat.GroupA     = mComparedSign(bbCombination,1) + (aaType-1)*numCond;
        stNewStat.GroupBName = caszConditions{mComparedSign(bbCombination,2)};
        stNewStat.GroupB     = mComparedSign(bbCombination,2) + (aaType-1)*numCond;
        stNewStat.p_Signi    = mComparedSign(bbCombination,end);
        
        stStat = [stStat, stNewStat];
    end
end

Stat = struct2table(stStat);

Stat_signi    = Stat(Stat.p_Signi < alpha,:);
Stat_notsigni = Stat(Stat.p_Signi >= alpha,:);

disp(Stat_notsigni);

writetable(Stat_signi,'2016_NoiseListeningTest_signi.csv');
writetable(Stat_notsigni,'2016_NoiseListeningTest_notsigni.csv');



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

% End of file: checkSignificance.m
