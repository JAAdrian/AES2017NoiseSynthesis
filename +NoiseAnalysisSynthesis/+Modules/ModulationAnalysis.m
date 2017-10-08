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
    
    NumFrequencyBands;
    
    ModNormFun;
end

properties (Logical, Nontunable)
    Verbose;
end

properties (SetAccess = protected)
    NumBins;
    NumBlocks;
    
    MelBands;
	LevelFluctuationCurves;
    ModulationDepth;
    BandCorrelationMatrix;
    
    StateBoundaries;
    MarkovTransition;
end


properties (Access = protected)
    LengthLevelCurves;
    
    MarkovAnalyzer;
	MelMatrix;
end



methods
	function [obj] = ModulationAnalysis(varargin)
        obj.MarkovAnalyzer = NoiseAnalysisSynthesis.Modules.MarkovAnalysis();
        
        obj.Verbose = false;
        
		obj.setProperties(nargin, varargin{:})
	end
end


methods (Access = protected)
	function [] = setupImpl(obj, stftSignal)
        import NoiseAnalysisSynthesis.External.*
        
        [obj.NumBins, obj.NumBlocks] = size(stftSignal);
        
        obj.LengthLevelCurves = ...
            ceil((obj.NumBlocks - obj.ModulationParameters.Overlap) / ...
            obj.ModulationParameters.Frameshift);
        
        freq = linspace(0, obj.SampleRate/2, obj.NumBins);
        obj.MelMatrix = melfilter(obj.NumFrequencyBands, freq);
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
        
        % don't consider first and last blocks
        idxNormalize = round(0.05 * obj.NumBlocks) : round(0.95 * obj.NumBlocks);
        
        obj.LevelFluctuationCurves = zeros(obj.LengthLevelCurves, obj.NumFrequencyBands);
        for iBand = 1:obj.NumFrequencyBands
            currBandSignal = obj.MelBands(iBand,:).';
            currBandSignal = currBandSignal / rmsvec(currBandSignal(idxNormalize));
            
            idxBlock = 1:obj.ModulationParameters.Blocklen;
            for jBlock = 1:obj.LengthLevelCurves
                % get RMS
                obj.LevelFluctuationCurves(jBlock, iBand) = rmsvec(currBandSignal(idxBlock));
                
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
        
        obj.BandCorrelationMatrix = computeBandCorrelation(obj.LevelFluctuationCurves);
    end
    
    function [] = analyzeMarkovTransitions(obj)
        obj.MarkovAnalyzer.LevelFluctuationCurves = obj.LevelFluctuationCurves;
        obj.MarkovAnalyzer.BandCorrelationMatrix  = obj.BandCorrelationMatrix;
        obj.MarkovAnalyzer.ModelParameters        = obj.ModelParameters;
        
        obj.MarkovAnalyzer();
        
        obj.StateBoundaries  = obj.MarkovAnalyzer.StateBoundaries;
        obj.MarkovTransition = obj.MarkovAnalyzer.MarkovTransition;
    end
end

end





% End of file: ModulationAnalysis.m
