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
control = NoiseAnalysisSynthesis.ControlCenter(signal, sampleRate);

control.ModelParameters.DoApplyClicks = true;

% Show infos during analysis and synthesis
control.Verbose = true;


% Analysis and synthesize of a two-channel signal.
control();

% Listen to results.
control.sound();

% Plot results.
control.plot();

pause;

%% Don't analyze but load a preset

clear;
close all;

sampleRate = 44.1e3;
noiseType = 'optical';

control = NoiseSynthesis.NoiseAnalysisSynthesis();
control.SampleRate = sampleRate;

control.readParameters(fullfile('+NoiseSynthesis', noiseType));

control.DesiredSignalLenSamples = round(5 * sampleRate);
control.synthesize();

signalMatrix = control.SensorSignals;

control.sound();

control.plot();


% End of file: runDemo.m
