% Show a demo of the noise analysis and synthesis
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  25-Feb-2016 17:43:32

clear;
close all;


szFilename = 'CHACE.Smpl.1_Noise.wav';

[vSignal,fs] = audioread(szFilename);


%% Full analysis and synthesis.

% Create object and consider clicks.
obj = NoiseSynthesis.NoiseAnalysisSynthesis(vSignal,fs);

obj.ModelParameters.bApplyClicks = true;

% Show infos during analysis and synthesis
obj.bVerbose = true;


% Call analysis and synthesize a two-channel signal.
obj.analyze();
obj.synthesize();

% Listen to results.
obj.sound();

% Plot results.
obj.plot();

% Retrieve the sensor signals.
mSignalMatrix = obj.SensorSignals;
% or 
% mSignalMatrix = obj.synthesize();

pause;

%% Don't analyze but load a preset

clear;
close all;

fs = 44.1e3;
noiseType = 'optical';

obj = NoiseSynthesis.NoiseAnalysisSynthesis();
obj.Fs = fs;

obj.readParameters(fullfile('+NoiseSynthesis', noiseType));

obj.DesiredSignalLenSamples = round(5 * fs);
obj.synthesize();

mSignalMatrix = obj.SensorSignals;

obj.sound();

obj.plot();


% End of file: runDemo.m
