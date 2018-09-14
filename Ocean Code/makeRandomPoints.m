%% Simulation Parameters
B = 1;
minAngle = 60;
angleRange = 120;
minDist = 150;
distRange = 200;
minH = -200;
hRange = 150;
numPoints = 1000;

%% Finding r1 and r2 for simulated points 
points = zeros(numPoints, 1);
r1 = zeros(numPoints, 2);
r2 = zeros(numPoints, 2);
angles = zeros(numPoints, 1);
for i = 1:numPoints
   angle = minAngle + rand*angleRange;
   dist = minDist + rand*distRange;%distance from r1 along the horizontal plane
   h = minH + rand*hRange;
   
   angles(i) = angle;
   
   r1(i, 1) = dist;
   r1(i, 2) = h;
   r2(i, 1) = sqrt((dist*cosd(angle) + B)^2 + (dist*sind(angle))^2);
   r2(i, 2) = h;
end

save('Testr1pts','r1');
save('Testr2pts','r2');
