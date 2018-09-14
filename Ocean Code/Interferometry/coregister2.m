% Labels should be a (number of points x 1) vector
% If r1(i) corresponds to r2(j), then labels(i) = j
function labels = coregister2(r1, r2, minAngle, maxAngle, B)
    %Convert to [0, 360) range
    minAngle = mod(minAngle, 360);
    maxAngle = mod(maxAngle, 360);
    %r2 - r1 is roughly equal to cos(angle)*B. 
    %Find the range of values for r2 - r1
    if minAngle < 180 && maxAngle <= 180
        minDiff = cosd(maxAngle)*B;
        maxDiff = cosd(minAngle)*B;
    elseif minAngle < 180
        minDiff = -1;
        maxDiff = max(cosd(minAngle)*B, cosd(maxAngle)*B);
    else
        minDiff = cosd(maxAngle)*B;
        maxDiff = cosd(minAngle)*B;
    end
    %Smarter algorithm than coregister.m:
    %For each point in r1, can I find one or more point within a reasonable
    %range in terms of height and r2-r1, given what I know about the angle
    %range? If so, choose the closest one. If not, choose 0 because any
    %other point is garbage anyway so we might as well just pick an angle
    %in the middle of the range later.
    labels = zeros(length(r1), 1);
    hWiggle = 1.0; %Allow points up to hWiggle off along h axis
    rWiggle = 0.0; %Allow points up to rWiggle out of range along r axis
    allIndicesR1 = 1:length(r1);
    allIndicesR2 = 1:length(r2);
    for i = allIndicesR1
        h = r1(i, 2);
        r2Min = r1(i, 1) + minDiff - rWiggle;
        r2Max = r1(i, 1) + maxDiff + rWiggle;
        %Logical mask with value 1 if the point is within the proper range
        isValidPoint = r2(:, 1) >= r2Min & ...
                       r2(:, 1) <= r2Max & ...
                       r2(:, 2) >= h - hWiggle & ...
                       r2(:, 2) <= h + hWiggle;       
        validIndices = allIndicesR2(isValidPoint);
        if isempty(validIndices)
            %print(i)
            %r1(i, :)
            %r2(i, :)
        else
            %Find the closest valid point
            hPenalty = 5.0;
            rPenalty = 1.0;
            weightedDist = @(x, y) sqrt(rPenalty*(x(1) - y(1)).^2 + hPenalty*(x(2) - y(2)).^2);
            validPoints = r2(validIndices, :);
            validPointsSize = size(validPoints);
            numValidPoints = validPointsSize(1);
            dists = zeros(numValidPoints, 1);
            for j = 1:numValidPoints
                dists(j) = weightedDist(r1(i, :), validPoints(j, :));
            end
            bestPoint = validIndices(dists == min(dists));
            labels(i) = bestPoint(1);
        end
    end
end