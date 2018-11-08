
% Fourier synthesis to make a time series from the transfer function
% mbp 9/96
% Updated 2014 to be compatible with the current file formats

% Need to set
%   Tstart = starting time
%   specfile (file containing spectrum)
%   root of field files
%   N = size of transform

clear all

Tstart   = 32.0;
shdfile  = 'MunkS';
c = 1520.0;  % reduction velocity (should exceed fastest possible arrival)

%%
% load source spectrum

%fid   = fopen( specfile );
%temp  = fscanf( fid, '%f', [ 3, inf ] );
%shat  = temp( 2, : ) + 1i * temp( 3, : );

% 'temporary force of a unit spectrum'
% shat  = ones( length( freq ), 1 );
% Nfreq = length( shat );

% generated by 'cans'
Tmax = 10;   % should be as long as the impulse response we want to see so that frequency sampling is adequate
sample_rate = 200;   % samples per second
delta_t     = 1 / sample_rate;
t_sts       = 0.0 : delta_t : Tmax - delta_t;
Nsamples    = length( t_sts );

omega       = 2 * pi * 10;
Pulse       = 'P';
[ sts, PulseTitle ] = cans( t_sts, omega, Pulse );

% source spectrum
s_hat = fft( sts );

delta_f_sts = 1 / Tmax;
f_max_sts   = 1 / delta_t;
s_freq = linspace( 0.0, f_max_sts - delta_f_sts, length( s_hat ) )';

% zero out the negative part of the spectrum
s_hat( Nsamples / 2 : end ) = 0.0;

% figure
% plot( t_sts( 1 : 100 ), sts( 1 : 100 ) )
% xlabel( 'Time (s)' )
% ylabel( 's(t)' )
% 
% figure
% plot( s_freq, abs( s_hat ) )
% xlabel( 'Frequency (Hz)' )
% ylabel( 's(f)' )


%%
% Main loop

nsd = 1;

for isd = 1 : nsd
   
   % read in the model transfer function
   
   clear rmodhat
   
   % dummy read to get the freq vector from the shdfil
   filename = [ shdfile '.shd.mat' ];
   [ PlotTitle, PlotType, freqVec, atten, Pos, pressure ] = read_shd( filename, 0.0 );
   Nfreq = length( freqVec );
   
   for ifreq = 1 : Nfreq
      % read the shdfile
      freq = freqVec( ifreq );
      [ PlotTitle, PlotType, ~, atten, Pos, pressure ] = read_shd( filename, freq );
      
      nrd = length( Pos.r.depth );
      nrr = length( Pos.r.range );
      
      if ( ifreq == 1 )   % allocate space
         rmodhat = zeros( Nfreq, nrd, nrr );
         %rmodhat = ones( Nfreq, nrd, nrr );
      end
      
      rmodhat( ifreq, 1 : nrd, 1 : nrr ) = squeeze( pressure );
   end   % next frequency
   
   %%
   % compute the received time series
   
   % remove the start time delay
   
   for ir = 1 : nrr
      for ird = 1 :nrd
         rmodhat( :, ird, ir ) = rmodhat( :, ird, ir ) .* exp( 1i * 2 * pi * Tstart * freqVec );
      end
   end
   
   % weight transfer function by source spectrum
   
   for ifreq = 1 : Nfreq
      rmodhat( ifreq, :, : ) = rmodhat( ifreq, :, : ) * interp1( s_freq, s_hat, freqVec( ifreq ) );
   end
   
   rmod = ifft( rmodhat, Nfreq );   % inverse FFT to compute received time-series
   
   % set up time vector based on usual FFT sampling rules
   
   deltaf = freqVec( 2 ) - freqVec( 1 );
   Tmax   = 1 / deltaf;
   deltat = Tmax / Nfreq;
   time   = linspace( 0.0, Tmax - deltat, Nfreq );
   
   %%
   % heterodyne with the base frequency
   % Be careful that rmod has adequate time-sampling ...
   
   %    for ir = 1 : nrr
   %       for ird = 1 : nrd
   %          rmod( :, ird, ir ) = rmod( :, ird, ir ) .* exp( -1i * 2 * pi * time' * freqVec( 1 ) );
   %       end
   %    end
   %
   % spectrum is conjugate symmetric so:
   rmod = 2 * real( rmod );
   %%
   % plot snapshots
   %
   %    figure
   %    for it = 1 : Nfreq
   %       TL = 20 * log10( abs( squeeze( rmod( it, :, : ) ) ) );
   %       imagesc( Pos.r.range / 1000, Pos.r.depth, TL )
   %       colormap( jet )
   %       xlabel( 'Range (km)' )
   %       ylabel( 'Depth (m)' )
   %       maxTL = max( max( TL ) );
   %       minTL = maxTL - 40;
   %       caxis( [ minTL, maxTL ] )
   %       colorbar
   %       drawnow
   %    end
   
   %%
   % save a time series file
   
   irr = 5;
   
   RTS = squeeze( rmod( :, 11 : 20 : 201, irr ) );	% can only plot 2D matrix
 
   % calculate time vector that goes with that range
   % tstart = Pos.r.range( irr ) / c - 0.1;   % min( delay( ir, :, ird ) )
   % tend   = tstart + T - deltat;
   % tout   = tstart : deltat : tend;
   
   rd_temp     = Pos.r.depth;
   Pos.r.depth = rd_temp( 11 : 20 : 201 );
   tout        = time;
   
   save( [ shdfile '.rts.mat' ], 'PlotTitle', 'Pos', 'tout', 'RTS' )
   
   Pos.r.depth = rd_temp;   % restore
   
   %%
   rmod_env = abs( hilbert( squeeze( rmod( :, :, irr ) ) ) );
   peak = max( max( rmod_env ) );
   
   figure
   imagesc( time, Pos.r.depth, rmod_env' )
   %caxis( [ -peak/5, peak/5 ] )
   colorbar
   colormap( jet )
   xlabel( 'Time (s)' )
   ylabel( 'Depth (m)' )
   title( PlotTitle )
   
   % calculate the envelope
   
   % normalize
   % clipped log-envelope
   %for ir = 1:nrr
   %  temp = 20 * log10( rmod_env( :, ir ) / max( rmod_env( :, ir ) ) ) + 30;
   %  I = find( temp < 0 );
   %  temp( I ) = zeros( size( I ) );
   %  rmod_env( :, ir ) = temp / norm( temp );
   %end
   %rmod_env = rmod_env';
   
   % save for future use ...
   
end   % next source depth