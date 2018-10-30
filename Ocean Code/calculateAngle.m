%% calculateAngle.m
% Given receiver-point distances r1 and r2, and distance between receivers,
% B, calculate angle theta of point relative to some reference based on
% number of receivers, as described below
%
% TODO figure out how to integrate into SAS so that all 3 sensors can use
% same function and output meaningful data
% TODO may need to take into account receiver rotation based on
% accelerometer data
function theta = calculateAngle(r1, r2, r3, B)
%% 2-receiver
% Assuming 2 receivers, calculates angle of point relative to line
% between both receivers
%     y = (r2^2 - r1^2 - B^2)/(2*B);
%     theta = acosd((B + y)/r2);

%% 3-receiver
% Assuming 3 receivers arranged in an equilateral triangle with sides of
% length B, calculates the angle of point relative to line drawn from a
% given receiver to opposite side of triangle
theta = 150 - acosd((-r2^2 + r1^2 + B^2)/(2*B*r1));
% Add 150 degrees if signal is received from same distance from r1/r2 but
% different distance from r3 (i.e. same distance but opposite side)
if (r3 < r1) && (r3 < r2)
    theta = theta + 150;
end

end