function [vOut] = adjustLength(vIn,lenSig,vPositions)
%ADJUSTLENGTH Adjust the length of a click track
% -------------------------------------------------------------------------
% If lenSig is less than the maximum value in vPositions then vIn will be
% cropped to length lenSig. Else the missing part will be filled with parts
% from the start.
%
% Usage: [vOut] = adjustLength(vIn,lenSig,vPositions)
%
%
%
% Author :  J.-A. Adrian (JA) <jens-alrik.adrian AT jade-hs.de>
% Date   :  16-Jul-2014 22:43:48
%


if max(vPositions) < lenSig,
    lenDiff = lenSig - max(vPositions);
    vOut = vIn;
    vOut(max(vPositions)+1:end) = vIn(1:lenDiff);
else
    vOut = vIn(1:lenSig);
end




% End of file: <adjustLength.m>
