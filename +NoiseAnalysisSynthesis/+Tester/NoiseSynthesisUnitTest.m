classdef NoiseSynthesisUnitTest < matlab.unittest.TestCase
%NOISESYNTHESISUNITTEST Parent class for unit tests in the NoiseAnalysisSynthesis package.
% -------------------------------------------------------------------------
%
% Author :  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date   :  11-Feb-2018 15:14:51
%


properties (Constant)
    DEFAULT_SEED = 123;
    MAX_COMPLEXITY = 20;
end

properties (GetAccess = public)
    Seed;
    Unit;
end

properties (Abstract)
    UnitName;
end

properties (Access = protected, Dependent)
    IsSystemObject;
end



methods (TestClassSetup)
    function setClassRng(testCase)
        testCase.Seed = rng();
        testCase.addTeardown(@rng, testCase.Seed);
        
        rng(testCase.DEFAULT_SEED);
    end
end

methods (TestMethodSetup)
    function setMethodRng(testCase)
        rng(testCase.DEFAULT_SEED);
    end
    
    function setupUnit(testCase)
        unitHandle = str2func(testCase.UnitName);
        try
            unitInstance = unitHandle();
        catch
            unitInstance = unitHandle;
        end
        
        testCase.Unit = unitInstance;
        
        if isobject(testCase.Unit)
            if testCase.IsSystemObject
                testCase.addTeardown(@release, testCase.Unit);
            else
                testCase.addTeardown(@delete, testCase.Unit);
            end
        end
    end
end



methods (Test)
    function testComplexity(testCase)
        cycComplexity = testCase.getMcCabe();
        
        testCase.verifyLessThanOrEqual(...
            cycComplexity, ...
            testCase.MAX_COMPLEXITY, ...
            cycComplexity ...
            );
    end
end



methods
    function [yesNo] = get.IsSystemObject(testCase)
        parentClasses = superclasses(testCase.Unit);
        
        yesNo = ismember('matlab.System', parentClasses);
    end
    
    function [complexity] = getMcCabe(testCase)
        complExpression = '\d+';
        
        compl = checkcode(testCase.UnitName, '-cyc');
        
        msg = {compl.message}.';
        complexity = cellfun(@(x) regexp(x, complExpression, 'match'), msg);
        complexity = str2double(complexity);
    end
end


end

% End of file: NoiseSynthesisUnitTest.m
