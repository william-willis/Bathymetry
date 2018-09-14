%% calculateAngle.m
% Given receiver-point distances r1 and r2, and distance between receivers,
% B, calculate angle theta of point relative to receiver-receiver line
function theta = calculateAngle(r1, r2, B)
    y = (r2^2 - r1^2 - B^2)/(2*B);
    theta = acosd((B + y)/r2);
end