% $Revision: 29 $
% $Author: brandt $
% $Date: 2011-03-30 20:43:53 +0200 (Mi, 30 Mrz 2011) $

% clear the workspace
clear;
close all; 
clc;

% create some input data that should be smoothed...
H = rand(1024, 1);
%H = ones(1024, 1);

% required parameters:
stAlgo.fs = 44100;                  % sampling rate
stAlgo.type = 'fractional-octave';  % type of spectral smoothing
                                    % . 'fractional-octave' or
                                    % . 'fixed-bandwidth'
                                    
stAlgo.bandwidth = 1/3;             % bandwidth
                                    % . in octaves for 'fractional-octave'
                                    % . in Hz for 'fixed-bandwidth'

stAlgo.L_FFT = 1024;                % length of the DFT

% initialize the smoothing algorithm
stAlgo = spectralsmoothing_init(stAlgo);

% perform the smoothing
H_sm = spectralsmoothing_process(H, stAlgo);

% plot the results
plot([H(1:stAlgo.L_FFT/2+1) H_sm]);
legend({'original data', 'smoothed data'});
set(gca,'xscale','log');
