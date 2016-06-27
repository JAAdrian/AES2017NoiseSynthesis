
%DECLICK Declick a signal vector without quality degrading
% -------------------------------------------------------------------------
% This algorithm declicks the signal based on a detector signal. If no
% clicks are found the input signal's quality is not degraded.
% Implementation via function handles, see below.
%
% Usage: [stAlgo] = DeClick(fs,threshold)
%
%   Input:   ---------
%           fs: sampling rate in Hz
%           threshold: a threshold from interval (0, inf) [default: 0.15]
%
%  Output:   ---------
%           stAlgo: Struct containing function handles to the two actual
%                   processing functions
%
%                       [] = @init():
%                                   Initialize algorithm.
%                                   Input:  none
%                                   Output: none
%
%                       [DataOut,idx] = @process(DataIn,Mode):
%                                   Declick the signal in DataIn
%                                   Input:
%                                       DataIn: (N x 1) Signal vector
%                                       Mode: 4 integer Modi
%                                           0: first Block repition
%                                           1: first Block last repition
%                                           2: inbetween blocks repition
%                                           3: inbetween block last repition
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  01-Mar-2016 14:05:27
%







% End of file: DeClick.m
