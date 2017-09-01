function [vClicks] = genclickmarkov(obj)
%GENCLICKMARKOV Generate click signal using Markov chain and Välimäki parameters
% -------------------------------------------------------------------------
%
% Usage: [vClicks] = genclickmarkov(obj)
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  30-Nov-2015 20:21:35
%


vStateChange = rand(1,obj.DesiredSignalLenSamples);

% CDF of probabilities
mCumTrans = full(cumsum(obj.ModelParameters.ClickTransition,2));

% normalize if sum is not 1
mCumTrans = bsxfun(@rdivide,mCumTrans,mCumTrans(:,end));

% first state is no click, ie. state 1
iCurrentState = 1;

vClicks = zeros(obj.DesiredSignalLenSamples,1);
for aaStep = 1:obj.DesiredSignalLenSamples
    % grab the random probability from the dice
    probStateChange = vStateChange(aaStep);
    
    % find the next state that is probable according to the
    % random vector
    vIdx = find(mCumTrans(iCurrentState,:) >= probStateChange);
    
    if vIdx
        iState = vIdx(1);
    else
        % if the state change fails, take the default state, i.e.
        % no click
        iState = 1;
    end
    
    vClicks(aaStep) = iState == 2;
    
    % update the current state
    iCurrentState = iState;
end

vAmplitudes = random(...
    'lognormal',...
    obj.ModelParameters.muLog,obj.ModelParameters.sigmaLog,...
    [sum(vClicks == 1),1]);
vClicks(vClicks == 1) = vAmplitudes;

%create the time varying LP filter and filter the clicks in blocks
mClickBlock = buffer(...
    vClicks,...
    round(obj.ModelParameters.clickBlocklenSec * obj.Fs),...
    obj.ModelParameters.clickOverlap,...
    'nodelay');

fLower = obj.ModelParameters.fLowerClick / obj.Fs * 2;
fUpper = obj.ModelParameters.fUpperClick / obj.Fs * 2;
meanClick = fLower;
stdClick  = fUpper - fLower;
for aaBlock = 1:size(mClickBlock,2)
    [b,a] = butter(...
        obj.ModelParameters.clickFilterOrder,...
        rand * stdClick + meanClick,...
        'low');
    
    mClickBlock(:,aaBlock) = filter(b,a,mClickBlock(:,aaBlock));
end

% expand to vector
vClicks = mClickBlock(:);
vClicks = vClicks(1:obj.DesiredSignalLenSamples);


% End of file: genclickmarkov.m
