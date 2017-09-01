function [] = saveSignals(obj,szSaveFilename,bStereo,szExt)
%SAVESIGNALS Save the analysis and synthesis signal to file
% -------------------------------------------------------------------------
% This class method provides means to save the analysis and synthesis
% signal to file. The analysis signal will have the szSaveFilename as file
% name, the synthesis signal will have szSaveFilename_synth.ext as filename.
%
% Usage: [] = saveSignals(obj,szSaveFilename)
%        [] = saveSignals(obj,szSaveFilename,bStereo)
%        [] = saveSignals(obj,szSaveFilename,bStereo,szExt)
%
%   Input:   ---------
%           obj: Object of type NoiseSynthesis.NoiseAnalysisSynthesis
%           szSaveFilename: Name stem of the created audio files
%           bStereo: Bool whether to save multichannel files [default: false]
%           szExt: Desired file type/extension [default: 'wav']
%
%
%  Output:   ---------
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  02-Dec-2015 16:23:44
%

assert(isa(szSaveFilename, 'char'), ['Pass a string corresponding to the ', ...
    'name of the audio file!']);
assert(isa(szExt, 'char'), ['Pass a string corresponding to the name of ', ...
    'the desired audio file extesion / type!']);
validateattributes(bStereo, {'logical', 'double'}, {'scalar', 'binary'})

if nargin < 4 || isempty(szExt)
    szExt = 'wav';
end
if nargin < 3 || isempty(bStereo)
    bStereo = false;
end


[szPath,szName,szTmpExt] = fileparts(szSaveFilename);

% account for '.' in the filename
szName = [szName szTmpExt];

szNewPath = fullfile(szPath,szName);
if ~exist(szNewPath,'dir')
    mkdir(szNewPath);
end

szFilename      = [fullfile(szNewPath,szName), '.', szExt];
szFilenameSynth = [fullfile(szNewPath,szName), '_synth', '.', szExt];

len = obj.lenSignalPlotAudio;

if ~isempty(obj.ClickTracks)
    vSaveSignal = nrmlz(obj.vOriginalAnalysisSignal,obj.soundLeveldB);
else
    vSaveSignal = nrmlz(obj.AnalysisSignal(1:len),obj.soundLeveldB);
end


if bStereo
    vSaveSignal      = vSaveSignal(:,ones(1,2));
    vSaveSignalSynth = nrmlz(...
        [...
        obj.SensorSignals(:, 1), obj.SensorSignals(:, 2)...
        ],obj.soundLeveldB);
else
    vSaveSignalSynth = nrmlz(obj.SensorSignals(:, 1),obj.soundLeveldB);
end


% check to not clip the signal
if any(abs(vSaveSignal) > 1)
    vSaveSignal = vSaveSignal ./ max(abs(vSaveSignal)) * 0.99;
end
if any(abs(vSaveSignalSynth) > 1)
    vSaveSignalSynth = vSaveSignalSynth ./ max(abs(vSaveSignalSynth)) * 0.99;
end


audiowrite(szFilename,vSaveSignal,obj.Fs);
audiowrite(szFilenameSynth,vSaveSignalSynth,obj.Fs);

end

function out = nrmlz(in,leveldB)
out = in ./ std(in(:,1)) * 10^(leveldB/20);
end





% End of file: saveSignals.m
