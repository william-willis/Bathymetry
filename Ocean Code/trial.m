clc;
close all;
clear all;
f=3000;%frequency of the transmitted pulse
fs=16000;%sampling frequency
N=10000;%number of samples required in the pulse
theta = 70; %Angle of target
d = 0.20;   %spacing between sensors
M = 1;    %No of sensors
c=1500;%velocity of sound in water
target_range=300;%range of the target is .3km
max_range=1500;
max_delay=2*max_range/c;
max_delay_samples=max_delay*fs;
x=0.02*randn(1,max_delay_samples);%random noise signal with 10000 samples
%%
t=[0:N-1]/fs;
y=sin(2*pi*f*t);%pulse signal
l=2*fs*target_range/c;
x(l:l+N-1)=y;%inserting the pulse signal to the random noise at the corresponding sample locations
figure
plot(x)
%% inverse beamformer
del = [0:M-1]*d*cosd(theta)/c;
inputSignal=delayseq(x',del,fs);
%% Beamformer
C=0;
Phi = 0:180;
cnt=0;
T=0;
d = 0;
for i =1:length(Phi)
    cnt=cnt+1;
    del(cnt,:) = -[0:M-1]*d*cosd(Phi(i))/c;
      outputSensorSignal = delayseq(inputSignal,del(cnt,:),fs);
      outputSignal(i,:) = sum(outputSensorSignal');
      outputPower(i) = var(outputSignal(i,:));
      [xc,lags] = xcorr(outputSignal(i,:),y);
      [value,I] = max(abs(xc));
      L=lags(I);
      range(i)=(c*L)/(2*fs);
end
[O,K]=max(outputPower);
[xc,lags] = xcorr(outputSignal(K,:),y);
[value,I] = max(abs(xc));
L=lags(I);
Range=(c*L)/(2*fs)
figure
plot(lags,xc)
legend(sprintf('Maximum at lag %d',L))
title('Cross-Correlation Sequence')
figure
plot(Phi,outputPower)
title('beamformer')