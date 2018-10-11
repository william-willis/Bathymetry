function [r1,r2] = dataSim(x1,y1,x2,y2)

% Assumes the surface is at a line (x,0) where x
% ranges from -20 to 20


point = [-200:10:200]

r1 = sqrt((x1-point).^2 + y1.^2);
r2 = sqrt((x2-point).^2 + y2.^2);

diff = r2-r1

d = ones(length(r1));


figure(1)
clf

plot(r1,d,'bo',r2,d,'g*');


