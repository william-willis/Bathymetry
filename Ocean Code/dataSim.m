function [r1,r2] = dataSim(x1,y1,x2,y2)

% Assumes the surface is at a line (x,0) where x
% ranges from -20 to 20


point = [-800:10:800]

r1 = sqrt((x1-point).^2 + y1.^2);
r2 = sqrt((x2-point).^2 + y2.^2);

diff = r2-r1

d = 100*ones(length(r1));

L = abs(x2-x1);

figure(1)
clf

% plot(r1,d,'bo',r2,d,'g*');
plot(r1,d,'bo');
ylim([90 110])

for r = 1:length(r1)
    %text(r1(r),d(r)-.1,int2str(r));
    text(r2(r),d(r)+.1,int2str(r));
    if(r == 80)
    viscircles([r2(r),d(r)],L,'Color','r');
    end
end


