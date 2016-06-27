function [] = plot(self)
%PLOT Plot the analyzed and synthesized signal properties for comparison
% -------------------------------------------------------------------------
% This class method overloads the default MATLAB plot function to provide
% an easy plot interface for objects of type
% NoiseSynthesis.NoiseAnalysisSynthesis
%
% Usage: [] = plot(self)
%
%   Input:   ---------
%           self: Object of type NoiseSynthesis.NoiseAnalysisSynthesis
%
%  Output:   ---------
%           none
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  02-Dec-2015 16:32:13
%

import NoiseSynthesis.external.*


caNPoints   = {'npoints',1e3};

caTextProps = {'fontsize',14};

[hTimeSig,hWelch,hSpectro,hModSpec,hDens,hCohere] = plotstack(6,50);
pause(1);

len = self.lenSignalPlotAudio;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmpblocklen = round(20e-3*self.Fs);
tmpoverlap  = round(tmpblocklen*0.5);
tmpnfft     = pow2(nextpow2(tmpblocklen) + 2);
vTmpWin     = hann(tmpblocklen,'periodic');

figure(hSpectro);

if ~isempty(self.AnalysisSignal),
    ha(1) = subplot(211); 
    STFT(self.AnalysisSignal(1:len),vTmpWin,tmpoverlap,tmpnfft,self.Fs);
    clim = get(gca,'clim');
    set(gca,'clim',[clim(2)-80,clim(2)],caTextProps{:});
    title('Spectrogram of the Desired Signal',caTextProps{:});
    colorbar;
    ylim([0 min(self.Fs/2,self.GammatoneHighestBand)]);
    ha(2) = subplot(212); 
    STFT(self.SensorSignals(1:len, 1),...
        vTmpWin,tmpoverlap,tmpnfft,self.Fs);
    set(gca,'clim',[clim(2)-80, clim(2)],caTextProps{:});
    title('Spectrogram of the Synthesized Signal',caTextProps{:});
    colorbar;
    linkaxes(ha,'xy');
else
    STFT(scaleSignal(self.SensorSignals(1:len, 1), std(self.AnalysisSignal)),...
        vTmpWin,tmpoverlap,tmpnfft,self.Fs);
    clim = get(gca,'clim');
    set(gca,'clim',[clim(2)-80, clim(2)],caTextProps{:});
    title('Spectrogram of the Synthesized Signal',caTextProps{:});
    colorbar;
end
drawnow;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~self.bApplyAmplitudeDistr,
    self.ModelParameters.AmplitudeModel = 'full';
end

switch self.ModelParameters.AmplitudeModel,
    case {'full','percentile'},
        [vDensSynth,vXSynth] = ksdensity(self.SensorSignals(:, 1),caNPoints{:});
        
    case 'gmm',
        vXSynth = linspace(...
            min(self.AnalysisSignal),...
            max(self.AnalysisSignal),...
            caNPoints{2});
        
        mPDFs = zeros(caNPoints{2},self.ModelParameters.NumGaussModels);
        for aaGauss = 1:self.ModelParameters.NumGaussModels,
            mPDFs(:,aaGauss) = self.ModelParameters.CDF{2}(aaGauss) * ...
                normpdf(...
                vXSynth,...
                self.ModelParameters.CDF{1}(aaGauss),...
                sqrt(self.ModelParameters.CDF{3}(aaGauss))...
                );
        end
        
        vDensSynth = sum(mPDFs,2);
        
    case 'alpha',
        import NoiseSynthesis.stbl_matlab.*
        
        vXSynth = linspace(...
            self.ModelParameters.Quantiles(1),...
            self.ModelParameters.Quantiles(2),...
            caNPoints{2});
        
        vDensSynth = stblpdf(...
            vXSynth,...
            self.ModelParameters.CDF(1),...
            self.ModelParameters.CDF(2),...
            self.ModelParameters.CDF(3),...
            self.ModelParameters.CDF(4)...
            );
        
        [vXSynth,vDensSynth] = makeCDFrobust(vXSynth,vDensSynth);
        
    case 'pareto',
        [vDensSynth, vXSynth] = PiecewiseParetoPDF(self,caNPoints{2});
end

figure(hDens);
semilogy(vXSynth,vDensSynth,'color',0*[1 1 1],'linewidth',1);
ax = gca;


if ~isempty(self.AnalysisSignal),
    [vDensDesired,vXDesired] = ksdensity(self.vBeforeDeCrackling,caNPoints{:});
    [vDensGauss]             = normpdf(vXDesired,0,std(self.vBeforeDeCrackling));
    
    hold on;
    semilogy(ax,vXDesired,vDensDesired,'color',0.7*[1 1 1],'linewidth',1);
    semilogy(ax,vXDesired,vDensGauss,'b--','linewidth',1); hold off;
    
    legend({...
        'Synthesized Distribution',...
        'Desired Distribution',...
        char({'Normal Distr. with', 'equal variance'})},...
        'location','south',...
        'Orientation','vertical',...
        caTextProps{:});
    
    title({'Kernel Density Estimation of Amplitude Distribution',...
        sprintf('%s: %.2e',...
        self.ErrorMeasures.AmplitudeErrorMethod, ...
        self.ErrorMeasures.AmplitudeDistributionError)});
else
    [vDensGauss] = normpdf(vXSynth,0,std(self.SensorSignals(:, 1)));
    
    hold on;
    semilogy(ax,vXSynth,vDensGauss,'b--','linewidth',1); hold off;
    
    legend({...
        'Synthesized Distribution',...
        char({'Normal Distr. with', 'equal variance'})},...
        'location','south',...
        'Orientation','vertical',...
        caTextProps{:});
    
    title('Kernel Density Estimation of Amplitude Distribution');
end

xlabel('Amplitude',caTextProps{:});
ylabel('Probability Density (log)',caTextProps{:});
set(gca,caTextProps{:});
axis tight;
grid on;
vYlim = get(gca,'ylim');
ylim([max(vYlim(1),1e-5) inf]);
drawnow;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmpblocklen = round(50e-3*self.Fs);
tmpoverlap  = round(tmpblocklen*0.5);
tmpnfft     = pow2(nextpow2(tmpblocklen));
vTmpWin     = hann(tmpblocklen,'periodic');

[vPSDSynth,vFreqSynth] = pwelch(...
    scaleSignal(self.SensorSignals(:, 1), std(self.AnalysisSignal)),...
    vTmpWin,tmpoverlap,tmpnfft,self.Fs);

figure(hWelch);
plot(vFreqSynth,10*log10(vPSDSynth),'color',0*[1 1 1],'linewidth',1);

hold on;
if ~isempty(self.AnalysisSignal),
    [vPSD,vFreq] = pwelch(self.AnalysisSignal,vTmpWin,tmpoverlap,tmpnfft,self.Fs);
    
    plot(vFreq,10*log10(vPSD),'color',0.6*[1 1 1],'linewidth',1);
    
    plot(self.CutOffHP*[1 1],ylim,'b--');
    
    title({...
        'Power Spectral Densities',...
        sprintf('%s: %.2f',...
        self.ErrorMeasures.PsdErrorMethod, ...
        self.ErrorMeasures.ColorationError)...
        });
    
    legend({'Synthesized PSD','Desired PSD','HP cutoff freq.'},...
        'location','southeast',caTextProps{:});
else
    plot(self.CutOffHP*[1 1],ylim,'b--');
    
    title('Power Spectral Densities');
    legend({'Synthesized PSD','HP cutoff freq.'},...
        'location','southeast',caTextProps{:});
end
hold off;

set(gca,'xscale','log',caTextProps{:});

xlabel('Frequency in Hz',caTextProps{:});
ylabel('Power Spectral Density in dB re. 1^2/Hz',caTextProps{:});
grid on;
axis tight;

drawnow;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(hTimeSig);
vTime = (0:len-1).'/self.Fs;
plot(vTime,scaleSignal(self.SensorSignals(1:len,1),std(self.AnalysisSignal)), ...
    'color',0*[1 1 1]); 

if ~isempty(self.AnalysisSignal),
    hold on;
    plot(vTime,self.AnalysisSignal(1:len),'color',0.7*[1 1 1]); 
    hold off;
    
    legend({'Synthesized Time Signal','Desired Time Signal'},...
        caTextProps{:},'location','northwest');
else
    legend({'Synthesized Time Signal'},...
        caTextProps{:},'location','northwest');
end

title('Time Signals',caTextProps{:});
xlabel('Time in s',caTextProps{:});
ylabel('Amplitude',caTextProps{:});

set(gca,caTextProps{:});
axis tight;
drawnow;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmpblocklen = round(15e-3*self.Fs);
tmpoverlap  = round(tmpblocklen*0.60);
tmpnfft     = pow2(nextpow2(tmpblocklen));
vTmpWin     = hann(tmpblocklen,'periodic');


[mModSpecSynth,vFreq,vModFreq] = ...
    ModulationSpectrogram(...
    scaleSignal(self.SensorSignals(1:len, 1),std(self.AnalysisSignal)),...
    vTmpWin,tmpoverlap,tmpnfft,self.Fs);


figure(hModSpec);
if ~isempty(self.AnalysisSignal),
    mModSpecAnal = ...
        ModulationSpectrogram(self.AnalysisSignal(1:len),...
        vTmpWin,tmpoverlap,tmpnfft,self.Fs);
    
    ha(1) = subplot(211);
    surf(vModFreq,vFreq,10*log10(abs(mModSpecAnal)),'edgecolor','none');
    axis tight;
    set(gca,'view',[0,90]);
    colorbar;
    box on;
    title('Modulation Spectrum of the Desired Signal',caTextProps{:});
    xlabel('Modulation Frequency in Hz');
    ylabel('Center Frequency in Hz');
    clim = get(gca,'clim');
    set(gca,caTextProps{:});
    
    ha(2) = subplot(212);
    surf(vModFreq,vFreq,10*log10(abs(mModSpecSynth)),'edgecolor','none');
    axis tight;
    set(gca,'view',[0,90]);
    colorbar;
    box on;
    title('Modulation Spectrum of the Synthesized Signal',caTextProps{:});
    xlabel('Modulation Frequency in Hz');
    ylabel('Center Frequency in Hz');
    set(gca,'clim',clim);
    set(gca,caTextProps{:});
    linkaxes(ha,'xy');
else
    surf(vModFreq,vFreq,10*log10(abs(mModSpecSynth)),'edgecolor','none');
    axis tight;
    set(gca,'view',[0,90]);
    colorbar;
    box on;
    title('Modulation Spectrum of the Synthesized Signal',caTextProps{:});
    xlabel('Modulation Frequency in Hz');
    ylabel('Center Frequency in Hz');
    set(gca,caTextProps{:});
end



drawnow;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
plotfun = @real;

tmpblocklen = 50e-3;
tmpblocklen = round(tmpblocklen * self.Fs);
tmpnfft     = pow2(nextpow2(tmpblocklen));
vTmpWin     = hann(tmpblocklen,'periodic');
tmpoverlap  = round(tmpblocklen * 0.5);

iSensor1 = 1;
iSensor2 = min(self.NumSensorSignals,2);


vPpp = cpsd(self.SensorSignals(:, iSensor1),...
    self.SensorSignals(:, iSensor1),vTmpWin,tmpoverlap,tmpnfft);
vPqq = cpsd(self.SensorSignals(:, iSensor2),...
    self.SensorSignals(:, iSensor2),vTmpWin,tmpoverlap,tmpnfft);
vPpq = cpsd(self.SensorSignals(:, iSensor1),...
    self.SensorSignals(:, iSensor2),vTmpWin,tmpoverlap,tmpnfft);

vFreq = linspace(0,self.Fs/2,tmpnfft/2+1);
vGammaEst = vPpq ./ sqrt(vPpp .* vPqq);


d = norm(self.ModelParameters.SensorPositions(:,iSensor1) - ...
    self.ModelParameters.SensorPositions(:,iSensor2));

mPSD   = [1 1];
vGamma = self.hCohereFun(vFreq,d,self.mTheta(iSensor1,iSensor2,:),mPSD);

figure(hCohere);
hPlot(1) = plot(vFreq,plotfun(vGammaEst),'linewidth',1); hold all;
hPlot(2) = plot(vFreq,plotfun(vGamma),'linewidth',1);    hold off
legend(hPlot,'Synthesized Coherence','Desired Coherence',...
    'location','north');
xlabel('Frequency in Hz');
ylabel('Spatial Coherence');
title({'Synthesized Spatial Coherence',...
    sprintf('Model: %s, %s part, MSE: %.2e',self.ModelParameters.CohereModel,...
    func2str(plotfun),...
    self.ErrorMeasures.SpatialCoherenceError)});
axis tight;
grid on;
box off;
set(gca,caTextProps{:});
axis([0, min(self.Fs/2,self.GammatoneHighestBand), -1, 1]);



end

function [out] = scaleSignal(in, stdReference)
if isnan(stdReference),
    % do nothing because there is no analysis signal
    stdReference = std(in);
end

out = in / std(in) * stdReference;
end







% End of file: plot.m
