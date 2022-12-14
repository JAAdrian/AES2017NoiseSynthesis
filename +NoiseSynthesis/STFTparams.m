classdef STFTparams < handle
%STFTPARAMS Parameter class for the STFT function
% -------------------------------------------------------------------------
% This class makes it easy to handle commonly and often used parameters in
% the STFT context. The reference is the desired block length in seconds
% and the overlap as a ratio. All remaining parameters are computed based
% on the sampling frequency.
%
% Usage: obj = STFTparams(BlocklenSec,OverlapRatio,fs)
%        obj = STFTparams(BlocklenSec,OverlapRatio,fs,szFBType)
%
%   Input:   ----------
%           BlocklenSec: block length in seconds (e.g. 32e-3)
%           OverlapRatio: overlap as a ratio (e.g. 0.5)
%           fs: sampling rate in Hz
%           szFBType: string stating the type of STFT paradigm. Either
%                     'analysis' or 'synthesis. If 'analysis' is chosen,
%                     the window function is by default a Hann window with
%                     desired blocklength. If 'synthesis' is chosen the
%                     window function is by default a square-root-Hann
%                     window with desired blocklength.
%                     [default: 'analysis']
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  29-Sep-2015 13:54:12
%


properties (SetAccess = private, GetAccess = public)
    Fs; % Sampling rate in Hz
    FrameRate; % Frame rate of the subsampled signal in freq. domain
    Blocklen; % Block length in samples
    Overlap; % Overlap in samples
    Frameshift; % Frame shift (or hopsize) in samples
    Window; % Window function vector
end

properties (Access = public)
    WindowFunctionHandle = @(x) hann(x,'periodic'); % Handle to create the desired window function
    NFFT; % DFT size in samples
    OriginalSignalLength; % Length of an original time signal. Can be used in the WOLA step in ISTFT
end




methods
    % Class constructor
    function [self] = STFTparams(BlocklenSec,OverlapRatio,fs,szFBType)
        if nargin,
            self.Fs         = fs;
            self.Blocklen   = round(BlocklenSec * self.Fs);
            self.Overlap    = round(OverlapRatio * self.Blocklen);
            self.Frameshift = self.Blocklen - self.Overlap;
            self.NFFT       = pow2(nextpow2(self.Blocklen));
            self.FrameRate  = round(self.Fs / self.Frameshift);
            
            % If synthesis filterbank is desired choose a sqrt(hann()) window
            % and set the NFFT to be the block length since we are working
            % with synthesis windows.
            if nargin > 3 && ~isempty(szFBType) && strcmpi(szFBType,'synthesis'),
                self.WindowFunctionHandle = @(x) sqrt(hann(x,'periodic'));
                
                self.Blocklen = self.NFFT;
                self.Overlap  = round(OverlapRatio * self.Blocklen);
            else
                self.WindowFunctionHandle = @(x) hann(x,'periodic');
            end

            % Compute the window function from the handle
            self.Window = self.WindowFunctionHandle(self.Blocklen);
        end
    end
    
    function [] = set.WindowFunctionHandle(self,Handle)
        assert(isa(Handle,'function_handle'),'Pass a valid handle to a window function');
        
        self.WindowFunctionHandle = Handle;
        
        self.Window = self.WindowFunctionHandle(self.Blocklen); %#ok<MCSUP>
    end
    
    function [] = set.NFFT(self,nfft)
        validateattributes(nfft, {'numeric'}, {'scalar', 'positive'});
        
        if log2(nfft) - round(log2(nfft)) > eps,
            warning(['Consider using a DFT size of a power of 2 for ', ...
                'computation speed puproses']);
        end
        
        self.NFFT = nfft;
    end
    
    function [] = set.OriginalSignalLength(self,len)
        validateattributes(len, {'numeric'}, {'scalar', 'positive'});
        
        self.OriginalSignalLength = len;
    end
    
    
    
    
    
    function [numBlocks] = computeNumberOfBlocks(self,lenSignal)
        %COMPUTENUMBEROFBLOCKS Compute the ceiled number of blocks
        % -----------------------------------------------------------------
        % The ceiled number of blocks resulting from the desired parameters.
        % This means that the signal will be zero-padded by default.
        
        if nargin < 2,
            if ~isempty(self.OriginalSignalLength)
                lenSignal = self.OriginalSignalLength;
            else
                error('Be sure to provide the original signal length as second parameter');
            end
        end
        
        numBlocks = ceil((lenSignal - self.Overlap) / self.Frameshift);
    end
end


methods (Access = private)

end







end




% End of file: STFTparams.m
