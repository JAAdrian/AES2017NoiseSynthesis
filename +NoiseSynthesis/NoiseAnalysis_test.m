function [tests] = NoiseAnalysis_test()
%NOISEANALYSIS_TEST Unit testing for the function/class 'NoiseAnalysis.m' 
%
% Run it by calling, e.g., runtests('NoiseAnalysis_test')
%
% Author:  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date  :  03-Sep-2017 21:02
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

end

function teardown(testCase)

end


function testSomething(testCase)
testCase.assumeTrue(0);
end



% End of file: NoiseAnalysis_test.m