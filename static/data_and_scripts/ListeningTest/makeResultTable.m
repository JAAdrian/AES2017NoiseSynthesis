% <purpose of this file>
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  10-Nov-2015 17:11:03
% Updated:  <>

clear;
close all;

addpath('deps');

szResultPath = 'Results';

if ispc
    szConfigPath = fullfile(getGitProjectPath,'noise-listeningtest','deps');
else
    if exist(fullfile(getGitProjectPath,'noisemodeling-listeningtest'),'dir'),
        szConfigPath = fullfile(getGitProjectPath,'noisemodeling-listeningtest','deps');
    else
        szConfigPath = fullfile(getGitProjectPath,'noise-listeningtest','deps');
    end
end

stConfig = parsejson(fileread(fullfile(szConfigPath,'eval_config.json')));

stFiles = listFiles(szResultPath,'*.json',0);

caszFilenames = {stFiles.name}';
numFiles      = length(caszFilenames);

caszCategories = {...
    'orig',...
    'gauss',...
    'synth',...
    'synsmall',...
    'orig',...
    'gauss',...
    'synth',...
    'synsmall',...
    'orig',...
    'gauss',...
    'synth',...
    'synsmall',...
    'white'...
    };
lenCat = length(caszCategories);

vIdxFile = [ones(4,1); 2*ones(4,1); 3*ones(4,1); 1];

stResult = struct(...
    'Subject',{},...
    'Condition',{},...
    'NoiseType',{},...
    'Set',{},...
    'File',{},...
    'Score',{}...
    );
for aaFile = 1:numFiles,
    [~,szJsonName] = fileparts(caszFilenames{aaFile});
    resultTemp = parsejson(fileread(caszFilenames{aaFile}));
    
    caszFieldnames = resultTemp.keys.';
    numFields      = length(caszFieldnames);
    for bbField = 1:numFields,
        caszField    = strsplit(caszFieldnames{bbField},'_');
        idxSet       = caszField{2}(end);
        caszField{2} = caszField{2}(1:end-1);
        
        szNewField = [caszField{1}, '_S', idxSet, '_'];
        
        for ccCat = 1:lenCat,
            stNewResults.Subject   = upper(szJsonName);
            stNewResults.Condition = caszCategories(ccCat);
            stNewResults.NoiseType = caszField(1);
            stNewResults.Set       = str2double(idxSet);
            stNewResults.File      = vIdxFile(ccCat);
            
            score = resultTemp(caszFieldnames{bbField});
            stNewResults.Score     = score{ccCat};
            
            stResult = [stResult, stNewResults];
        end
    end
    
    
end

T = struct2table(stResult);

writetable(T,'2016_NoiseListeningTest.csv');


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

% End of file: makeResultTable.m
