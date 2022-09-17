# Synthesis of Perceptually Plausible Multichannel Noise Signals Controlled by Real World Statistical Noise Properties

This Github repository provides code and basic information about the studies
which were performed for the publication of the [respective AES journal paper](https://jaadrian.github.io/AES2017NoiseSynthesis/#citation).

Head for the [accompanying web site](https://jaadrian.github.io/AES2017NoiseSynthesis/#citation) for more basic information about the study.

## Content

- [Content](#content)
- [Installation](#installation)
- [Usage](#usage)
- [Examples](#examples)
- [License](#license)

This MATLAB class provides means to analyze audio noise disturbances and
synthesize artificial noise processes of arbitrary length with similar
perceptive features.

The goal is to provide a tool for researchers and developers to generate
artificial noise disturbances for evaluating algorithms in single and
multi-channel applications.

## Installation

The package has been tested under Windows and Linux with MATLAB versions >=
2014b 64bit. To use the class, make sure the folder **containing the package
folder** `+NoiseSynthesis` with all the class files is part of the MATLAB path.
Various methods to add a folder to MATLAB's path exist. To ensure the latter
for the current session, use

```matlab
addpath(path_to_package);
```
To make use of the mexfile `rmsvec` in the *external* folder of the package
(ie. +NoiseSynthesis/+external) it has to be compiled by calling

```matlab
mex rmsvec.cpp
```

The package has dependencies to the MATLAB *Statistics and Machine Learning*
and *Signal Processing* toolbox.

## Usage

In this part the basic and the more advanced functionalities of the class are
described. This README provides practical examples. For class documentation
refer to `doc NoiseSynthesis.NoiseAnalysisSynthesis`.

### Instantiate an Object

To instantiate a noise-synthesis object, simply call one of

```matlab
obj = NoiseSynthesis.NoiseAnalysisSynthesis();
obj = NoiseSynthesis.NoiseAnalysisSynthesis(vSignal,fs);
```
where `vSignal` is a signal vector of a noise process to be analyzed and `fs`
is the corresponding sampling rate in Hertz.

If the constructor is called without arguments the analysis method will fail.
In this state the class can only synthesize a noise process based on one of the
presets.


### Properties

After creating a `NoiseAnalysisSynthesis` object as shown above the object
shows the following properties. The first properties describe the considered
signals like the analysis and synthesis (and optional click) signal. For model
parameters and error measures see below. The remaining properties describe some
general processing parameters as well as several Booleans steering which parts
of the process chain are desired.

```matlab
>> obj

obj =

  NoiseAnalysisSynthesis with properties:

             AnalysisSignal: [358706x1 double]
              SensorSignals: []
                ClickTracks: {}
            ModelParameters: [1x1 NoiseSynthesis.ModelParametersSet]
              ErrorMeasures: [1x1 NoiseSynthesis.ErrorMeasures]
        GammatoneLowestBand: 64
       GammatoneHighestBand: 16000
         NumModulationBands: 16
                   CutOffHP: 100
           NumSensorSignals: 2
                 NumSources: 1
                         Fs: 44100
    DesiredSignalLenSamples: 358706
           bApplyColoration: 1
       bApplyAmplitudeDistr: 1
          bApplyModulations: 1
         bApplyComodulation: 1
     bApplySpatialCoherence: 1
         bEstimateClickSpec: 1
                   bDeClick: 1
```

The default, ie. empty, model parameters sub-object looks like the following
(before the analysis step). Parameters which are not signal dependent are
initialized with default values, the rest is empty.

```matlab
>> obj.ModelParameters

  NoiseSynthesis.ModelParametersSet with properties:

                    Model: 'manual'
     ModulationFilterbank: 'mel'
          ModulationDepth: [16x1 double]
          ModulationSpeed: 'fast'
         MarkovTransition: []
    MarkovStateBoundaries: [10x2 double]
               GammaBands: []
          ClickTransition: []
              fLowerClick: 2000
              fUpperClick: 6000
                 SNRclick: Inf
                  MeanPSD: []
              ColorNumOrd: 8
            ColorDenumOrd: 8
           AmplitudeModel: 'pareto'
                Quantiles: []
                      CDF: []
              CohereModel: 'cylindrical'
          SensorPositions: [3x2 double]
           SourcePosition: [3x1 double]
             bApplyClicks: 0
         ModulationWinLen: 0.0250
```

There is also the possibility to view simple error measures between the
analysis and synthesis signals if available.

```matlab
>> obj.ErrorMeasures

  ErrorMeasures with properties:

               ColorationError: 0.1833
         SpatialCoherenceError: 0.0016
            ComodulationsError: 0.0037
    AmplitudeDistributionError: 0.0035
               ModulationError: 827.1058
          AmplitudeErrorMethod: 'Bhattacharyya'
                PsdErrorMethod: 'cosh'
         ModulationErrorMethod: 'KullbackLeibler'

```


### Class Methods

The following public methods are implemented (in alphabetical order):

```matlab
>> methods(NoiseSynthesis.NoiseAnalysisSynthesis)

Methods for class NoiseSynthesis.NoiseAnalysisSynthesis:

NoiseAnalysisSynthesis  % the constructor
analyze
flushParameters
playAnalyzed
playSynthesized
plot
readParameters
saveParameters
saveSignals
sound
soundsc
synthesize
```

### Analyze the Noise Process

To start the analysis if a desired signal has been passed in the constructor
call the `analyze` method by

```matlab
analyze(obj); % or equivalently
obj.analyze();
```

### Synthesize an Artificial Noise Process

When a complete model parameter set is present, ie. obj.ModelParameters has all
information, the `synthesis` method can be called by

```matlab
synthesize(obj); % or equivalently
obj.synthesize();
```

Now, the synthesized signal is available in `obj.SensorSignals` or it can be
directly retrieved by calling

```matlab
SynthSignal = synthesize(obj); % or equivalently
SynthSignal = obj.synthesize();
```

## Examples

### Analysis and Synthesis of a Monaural Noise Signal

A complete example of the easiest way to use the analysis and synthesis methods
is shown below.

```matlab
% signal to be analyzed
[vSignal, fs] = audioread('noise.wav');

% create the object
obj = NoiseSynthesis.NoiseAnalysisSynthesis(vSignal,fs);

% call analysis and synthesize a two-channel signal
obj.analyze();
obj.synthesize();

% listen to results in comparison to analysis signal
sound(obj);

% plot some characteristics
plot(obj);
```

### Synthesis using a Parameter Preset

It is possible to choose from a small set of presets for a synthesis. Supported
presets for now are

- optical
- tape
- vinyl
- rain
- applause

and are saved as mat-Files in the package folder `+NoiseSynthesis`. The
following example shows the synthesis with presets.

```matlab
% create the object without parameters
obj = NoiseSynthesis.NoiseAnalysisSynthesis();

% load parameters, for example vinyl
obj.loadParameters(fullfile('+NoiseSynthesis', 'vinyl'))

% synthesize a noise signal
obj.synthesize();

% listen to results in comparison to analysis signal
sound(obj);

% plot some characteristics
plot(obj)
```

### Saving New Presets

It is of course possible to save own presets when there is access to an
isolated noise files. To do so, follow the example by using the
`saveParameters` method.

```matlab
% signal to be analyzed
[vSignal, fs] = audioread('noise.wav');

% create the object
obj = NoiseSynthesis.NoiseAnalysisSynthesis(vSignal,fs);

% call analysis
obj.analyze;

% now: save the parameters with desired file name
obj.saveParameters(fullfile('+NoiseSynthesis', 'myNoiseParameters'))
```

Use the presets as shown in the previous example.


## License

The software is published under BSD 3-Clause license.


    Copyright (c) 2016, Jens-Alrik Adrian
    Institute for Hearing Technology and Audiology
    Jade University of Applied Sciences
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are
    met:

    	1. Redistributions of source code must retain the above copyright
    	   notice, this list of conditions and the following disclaimer.

    	2. Redistributions in binary form must reproduce the above copyright
    	   notice, this list of conditions and the following disclaimer in
    	   the documentation and/or other materials provided with the
    	   distribution.

    	3. Neither the name of the copyright holder nor the names of its
    	   contributors may be used to endorse or promote products derived
    	   from this software without specific prior written permission.

     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
     IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
     TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
     PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
     HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
     SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
     TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
     PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
     LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
     NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
     SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
