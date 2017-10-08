function [tests] = NoiseAnalysis_test()
%NOISEANALYSIS_TEST Unit testing for the function/class 'NoiseAnalysis.m' 
%
% Run it by calling, e.g., runtests('NoiseAnalysis_test')
%
% Author:  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date  :  11-Sep-2017 20:27
%

% History:  v0.1.0  initial version, 11-Sep-2017 (JA)
%


tests = functiontests(localfunctions());
end


function setupOnce(testCase)
seed = rng();
testCase.TestData.seed = seed;
rng(123);
end

function teardownOnce(testCase)
rng(testCase.TestData.seed);
end

function setup(testCase)
[signal, sampleRate] = audioread('CHACE.Smpl.1_Noise.wav');

signal = signal(1 : round(2*sampleRate));

module = NoiseAnalysisSynthesis.Modules.NoiseAnalysis();
module.SampleRate = sampleRate;
module.Signal = signal;
module.StftParameters = NoiseAnalysisSynthesis.STFTparams(...
    1024 / sampleRate, ...
    0.5, ...
    sampleRate, ...
    'synthesis' ...
    );
module.DesiredLengthSignalSamples = round(2 * sampleRate);

testCase.TestData.module = module;
end




function testSomething(testCase)
testCase.TestData.module();
end



% End of file: NoiseAnalysis_test.m
