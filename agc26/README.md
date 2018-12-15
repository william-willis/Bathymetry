# Ocean_EGR
*Code for Duke Ocean Engineering
*This is code either straight from the Acoustic Toolbox ( http://oalib.hlsresearch.com/Rays/index.html ), 
*from Dinesh Palanisamy and his initial work on the 2D and 3D neural networks, or from myself in modifying
*and creating new scripts to operate the neural network and train the data.
*The important code is generate_noisy_data.m which will generate audio data from .env and .bty's. These are what populate the NN training and test data.
*Please keep in mind you current folder in MATLAB must be Bathymetry/agc26/at/Bellhop , with the rest of at/ added to your current path, in order to generate training data.
*delayandsum.m is likely the biggest issue in generating test data, and should be immediately fixed.
