% Show a demo of the noise analysis and synthesis
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  25-Feb-2016 17:43:32

clear;
close all;


filename = 'CHACE.Smpl.1_Noise.wav';

[signal, sampleRate] = audioread(filename);


%% Full analysis and synthesis.

% Create object and consider clicks.
obj = NoiseSynthesis.NoiseAnalysisSynthesis(signal, sampleRate);

obj.ModelParameters.DoApplyClicks = true;

% Show infos during analysis and synthesis
obj.Verbose = true;


% Call analysis and synthesize a two-channel signal.
obj.analyze();
obj.synthesize();

% Listen to results.
obj.sound();

% Plot results.
obj.plot();

% Retrieve the sensor signals.
signalMatrix = obj.SensorSignals;
% or 
% mSignalMatrix = obj.synthesize();

pause;

%% Don't analyze but load a preset

clear;
close all;

sampleRate = 44.1e3;
noiseType = 'optical';

obj = NoiseSynthesis.NoiseAnalysisSynthesis();
obj.SampleRate = sampleRate;

obj.readParameters(fullfile('+NoiseSynthesis', noiseType));

obj.DesiredSignalLenSamples = round(5 * sampleRate);
obj.synthesize();

signalMatrix = obj.SensorSignals;

obj.sound();

obj.plot();


% End of file: runDemo.m
