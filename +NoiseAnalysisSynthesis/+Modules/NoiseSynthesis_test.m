function [tests] = NoiseSynthesis_test()
%NOISESYNTHESIS_TEST Unit testing for the function/class 'NoiseSynthesis.m' 
%
% Run it by calling, e.g., runtests('NoiseSynthesis_test')
%
% Author:  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date  :  01-Oct-2017 20:14
%

% History:  v0.1.0  initial version, 01-Oct-2017 (JA)
%


tests = functiontests(localfunctions());
end


function setupOnce(testCase)
seed = rng();
testCase.TestData.seed = seed;
rng(123);

noiseProperties = load('noiseprops.mat');

testCase.TestData.noiseProperties = noiseProperties;
end

function teardownOnce(testCase)
rng(testCase.TestData.seed);
end

function setup(testCase)
noiseProperties = testCase.TestData.noiseProperties.noiseProperties;

synthesis = NoiseAnalysisSynthesis.Modules.NoiseSynthesis();
synthesis.NoiseProperties = noiseProperties;


blocklenSamples = 1024;
sampleRate = 44.1e3;
synthesis.StftParameters = NoiseAnalysisSynthesis.STFTparams(...
    blocklenSamples / sampleRate, ...
    0.5, ...
    sampleRate, ...
    'synthesis' ...
    );

synthesis.DesiredLengthSignalSamples = synthesis.SampleRate;

numBlocks = 1;
blockedSignal = zeros(synthesis.StftParameters.Blocklen, numBlocks);
for iBlock = 1:numBlocks
    blockedSignal(:, iBlock) = synthesis();
end
end




function testSomething(testCase)
testCase.assumeTrue(true);
end



% End of file: NoiseSynthesis_test.m
