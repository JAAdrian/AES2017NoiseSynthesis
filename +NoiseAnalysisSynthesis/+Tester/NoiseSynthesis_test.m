classdef NoiseSynthesis_test < NoiseAnalysisSynthesis.Tester.NoiseSynthesisUnitTest
%NOISESYNTHESIS_TEST Unit test for NoiseSynthesis.m
% -------------------------------------------------------------------------
% Run it by calling 'runtests()'
%   or specifically 'runtests('NoiseSynthesis_test')'
%
% Author :  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date   :  11-Feb-2018 15:58:14
%


properties
    UnitName = 'NoiseAnalysisSynthesis.Modules.NoiseSynthesis';
    NoiseProperties;
end


methods (TestClassSetup)
    function setupProperties(testCase)
        noiseProperties = load('noiseprops.mat');
        
        testCase.NoiseProperties = noiseProperties;
    end
end

methods (TestMethodSetup)
    function setup(testCase)
        noiseProperties = testCase.NoiseProperties.noiseProperties;
        
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
        
        testCase.Unit = synthesis;
    end
end



methods (Test)
    function runSynthesis_FewBlocks(testCase)
        noiseBlock = [];
        for iBlocks = 1:10
            noiseBlock = [noiseBlock, testCase.Unit()]; %#ok<AGROW>
        end
        
        testCase.verifySize(noiseBlock, [513, 20]);
        testCase.verifyClass(noiseBlock, 'double');
        testCase.verifyFalse(isreal(noiseBlock));
    end
end

end

% End of file: NoiseSynthesis_test.m
