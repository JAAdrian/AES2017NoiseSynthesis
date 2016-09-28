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
            narginchk(3, 4);
            
            validateattributes(BlocklenSec, ...
                {'numeric'}, ...
                {'positive', 'scalar'}, ...
                mfilename, ...
                'BlocklenSec', ...
                1 ...
                );
            validateattributes(OverlapRatio, ...
                {'numeric'}, ...
                {'positive', 'scalar', '<', 1}, ...
                mfilename, ...
                'OverlapRatio', ...
                2 ...
                );
            validateattributes(fs, ...
                {'numeric'}, ...
                {'positive', 'scalar'}, ...
                mfilename, ...
                'fs', ...
                3 ...
                );
            
            if nargin < 4 || isempty(szFBType),
                szFBType = 'analysis';
            else
                validateattributes(szFBType, {'char'}, {});
                szFBType = validatestring(szFBType, {'analysis', 'synthesis'});
            end
            
            self.Fs         = fs;
            self.Blocklen   = round(BlocklenSec * self.Fs);
            self.Overlap    = round(OverlapRatio * self.Blocklen);
            self.Frameshift = self.Blocklen - self.Overlap;
            self.NFFT       = pow2(nextpow2(self.Blocklen));
            self.FrameRate  = round(self.Fs / self.Frameshift);
            
            % If synthesis filterbank is desired choose a sqrt(hann()) window
            % and set the NFFT to be the block length since we are working
            % with synthesis windows.
            switch szFBType,
                case 'synthesis',
                    self.WindowFunctionHandle = @(x) sqrt(hann(x,'periodic'));
                    
                    self.Blocklen = self.NFFT;
                    self.Overlap  = round(OverlapRatio * self.Blocklen);
                
                case 'analysis',
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




%-------------------- Licence ---------------------------------------------
% Copyright (c) 2015, J.-A. Adrian
% Institute for Hearing Technology and Audiology
% Jade University of Applied Sciences
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
%
%	1. Redistributions of source code must retain the above copyright
%	   notice, this list of conditions and the following disclaimer.
%
%	2. Redistributions in binary form must reproduce the above copyright
%	   notice, this list of conditions and the following disclaimer in
%	   the documentation and/or other materials provided with the
%	   distribution.
%
%	3. Neither the name of the copyright holder nor the names of its
%	   contributors may be used to endorse or promote products derived
%	   from this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
% IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
% TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
% PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
% HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
% TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

% End of file: STFTparams.m
