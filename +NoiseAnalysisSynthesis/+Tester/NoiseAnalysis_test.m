classdef NoiseAnalysis_test < NoiseAnalysisSynthesis.Tester.NoiseSynthesisUnitTest
%NOISEANALYSIS_TEST Unit test for NoiseAnalysisSynthesis.Tester.NoiseAnalysis.m
% -------------------------------------------------------------------------
% Run it by calling 'runtests()'
%   or specifically 'runtests('NoiseAnalysisSynthesis.Tester.NoiseAnalysis_test')'
%
% Author :  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date   :  11-Feb-2018 15:31:36
%


properties
    UnitName = 'NoiseAnalysisSynthesis.Modules.NoiseAnalysis';
end


methods (TestMethodSetup)
    function setup(testCase)
        [signal, sampleRate] = audioread('CHACE.Smpl.1_Noise.wav');
        
        signal = signal(1 : round(2*sampleRate));
        
        module = testCase.Unit;
        module.SampleRate = sampleRate;
        module.Signal = signal;
        module.StftParameters = NoiseAnalysisSynthesis.STFTparams(...
            1024 / sampleRate, ...
            0.5, ...
            sampleRate, ...
            'synthesis' ...
            );
        module.DesiredLengthSignalSamples = round(2 * sampleRate);
        
        testCase.Unit = module;
    end
end



methods (Test)
    function runAnalysis(testCase)
        testCase.Unit();
    end
end

end

% End of file: NoiseAnalysis_test.m
