%% Simulation Parameters
B = 1;
minAngle = 0;
angleRange = 60;
minDist = 150;
distRange = 200;
minH = -200;
hRange = 150;
numPoints = 1000;

%% Creating simulated SAS data
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

figure(1)
clf
plot(r1(:, 1), r1(:, 2), 'ko')
% figure(2)
% clf
hold on
plot(r2(:, 1), r2(:, 2), 'ro')
xlabel('r')
ylabel('h')
legend('r1', 'r2')

%% Testing coregistration algorithm
%labels = coregister(r1, r2); 
labels = coregister2(r1, r2, minAngle, minAngle + angleRange, B); 
allIndices = (1:length(labels))';
score = sum(labels == allIndices)/length(labels)

%Show where the algorithm got the wrong answer
% missedIndices = allIndices(labels ~= allIndices);
% originalPoints = zeros(length(missedIndices), 2);
% guessedPoints = zeros(length(missedIndices), 2);
% actualPoints = zeros(length(missedIndices), 2);
% for i = 1:length(missedIndices)
%     missedIndex = missedIndices(i);
%     originalPoints(i, :) = r1(missedIndex, :);
%     guessedPoints(i, :) = r2(labels(missedIndex), :);
%     actualPoints(i, :) = r2(missedIndex, :);
% end
% figure(2)
% clf
% plot(originalPoints(:, 1), originalPoints(:, 2), 'bo', ...
%     guessedPoints(:, 1), guessedPoints(:, 2), 'r*', ...
%     actualPoints(:, 1), actualPoints(:, 2), 'g*')

%Calculate angles
calculatedAngles = zeros(numPoints, 1);
for i = 1:numPoints
    if labels(i) > 0 && labels(i) <= numPoints
        calculatedAngles(i) = calculateAngle(r1(i), r2(labels(i)), B);
    else
        calculatedAngles(i) = minAngle + angleRange/2;
    end
end

%Show how accurate angle calculations were
figure(3)
clf
plot(angles, 'b*')
hold on
plot(calculatedAngles, 'g*')
plot(abs(angles - calculatedAngles), 'ro')
xlabel('Point Number')
ylabel('Angle (degrees)')
legend('Actual', 'Estimate', 'Difference')

