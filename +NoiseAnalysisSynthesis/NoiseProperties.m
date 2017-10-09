classdef NoiseProperties < matlab.System
%NOISEPROPERTIES <purpose in one line!>
% -------------------------------------------------------------------------
% <Detailed description of the function>
%
% NoiseProperties Properties:
%	propA - <description>
%	propB - <description>
%
% NoiseProperties Methods:
%	doThis - <description>
%	doThat - <description>
%
% Author :  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date   :  03-Sep-2017 20:45:07
%


properties
    ModulationDepth;  % Modulation depth for all freq. bands
    MarkovTransition; % Transition matrix for the modulation modeling
    MarkovStateBoundaries; % Markov state boundaries in dB
    
    BandCorrelationMatrix; % Inter-band correlation matrix
    
    MeanPsd; % PSD vector
    
    Quantiles; % Independent variable of ECDF or holds information for other models
    Cdf; % Dependent variable of ECDF or holds information for other models
    
    ClickTransition;
    LowerEdgeClick = 2e3; % Lower cutoff freq. for HP filter
    UpperEdgeClick = 6e3; % upper cutoff freq. for HP filter
    SnrClick = inf; % SNR between base noise and click signal
end

end



% End of file: NoiseProperties.m
