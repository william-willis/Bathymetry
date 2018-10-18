%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%           SASMapper.m          %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% William Willis, Patrick Terry, Jia Zeng - 2017

function [x_out, y_out, z_out] = SASMapper(Audio1, Audio2, Audio3)
% Input is string filenames for audio files from each of the two receivers
% from a single descent, output is x, y, and z coordinates for a mapped
% region with the origin at the pod location. Without input, runs
% simulation data built in to SAS code. 


thetavals=0:30:360;
ltv=length(thetavals);

%% Sound File Processing
if nargin==3
    Audiodata1 = cell(1,ltv);
    Audiodata2 = cell(1,ltv);
    Audiodata3 = cell(1,ltv);

    % Complete Audio Data
    audiocomplete1 = audioread(Audio1);
    audiocomplete2 = audioread(Audio2);
    audiocomplete3 = audioread(Audio3);
    
    % Angle Partitioning
%     for n=1:ltv
%         Audiodata1n = audiocomplete1;
%         for n=
%         end
%         Au
%     end
end

%% Establish Variables

% First Receiver Data
data1=cell(1,ltv);
% Second Receiver Data
data2=cell(1,ltv);
% Third Receiver Data
data3=cell(1,ltv);
% Angle Data
angles = cell(1,ltv);
% Coordinate data with Angles within Swathe
data=cell(1,ltv);

%% Synthetic Aperture Sonar Processing

% Mapping with Sound File
if nargin==3
    for n=1:ltv
        % Find coordinates of sea floor points for each data swathe
        [data1nr,data1nh]=SAS(Audiodata1{n},n);
        [data2nr,data2nh]=SAS(Audiodata2{n},n);
        [data3nr,data3nh]=SAS(Audiodata3{n},n);
        
        data1{n}=[data1nr data1nh];
        data2{n}=[data2nr data2nh];
        data3{n}=[data3nr data3nh];
        
        % Image correlation + interferometry function
        angles{n}=angleInterferometry(data1{n},data2{n},data3{n},1)
        % Data matrix
        data{n} = [data2{n} angles{n}];
    end
% Mapping with Simulation
else
    for n=1:ltv
        % Generate Random Swathe Data
        run('makeRandomPoints');
        % Find coordinates of sea floor points for each data swathe
        [data1nr,data1nh]=SAS(1);
        [data2nr,data2nh]=SAS(2);
        [data3nr,data3nh]=SAS(3);
        
        data1{n}=[data1nr data1nh];
        data2{n}=[data2nr data2nh];
        data3{n}=[data3nr data3nh];
        
        % Image correlation + interferometry function
        angles{n}=angleInterferometry(data1{n},data2{n},data3{n},1)
        % Data matrix
        data{n} = [data2{n} angles{n}];
    end  
end

%% Map Reconstruction
R = [];
H = [];
A = [];
for n=1:ltv
    data = data{n};
    R = vertcat(R,data(:,1));
    H = vertcat(H,data(:,2));
    A = vertcat(A,data(:,3)+thetavals(n));
end

x_out = R.*cos(A);
y_out = R.*sin(A);

z_out = H;

xlin = linspace(min(x_out),max(x_out),50);
ylin = linspace(min(y_out),max(y_out),50);

[X,Y] = meshgrid(xlin,ylin);
f = scatteredInterpolant(x_out',y_out',z_out');
Z = f(X,Y);
figure(1)
surf(X,Y,Z);
