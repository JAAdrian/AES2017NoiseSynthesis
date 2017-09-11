classdef AmplitudeAnalysis < matlab.System
%AMPLITUDEANALYSIS <purpose in one line!>
% -------------------------------------------------------------------------
% <Detailed description of the function>
%
% AmplitudeAnalysis Properties:
%	propA - <description>
%	propB - <description>
%
% AmplitudeAnalysis Methods:
%	doThis - <description>
%	doThat - <description>
%
% Author :  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date   :  09-Sep-2017 23:26:30
%

% History:  v0.1.0   initial version, 09-Sep-2017 (JA)
%
    
    
    properties (Access = public)
        AmplitudeModel;
    end
    
    properties (SetAccess = protected)
        Parameters;
    end
    
    properties (Access = protected)
        Percentiles;
    end
    
    properties (Hidden, Transient)
        AmplitudeModelSet = matlab.system.StringSet({...
            'Full', ...
            'Percentile', ...
            'Pareto' ...
            });
    end
    
    
    methods
        function [obj] = AmplitudeAnalysis(varargin)
            obj.AmplitudeModel = 'Pareto';
            obj.Percentiles    = [0, 100];
            
            obj.setProperties(nargin, varargin{:})
        end
    end
    
    
    methods (Access = protected)
        function [] = setupImpl(obj, ~)
            obj.Parameters = struct(...
                'Quantiles', [], ...
                'Cdf', [] ...
                );
        end
        
        function [parameters] = stepImpl(obj, signal)
            switch obj.AmplitudeModel 
                case 'Full'
                    [obj.Parameters.Cdf, obj.Parameters.Quantiles] = ecdf(...
                        signal ...
                        );
                    
                    obj.Parameters.Cdf = ...
                        (obj.Parameters.Cdf(1:end-1) + obj.Parameters.Cdf(2:end))/2;
                    obj.Parameters.Quantiles = obj.Parameters.Quantiles(2:end);
                    
                case 'Percentile'
                    cdf = 0:100;
                    prc = prctile(signal, cdf);
                    
                    obj.ModelParameters.Quantiles = prc;
                    obj.ModelParameters.Cdf       = cdf ./ 100;
                    
                case 'Pareto'
                    % source for piecewise Pareto:
                    % http://de.mathworks.com/help/stats/fit-a-nonparametric-distribution-with-pareto-tails.html
                    
                    import NoiseAnalysisSynthesis.external.*
                    
                    numPoints = 1000;
                    
                    quantiles = linspace(...
                        min(signal), ...
                        max(signal), ...
                        numPoints ...
                        );
                    
                    normmean = mean(signal);
                    normstd  = std(signal);
                    
                    midPdf = normpdf(quantiles, normmean, normstd);
                    
                    [densy, densx] = ksdensity(signal, 'npoints', numPoints);
                    
                    percRangeLower = [0.001, 0.20];
                    percRangeUpper = [0.80,  0.999];
                    
                    idxLower = find(...
                        quantiles >= prctile(signal, percRangeLower(2)*100), ...
                        1, 'first' ...
                        );
                    idxUpper = find(...
                        quantiles >= prctile(signal, percRangeUpper(1)*100), ...
                        1, 'first' ...
                        );
                    
                    percLower = intersections(...
                        densx(1:idxLower), ...
                        densy(1:idxLower), ...
                        quantiles(1:idxLower), ...
                        midPdf(1:idxLower) ...
                        );
                    percUpper = intersections(...
                        quantiles(idxUpper:end), ...
                        midPdf(idxUpper:end), ...
                        densx(idxUpper:end), ...
                        densy(idxUpper:end) ...
                        );
                    
                    [y, x] = ecdf(signal);
                    x = (x(1:end-1) + x(2:end)) / 2;
                    y = (y(1:end-1) + y(2:end)) / 2;
                    
                    percLower = interp1(x, y, percLower, 'linear');
                    percUpper = interp1(x, y, percUpper, 'linear');
                    
                    
                    % if no intersections found: use defaults
                    if isempty(percLower)
                        percLower = 0.05;
                    else
                        percLower  = percLower(...
                            percLower >= percRangeLower(1) & ...
                            percLower <= percRangeLower(2) ...
                            );
                        percLower = percLower(1);
                    end
                    if isempty(percUpper)
                        percUpper = 0.95;
                    else
                        percUpper = percUpper(...
                            percUpper >= percRangeUpper(1) & ...
                            percUpper <= percRangeUpper(2) ...
                            );
                        percUpper = percUpper(end);
                    end
                    
                    parTailsAdjusted = paretotails(signal, percLower, percUpper);
                    
                    lowerParams = parTailsAdjusted.lowerparams;
                    upperParams = parTailsAdjusted.upperparams;
                    
                    pl = parTailsAdjusted.boundary(1);
                    pu = parTailsAdjusted.boundary(2);
                    
                    obj.Parameters.Quantiles = prctile(...
                        signal, ...
                        [0, pl*100, pu*100, 100] ...
                        );
                    obj.Parameters.Quantiles(end+1:end+2) = [pl; pu];
                    
                    obj.Parameters.Cdf = [
                        lowerParams;
                        normmean, normstd;
                        upperParams ...
                        ];
            end
            
            if nargout
                parameters = obj.Parameters;
            end
        end
    end
    
end





% End of file: AmplitudeAnalysis.m
