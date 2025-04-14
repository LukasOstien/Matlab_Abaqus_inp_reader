% test
clear all %#ok<CLALL>
clc
close all

% Call inp file by sending a text file to the truss_solve function
truss_solve('[your Abaqus .inp file].txt');
