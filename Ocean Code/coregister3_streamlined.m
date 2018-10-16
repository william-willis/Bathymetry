% Labels should be a (number of points x 1) vector
% If r1(i) corresponds to r2(j), then labels(i) = j

% Coregistering takes the most probably mapping between all of the radial
% data from each reciever


% Precondition: Need to only consider r positions for all of the r data
% L is the length apart the recievers are
% error is the permitted error
function labels = coregister3_streamlined(r1, r2, L, error)
    % Sort the r values
        r1 = sort(r1)
        r2 = sort(r2)
    % Make same length
        if length(r1) > length(r2)
            for i = 1:length(r2)
                newR1(i) = r1(i);
            end
            r1 = newR1
        else if length(r2) > length(r1)
            for i = 1:length(r1)
                newR2(i) = r2(i);
            end
            r2 = newR2
        end
    % Max difference
        %maxDiff = L + error;
        %minDiff = 0;
    % Go to point in r1
        for i = 1:length(r1)
            labels(i) = i
        end
end