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
    ModulationDepth; % Modulation depth for all freq. bands
    MarkovTransition; % Transition matrix for the modulation modeling
    MarkovStateBoundaries; % Markov state boundaries in dB
    GammaBands; % Inter-band correlation matrix
    
    MeanPSD; % PSD vector
    
    Quantiles; % Independent variable of ECDF or holds information for other models
    CDF; % Dependent variable of ECDF or holds information for other models
end


methods
end

end



% End of file: NoiseProperties.m
