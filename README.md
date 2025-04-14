# Matlab_Abaqus_inp_reader
this function aims to read any 2d truss described by an Abaqus .inp file and solve for global displacements, local displacements, local forces, local stresses, and reaction forces. As of now, it is still a work in progress. This current version only allows for all elements being the same material. Boundary conditions at an angle (ex: slanted rollers) have not been incorporated yet. The text file to be analyzed must follow the disclaimer mentioned in the script, which will be regurgitated here:
%%%%%%%%%%%%%%%%%%%%%%% DISCLAMER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THE INPUT FILE MUST FOLLOW THIS SPECIFIC STRUCTURE IN ORDER TO READ IT
% PROPERLY:
% 01
%   NODES MUST BE THE FIRST SEGMENT
% 02
%   ELEMENTS MUST BE THE SECOND SEGMENT
% 03
%   THE SOLID SECION SEGMENT MUST SPECIFY ITS ELEMENT NUMBER AS THE TWENTY
%   SIXTH AND TWENTY SEVENTH CHARACTER IN THE LINE, THEREFORE THIS SPECIFIC
%   SCRIPT IS LIMITED TO TRUSSES WITH A MAXIMUM OF NINETY NINE ELEMENTS.
%   (this is due to my incredible laziness when writing the code)
% 04
%   THE STEP MUST BE THE LAST SEGMENT INPUT TO THE FILE SUCH THAT THE LAST
%   LINE IN THE TEXT FILE IS "*END STEP"
% 05
%   MATERIAL PROPERTIES CAN BE BE ANYWHERE IN THE DOCUMENT, BUT ITS
%   PROBABLY FOR THE BETTER IF THEY ARE BEFORE THE STEP AND AFTER THE SOLID
%   SECTION SEGMENTS IN ADDITION, ALL ELEMENTS MUST BE OF THE SAME MATERIAL
% 06
%   SIMILAR TO DISCLAIMER POINT 2 EXCUSE, THIS ONLY CONSIDERS BOUNDARY
%   CONDITIONS THAT ONLY ACT IN THE X OR Y DIRECTIONS. TO BE MORE SPECIFIC,
%   THIS CODE WILL NOT PROCESS A ROLLER ON A SLANTED PLANE CORRECTLY
% 07
%   LIKE ABAQUS, ALL REPORTED VALUES ARE UNITLESS, IT IS UP TO THE USER TO
%   IDENTIFY WHAT THOSE UNITS ARE IN THEIR OWN RESPECTIVE SETTING
% 08
%   BOUNDARY CONDITIONS THAT ARE SLANTED HAVENT BEEN IMPLAMENTED YET
