function [r1,r2] = dataSim(x1,y1,x2,y2)

% Assumes the surface is at a line (x,0) where x
% ranges from -20 to 20


point = [-800:10:800]

r1 = sqrt((x1-point).^2 + y1.^2);
r2 = sqrt((x2-point).^2 + y2.^2);


d = 100*ones(length(r1));

L = sqrt((x2-x1).^2 + (y2-y1).^2);

figure(1)
clf

plot(r1,d,'bo',r2,d,'g*');
ylim([90 110])


for r = 1:length(r1)
    text(r1(r),d(r)-.1,int2str(r));
    text(r2(r),d(r)+.1,int2str(r));
    labels(r) = r
    
    if(r == 80)
    viscircles([r2(r),d(r)],L,'Color','r');
    end
end

sorted_r1 = sort(r1);
sorted_r2 = sort(r2);

labels_co = coregister3(sorted_r1, sorted_r2, L, .05*L)

% Calculate accuracy
trueCount = 0;
falseCount = 0;
for index = 1:length(labels_co)
    if(labels_co(index) == index)
        trueCount = trueCount + 1;
    else
        falseCount = falseCount + 1;
    end
end

accuracy = trueCount / length(labels_co)

