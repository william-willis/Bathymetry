%% TestAngleCalculation.m
% Tests calculateAngle.m
rec1 = [0, 5];
rec2 = [0, 6];
point = [7, 0];
eDist = @(a, b) sqrt(sum((a-b).^2));
B = eDist(rec1, rec2);
r1 = eDist(rec1, point);
r2 = eDist(rec2, point);

theta = calculateAngle(r1, r2, B)

figure(1)
clf
plot(rec1(1), rec1(2), 'ko')
hold on
plot(rec2(1), rec2(2), 'bo')
plot(point(1), point(2), 'ro')
axis equal