function [b,a] = FDLS(N_Order, D_Order, Freq_Vec, Magnitude, Phase, fs_Hz, vWeights)
% [b,a] = FDLS(N_Order, D_Order, Freq_Vec, Magnitude, Phase, fs_Hz)
%
% IN:
% N_Order               numerator order  (number of zeros -1)
% D_Order               denominator order (nuber of poles)
% Freq_Vec              frequency values [Hz]
% magnitude             magnitude values (linear)
% phase radians         phase (radians)
%
% OUT:
% b,a                   filter coefficients
%

%  Implements FDLS method after 'Precise Filter Design' by Greg Berchin
% (c) Thorsten Schmidt
%
% Update: 07-Aug-2015 13:16:07 (JA):    - Optional freq. weighting
%                                       - rearranged some code
%

% make sure every vector is a column vector
Freq_Vec  = Freq_Vec(:);
Magnitude = Magnitude(:);
Phase     = Phase(:);

if nargin > 7 || isempty(vWeights),
    vWeights = ones(length(Phase),1);
end
vWeights = vWeights(:);

% Create normalized freuency
Omega = (2*pi*Freq_Vec) / fs_Hz;

% create Outsig (y)
y = Magnitude.*cos(Phase) .* vWeights;


% create Inputmatrix (X)

% recursive part
X_D = zeros(length(Omega),D_Order);  % (JA) initialize matrix
for k=1:D_Order
   X_D(:,k) = -Magnitude.*cos (-k * Omega + Phase) .* vWeights;
end

% non recursive part
X_N = zeros(length(Omega),N_Order-1);   % (JA) initialize matrix
for k=1:N_Order-1
   X_N(:,k) = cos (-k * Omega) .* vWeights;
end

X = [X_D ones(length(Magnitude),1) X_N];


% calculate filter coefficients
% Coeff = X\y;
Coeff = pinv(X) * y;   % (JA) use the numerically robust pseudoinverse
                       % and apply weighted LSQ (WLSQ)


b = Coeff(D_Order+1:D_Order+N_Order)';

a = [1 Coeff(1:D_Order)'];
