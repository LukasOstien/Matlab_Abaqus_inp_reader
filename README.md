# Matlab_Abaqus_inp_reader
this function aims to read any 2d truss described by an Abaqus .inp file and solve for global displacements, local displacements, local forces, local stresses, and reaction forces. As of now, it is still a work in progress. This current version only allows for all elements being the same material. Boundary conditions at an angle (ex: slanted rollers) have not been incorporated yet. The text file to be analyzed must follow the disclaimer mentioned in the script, which will be regurgitated here: <br />
THE INPUT FILE MUST FOLLOW THIS SPECIFIC STRUCTURE IN ORDER TO READ IT PROPERLY: <br />
% 01  <br />
%   NODES MUST BE THE FIRST SEGMENT  <br />
% 02  <br />
%   ELEMENTS MUST BE THE SECOND SEGMENT  <br />
% 03  <br />
%   THE SOLID SECION SEGMENT MUST SPECIFY ITS ELEMENT NUMBER AS THE TWENTY  <br />
%   SIXTH AND TWENTY SEVENTH CHARACTER IN THE LINE, THEREFORE THIS SPECIFIC  <br />
%   SCRIPT IS LIMITED TO TRUSSES WITH A MAXIMUM OF NINETY NINE ELEMENTS.  <br />
%   (this is due to my incredible laziness when writing the code)  <br />
% 04  <br />
%   THE STEP MUST BE THE LAST SEGMENT INPUT TO THE FILE SUCH THAT THE LAST  <br />
%   LINE IN THE TEXT FILE IS "*END STEP"  <br />
% 05  <br />
%   MATERIAL PROPERTIES CAN BE BE ANYWHERE IN THE DOCUMENT, BUT ITS  <br />
%   PROBABLY FOR THE BETTER IF THEY ARE BEFORE THE STEP AND AFTER THE SOLID  <br />
%   SECTION SEGMENTS IN ADDITION, ALL ELEMENTS MUST BE OF THE SAME MATERIAL  <br />
% 06  <br />
%   SIMILAR TO DISCLAIMER POINT 2 EXCUSE, THIS ONLY CONSIDERS BOUNDARY  <br />
%   CONDITIONS THAT ONLY ACT IN THE X OR Y DIRECTIONS. TO BE MORE SPECIFIC,  <br />
%   THIS CODE WILL NOT PROCESS A ROLLER ON A SLANTED PLANE CORRECTLY  <br />
% 07
%   LIKE ABAQUS, ALL REPORTED VALUES ARE UNITLESS, IT IS UP TO THE USER TO  <br />
%   IDENTIFY WHAT THOSE UNITS ARE IN THEIR OWN RESPECTIVE SETTING  <br />
% 08  <br />
%   BOUNDARY CONDITIONS THAT ARE SLANTED HAVENT BEEN IMPLAMENTED YET  <br />
