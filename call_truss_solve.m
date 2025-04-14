% test
clear all %#ok<CLALL>
clc
close all

% Process and solve inp file by sending an Abaqus .inp file to the truss_solve function
% As mentioned in disclaimer, 2D truss system only
truss_solve('[your Abaqus .inp file].txt');
