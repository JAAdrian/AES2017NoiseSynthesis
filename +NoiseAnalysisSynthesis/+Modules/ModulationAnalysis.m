classdef ModulationAnalysis < matlab.System
%MODULATIONANALYSIS <purpose in one line!>
% -------------------------------------------------------------------------
% <Detailed description of the function>
%
% ModulationAnalysis Properties:
%	propA - <description>
%	propB - <description>
%
% ModulationAnalysis Methods:
%	doThis - <description>
%	doThat - <description>
%
% Author :  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date   :  10-Sep-2017 17:49:20
%

% History:  v0.1.0   initial version, 10-Sep-2017 (JA)
%


properties (Access = public)
	Signal;
    SampleRate;
    
    ModulationParameters;
    ModelParameters;
    
    NumModulationBands;
    
    ModNormFun;
end

properties (Dependent)
    
end

properties (SetAccess = protected, GetAccess = public)
    NumBins;
    LenLevelCurves;
    NumBlocks;
    
    MelBands;
	LevelFluctuationCurves;
    ModulationDepth;
    GammaBands;
end


properties (Access = protected)
    MarkovAnalyzer;
	MelMatrix;
end



methods
	function [obj] = ModulationAnalysis(varargin)
        obj.MarkovAnalyzer = NoiseAnalysisSynthesis.Modules.MarkovAnalysis();
        
		obj.setProperties(nargin, varargin{:})
	end
end


methods (Access = protected)
	function [] = setupImpl(obj, stftSignal)
        import NoiseAnalysisSynthesis.External.*
        
        [obj.NumBins, obj.LenLevelCurves] = size(stftSignal);
        
        freq = linspace(0, obj.SampleRate/2, obj.NumBins);
        obj.MelMatrix = melfilter(obj.NumModulationBands, freq);
    end

	function [] = stepImpl(obj, stftSignal)
        obj.transform2Mel(stftSignal);
        obj.computeLevelFluctuations();
		obj.analyzeModulationDepth();
        obj.analyzeCorrelationBands();
        obj.analyzeMarkovTransitions();
    end
    
    
    function [] = transform2Mel(obj, stftSignal)
        obj.MelBands = obj.MelMatrix * stftSignal;
    end
    
    function [] = computeLevelFluctuations(obj)
        import NoiseAnalysisSynthesis.External.*
        
        modulationFrameShift = obj.ModulationParameters.Frameshift;
        
        numBlocksPadded = obj.LenLevelCurves*modulationFrameShift + obj.ModulationParameters.Overlap;
        
        remainingBlocks = numBlocksPadded - obj.NumBlocks;
        
        idxNormalize = ...
            round(0.05 * obj.NumBlocks) : round(0.95 * obj.NumBlocks);
        
        obj.LevelFluctuationCurves = zeros(obj.LenLevelCurves, obj.NumBands);
        for iBand = 1:obj.NumModulationBands
            currBandSignal = obj.MelBands(iBand,:).';
            currBandSignal = currBandSignal / rmsvec(currBandSignal(idxNormalize));
            
            currBandSignal = [...
                currBandSignal; ...
                currBandSignal(end-remainingBlocks+1:end)...
                ]; %#ok<AGROW>
            
            idxBlock = 1:obj.ModulationParameters.Blocklen;
            for jBlock = 1:obj.LenLevelCurve
                % get RMS
                obj.LevelFluctuationCurves(jBlock,iBand) = rmsvec(currBandSignal(idxBlock));
                
                % update block index
                idxBlock = idxBlock + modulationFrameShift;
            end
        end
    end
    
    function [] = analyzeModulationDepth(obj)
        obj.ModulationDepth = obj.ModNormFun(obj.LevelFluctuationCurves).';
    end
    
    function [] = analyzeCorrelationBands(obj)
        import NoiseAnalysisSynthesis.External.*
        
        obj.GammaBands = computeBandCorrelation(obj.LevelFluctuationCurves);
    end
    
    function [] = analyzeMarkovTransitions(obj)
        obj.MarkovAnalyzer(obj.LevelFluctuationCurves);
    end
end

end





% End of file: ModulationAnalysis.m
