% Labels should be a (number of points x 1) vector
% If r1(i) corresponds to r2(j), then labels(i) = j
function labels = coregister(r1, r2)
    %Naive algorithm: register each point to the point that's closest to it
    %Points far apart in height are very unlikely to be the same
    hPenalty = 5.0;
    rPenalty = 1.0;
    labels = zeros(length(r1), 1);
    for i = 1:length(r1)
        closestDist = 9999;
        closestJ = 0;
        for j = 1:length(r2)
            dist = sqrt(rPenalty*(r1(i, 1) - r2(j, 1)).^2 + ...
                        hPenalty*(r1(i, 2) - r2(j, 2)).^2);
            if dist < closestDist
                closestDist = dist;
                closestJ = j;
            end
        end
        labels(i) = closestJ;
    end
end