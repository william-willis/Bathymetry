% Labels should be a (number of points x 1) vector
% If r1(i) corresponds to r2(j), then labels(i) = j

% Coregistering takes the most probably mapping between all of the radial
% data from each reciever


% Precondition: Need to only consider r positions for all of the r data
% L is the length apart the recievers are
% error is the permitted error
% Assuming that Matlab functions are passed by values
function labels = coregister3(r1, r2, L, error)
    % Sort the r values
        r1 = sort(r1)
        r2 = sort(r2)
        
        
    % Max difference
        maxDiff = L + error;
        minDiff = 0;
    % Go to point in r1
        for i = 1:length(r1)
            possibleParings = []
            for j = 1:length(r2)
                minVal = r1(i) - maxDiff;
                maxVal = r1(i) + maxDiff;
                if(r2(j) ~= Inf) 
                    if (r2(j) >= minVal)
                        if(r2(j) <= maxVal)
                            %Add to list
                            possibleParings = [possibleParings j]
                        else
                            break;
                        end
                    end
                end
            end
            
            % Run the Guess Code
            if(length(possibleParings) > 0)
                possDistances = r2(possibleParings) - r1(i)
                possDistances = sort(possDistances)
                
                labels(i) = possibleParings(1)
                r2(possibleParings(1)) = Inf
            end
        end
        
        
        % Find points that are within the min and max error range
        % Guess which point pairs up
            % Compare to r value of previous points
                % diff (theta) vs. r
            % Distribution of theta points previously made
end