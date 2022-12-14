function [] = generateCoherentClicks(self)
%GENERATECOHERENTCLICKS Generate click signals with desired spatial coherence
% -------------------------------------------------------------------------
%
% Usage: [] = generateCoherentClicks(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:13:23
%


caClickTracks = cellfun(@(x) genArtificialClicks(self),...
    cell(self.NumSensorSignals,1),...
    'uni',false);

% apply coherence
bComputePSD = true;
mCoherentClicks = mixSignals(self, caClickTracks, bComputePSD);

% change format for further processing
for aaSignal = 1:self.NumSensorSignals,
    self.ClickTracks{aaSignal} = squeeze(mCoherentClicks(aaSignal,:,:)).';
end



% End of file: generateCoherentClicks.m
