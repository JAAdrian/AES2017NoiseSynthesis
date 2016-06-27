
%DECRACKLE De-crackle an audio signal vector
% -------------------------------------------------------------------------
% This algorithm de-crackles the signal based on a detector signal. If no
% crackles are found the input signal's quality is not degraded.
% Implementation via function handles, see below.
%
% Usage: [stAlgo] = DeCrackele(fs,threshold)
%
%   Input:   ---------
%           fs: sampling rate in Hz
%           threshold: a threshold from interval (0, 100) corresponding to
%                      percentiles. A lower value leads to stronger
%                      de-crackling
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
%                       [DataOut] = @process(DataIn):
%                                   Declick the signal in DataIn
%                                   Input:
%                                       DataIn: (N x 1) Signal vector
%
% Author:  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date  :  15-Jun-2016 15:57
%






% End of file: DeCrackle.m
