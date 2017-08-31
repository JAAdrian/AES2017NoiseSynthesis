function [] = analyzeAmplitudeDistribution(self)
%ANALYZEAMPLITUDEDISTRIBUTION Retrieve amplitude distribution parameters
% -------------------------------------------------------------------------
%
% Usage: [] = analyzeAmplitudeDistribution(self)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:00:12
%

import NoiseSynthesis.external.*


vAnalysisPrctile = [0.0, 100];

switch self.ModelParameters.AmplitudeModel
    case 'alpha'
        import NoiseSynthesis.stbl_matlab.*
        
        self.ModelParameters.Quantiles = ...
            prctile(self.AnalysisSignal, vAnalysisPrctile);
        
        vPrc = prctile(self.AnalysisSignal,[1,99]);
        vAnalysisSig = self.AnalysisSignal;
        vAnalysisSig(vAnalysisSig < vPrc(1)) = vPrc(1);
        vAnalysisSig(vAnalysisSig > vPrc(2)) = vPrc(2);
        
        self.ModelParameters.CDF = stblfit(vAnalysisSig);
        
    case 'gmm'
        import NoiseSynthesis.GMM_toolbox.*
        
        szCovarType = 'diag';
        p_delta_min = 0.01;
        numMaxLoops = 20;
        
        [initCenters,caClusterData] = ...
            LBG_VQ_codebook(...
            self.AnalysisSignal,...
            self.ModelParameters.NumGaussModels,...
            p_delta_min);
        
        stGMM = gmm_init(...
            size(self.AnalysisSignal,2),...
            self.ModelParameters.NumGaussModels,...
            szCovarType,...
            initCenters,...
            caClusterData,...
            length(self.AnalysisSignal),...
            p_delta_min...
            );
        
        stGMM = gmm_em(...
            stGMM,...
            self.AnalysisSignal,...
            p_delta_min,...
            numMaxLoops);
        
        self.ModelParameters.Quantiles = ...
            prctile(self.AnalysisSignal, vAnalysisPrctile);
        self.ModelParameters.CDF = ...
            {stGMM.mCenters, stGMM.vPriors, stGMM.mCovars};
        
        self.ModelParameters.NumGaussModels = length(stGMM.mCenters);
        
    case 'full'
        [self.ModelParameters.CDF,self.ModelParameters.Quantiles] = ...
            ecdf(self.AnalysisSignal);
        
        self.ModelParameters.CDF = ...
            (self.ModelParameters.CDF(1:end-1) + self.ModelParameters.CDF(2:end))/2;
        self.ModelParameters.Quantiles = ...
            self.ModelParameters.Quantiles(2:end);
        
    case 'percentile'
        vCDF   = 0:100;
        vPrctl = prctile(self.AnalysisSignal,vCDF);
        
        self.ModelParameters.Quantiles = vPrctl;
        self.ModelParameters.CDF       = vCDF ./ 100;
        
    case 'pareto'
        % source for piecewise Pareto:
        % http://de.mathworks.com/help/stats/fit-a-nonparametric-distribution-with-pareto-tails.html
        
        vQuantiles = linspace(...
            min(self.AnalysisSignal),...
            max(self.AnalysisSignal),...
            1000);
        
        normmean = mean(self.AnalysisSignal);
        normstd  = std(self.AnalysisSignal);
        
        vMidPDF = normpdf(vQuantiles,normmean,normstd);
        
        [dens,densx] = ksdensity(self.AnalysisSignal,'npoints',1000);
        
        percRangeLower = [0.001 0.20];
        percRangeUpper = [0.80 0.999];
        
        idxLower = find(vQuantiles >= prctile(self.AnalysisSignal,...
            percRangeLower(2)*100),1,'first');
        idxUpper = find(vQuantiles >= prctile(self.AnalysisSignal,...
            percRangeUpper(1)*100),1,'first');
        
        [perclower] = intersections(...
            densx(1:idxLower),dens(1:idxLower),...
            vQuantiles(1:idxLower),vMidPDF(1:idxLower));
        [percupper] = intersections(...
            vQuantiles(idxUpper:end),vMidPDF(idxUpper:end),...
            densx(idxUpper:end),dens(idxUpper:end));
        
        [y,x] = ecdf(self.AnalysisSignal);
        x = (x(1:end-1) + x(2:end)) / 2;
        y = (y(1:end-1) + y(2:end)) / 2;
        
        perclower = interp1(x,y,perclower,'linear');
        percupper = interp1(x,y,percupper,'linear');
        
        
        % if no intersections found: use defaults
        if isempty(perclower)
            perclower = 0.05;
        else
            perclower  = perclower(...
                perclower >= percRangeLower(1) & ...
                perclower <= percRangeLower(2));
            perclower = perclower(1);
        end
        if isempty(percupper)
            percupper = 0.95;
        else
            percupper = percupper(...
                percupper >= percRangeUpper(1) & ...
                percupper <= percRangeUpper(2));
            percupper = percupper(end);
        end
        
        %                 warning('off','stats:paretotails:ConvergedToBoundaryLower');
        partailsadjusted = paretotails(self.AnalysisSignal,perclower,percupper);
        %                 warning('on','stats:paretotails:ConvergedToBoundaryLower');
        
        vLowerParams = partailsadjusted.lowerparams;
        vUpperParams = partailsadjusted.upperparams;
        
        PL = partailsadjusted.boundary(1);
        PU = partailsadjusted.boundary(2);
        
        
        self.ModelParameters.Quantiles = prctile(...
            self.AnalysisSignal, [0,...
            PL*100,...
            PU*100,...
            100]);
        self.ModelParameters.Quantiles(end+1:end+2) = [PL; PU];
        
        self.ModelParameters.CDF = [
            vLowerParams;
            normmean, normstd;
            vUpperParams];
end




% End of file: analyzeAmplitudeDistribution.m
