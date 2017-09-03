function [tests] = NoiseProperties_test()
%NOISEPROPERTIES_TEST Unit testing for the function/class 'NoiseProperties.m' 
%
% Run it by calling, e.g., runtests('NoiseProperties_test')
%
% Author:  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date  :  03-Sep-2017 20:45
%

% History:  v0.1.0  initial version, 03-Sep-2017 (JA)
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
testCase.TestData.obj = NoiseSynthesis.NoiseProperties();
end

function teardown(testCase)

end


function testSomething(testCase)

end



% End of file: NoiseProperties_test.m
