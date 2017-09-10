classdef STFTparams < handle
%STFTPARAMS Parameter class for the STFT function
% -------------------------------------------------------------------------
% This class makes it easy to handle commonly and often used parameters in
% the STFT context. The reference is the desired block length in seconds
% and the overlap as a ratio. All remaining parameters are computed based
% on the sampling frequency.
%
% Usage: obj = STFTparams(blocklenSec, overlapRatio, sampleRate)
%        obj = STFTparams(blocklenSec, overlapRatio, sampleRate, fbType)
%
%   Input:   ----------
%           blocklenSec: block length in seconds (e.g. 32e-3)
%           overlapRatio: overlap as a ratio (e.g. 0.5)
%           sampleRate: sampling rate in Hz
%           fbType: string stating the type of STFT paradigm. Either
%                   'analysis' or 'synthesis. If 'analysis' is chosen,
%                   the window function is by default a Hann window with
%                   desired blocklength. If 'synthesis' is chosen the
%                   window function is by default a square-root-Hann
%                   window with desired blocklength.
%                   [default: 'analysis']
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  31-Aug-2017 13:54:12
%


properties (SetAccess = private, GetAccess = public)
    SampleRate; % Sampling rate in Hz
    FrameRate; % Frame rate of the subsampled signal in freq. domain
    Blocklen; % Block length in samples
    Overlap; % Overlap in samples
    Frameshift; % Frame shift (or hopsize) in samples
    Window; % Window function vector
end

properties (Access = public)
    WindowFunctionHandle = @(x) hann(x,'periodic'); % Handle to create the desired window function
    Nfft; % DFT size in samples
    OriginalSignalLength; % Length of an original time signal. Can be used in the WOLA step in ISTFT
end




methods
    % Class constructor
    function [obj] = STFTparams(blocklenSec, overlapRatio, sampleRate, fbType)
        if ~nargin
            return;
        end
        
        obj.SampleRate = sampleRate;
        obj.Blocklen   = round(blocklenSec * obj.SampleRate);
        obj.Overlap    = round(overlapRatio * obj.Blocklen);
        obj.Frameshift = obj.Blocklen - obj.Overlap;
        obj.Nfft       = pow2(nextpow2(obj.Blocklen));
        obj.FrameRate  = round(obj.SampleRate / obj.Frameshift);
        
        % If synthesis filterbank is desired choose a sqrt(hann()) window
        % and set the Nfft to be the block length since we are working
        % with synthesis windows.
        if nargin > 3 && ~isempty(fbType) && strcmpi(fbType, 'synthesis')
            obj.WindowFunctionHandle = @(x) sqrt(hann(x, 'periodic'));
            
            obj.Blocklen = obj.Nfft;
            obj.Overlap  = round(overlapRatio * obj.Blocklen);
        else
            obj.WindowFunctionHandle = @(x) hann(x, 'periodic');
        end
        
        % Compute the window function from the handle
        obj.Window = obj.WindowFunctionHandle(obj.Blocklen);
    end
    
    function [] = set.WindowFunctionHandle(obj, Handle)
        assert(isa(Handle,'function_handle'), 'Pass a valid handle to a window function');
        
        obj.WindowFunctionHandle = Handle;
        
        obj.Window = obj.WindowFunctionHandle(obj.Blocklen); %#ok<MCSUP>
    end
    
    function [] = set.Nfft(obj, Nfft)
        validateattributes(Nfft, {'numeric'}, {'scalar', 'positive'});
        
        if log2(Nfft) - round(log2(Nfft)) > eps
            warning(['Consider using a DFT size of a power of 2 for ', ...
                'computation speed purposes']);
        end
        
        obj.Nfft = Nfft;
    end
    
    function [] = set.OriginalSignalLength(obj,len)
        validateattributes(len, {'numeric'}, {'scalar', 'positive'});
        
        obj.OriginalSignalLength = len;
    end
    
    
    
    
    
    function [numBlocks] = computeNumberOfBlocks(obj,lenSignal)
        %COMPUTENUMBEROFBLOCKS Compute the ceiled number of blocks
        % -----------------------------------------------------------------
        % The ceiled number of blocks resulting from the desired parameters.
        % This means that the signal will be zero-padded by default.
        
        if nargin < 2
            if ~isempty(obj.OriginalSignalLength)
                lenSignal = obj.OriginalSignalLength;
            else
                error('Be sure to provide the original signal length as second parameter');
            end
        end
        
        numBlocks = ceil((lenSignal - obj.Overlap) / obj.Frameshift);
    end
end

end




% End of file: STFTparams.m
