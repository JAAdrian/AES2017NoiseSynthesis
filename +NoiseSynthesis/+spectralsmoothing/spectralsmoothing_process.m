function [H_sm, stAlgo] = spectralsmoothing_process(H, stAlgo)

%% Implementation of the algorithm described in
%     "Generalized Fractional-Octave Smoothing of Audio and Acoustic
%     Responses", P. D. Hatziantoniou and J. N. Mourjopoulos

% $Revision: 29 $
% $Author: brandt $
% $Date: 2011-03-30 20:43:53 +0200 (Mi, 30 Mrz 2011) $

% TODO: only process half of the spectrum!

%% perform the smoothing...
H = [H; conj(H(end-1:-1:2,:))];
H_sm = zeros(stAlgo.L_FFT, 1);

Wtilde_sm = zeros(1,stAlgo.L_FFT);
for k = 1 : (stAlgo.L_FFT)
    curM = stAlgo.m(k);
    
    % the following lines are based on M. Ruhland's C++ implementation...
    Wtilde_sm(curM) = stAlgo.W_sm(curM, 1);
    for l = 1 : curM
        Wtilde_sm(l) = stAlgo.W_sm(curM, stAlgo.L_FFT-curM+l);
    end
    for l = curM+1 : 2*curM+1
        Wtilde_sm(l) = stAlgo.W_sm(curM, l-curM);
    end

    for nn = k-curM : k+curM
        H_sm(k) = H_sm(k) + H(mod(nn+stAlgo.L_FFT-1, stAlgo.L_FFT)+1) * Wtilde_sm(nn-(k-curM)+1);
    end
end

% for our purposes (denoising) the first half of the spectrum is enough...
H_sm = H_sm(1:stAlgo.L_FFT/2+1);

end % of function
