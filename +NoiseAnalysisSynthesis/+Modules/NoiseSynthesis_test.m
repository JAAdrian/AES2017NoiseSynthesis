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

data = load('handel');
analysisModule = NoiseAnalysisSynthesis.Modules.NoiseAnalysis();
analysisModule.SampleRate = data.Fs;
analysisModule.Signal = data.y;
analysisModule.StftParameters = NoiseAnalysisSynthesis.STFTparams(256/data.Fs, 0.5, data.Fs, 'synthesis');
analysisModule.DesiredLengthSignalSamples = length(data.y);

testCase.TestData.analysisModule = analysisModule;

noiseProperties = analysisModule();
testCase.TestData.noiseProperties = noiseProperties;
end

function teardownOnce(testCase)
rng(testCase.TestData.seed);
end

function setup(testCase)
noiseProperties = testCase.TestData.noiseProperties;

module = NoiseAnalysisSynthesis.Modules.NoiseSynthesis();
module.NoiseProperties = noiseProperties;
end




function testSomething(testCase)
testCase.assumeTrue(true);
end



% End of file: NoiseSynthesis_test.m
