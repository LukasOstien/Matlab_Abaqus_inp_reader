function truss_solve(input_file)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%       Lukas Ostien        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%       M168                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%       Project 1 P4        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% PURPOSE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THIS FUNCTION AIMS TO SOLVE A 2D TRUSS SYSTEM THAT HAS BEEN DEFINED BY AN
% ABAQUS INPUT FILE IN THE FORM OF A TEXT DOCUMENT. IT WILL RETURN MATRICES
% CONTAINING INFORMATION ABOUT NODES, ELEMENTS, MATERIAL PROPERTIES, 
% DEGREES OF FREEDOM, GLOBAL DISPLACEMENTS, LOCAL DISPLACEMENTS, LOCAL 
% FORCES, ELEMENT STRESSES, REACTION FORCES, AND LOCAL & GLOBAL STIFFNESS 
% MATRICES. SOLUTIONS TO THE TRUSS PROBLEM ARE ALSO DISPLAYED ON 
% THE COMMAND WINDOW. RETURNED INFORMATION AS WELL AS SOME DISCLAIMERS CAN
% BE READ BELOW.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THE RETURNED MATRICES CAN BE INTERPRETED WITH THIS STRUCTURE IN MIND:
% 01 NODES
%    * 1ST COLUMN: THE IDENTIFICATION NUMBER OF THE NODE
%    * 2ND COLUMN: THE GLOBAL X POSITION
%    * 3RD COLUMN: THE GLOBAL Y POSITION
%    * 4TH COLUMN: CAN THIS NODE MOVE IN GLBOAL X DIRECTION (1 YES, 0 NO)
%    * 5TH COLUMN: CAN THIS NODE MOVE IN GLBOAL Y DIRECTION (1 YES, 0 NO)
% 02 ELEMENTS
%    * 1ST COLUMN: THE IDENTIFICATION NUMBER OF THE ELEMENT
%    * 2ND COLUMN: THE NODE IDENTIFICATION NUMBER WHERE THE ELEMENT STARTS
%    * 3RD COLUMN: THE NODE IDENTIFICATION NUMBER WHERE THE ELEMENT ENDS
%    * 4TH COLUMN: THE CROSS SECTIONAL AREA OF THE ELEMENT
% 03 PROPERTIES
%    * 1ST COLUMN: ELASTIC MODULUS
%    * 2ND COLUMN: POISSONS RATIO
% 04 DEGREES OF FREEDOM
%    * 1ST COLUMN: THE IDENTIFICATION NUMBER OF THE DEGREE OF FREEDOM
%    * 2ND COLUMN: THE NODE IDENTIFICATION NUMBER WHERE THIS DOF RESIDES
%    * 3RD COLUMN: THE DIRECTION THIS DOF REPRESENTS (1 X, 2 Y)
% 05 LOAD - ROW POSITION REPRESENTS DOF
%    * 1ST COLUMN: USER DEFINED LOADS ON TRUSS
% 06 GLOBAL DISPLACEMENTS - ROW POSITION REPRESENTS DOF
%    * 1ST COLUMN: SOLVED DISPLACEMENTS 
% 07 LOCAL DISPLACEMENTS - ROW POSITION REPRESENTS ELEMENT
%    * 1ST COLUMN: STARTING POINT DISPLACEMENT IN X DIRECTION
%    * 2ND COLUMN: STARTING POINT DISPLACEMENT IN Y DIRECTION
%    * 3RD COLUMN: ENDING POINT DISPLACEMENT IN X DIRECTION
%    * 4TH COLUMN: ENDING POINT DISPLACEMENT IN Y DIRECTION
% 08 LOCAL FORCES - ROW POSITION REPRESENTS ELEMENT
%    * 1ST COLUMN: STARTING POINT FORCE IN X DIRECTION
%    * 2ND COLUMN: STARTING POINT FORCE IN Y DIRECTION
%    * 3RD COLUMN: ENDING POINT FORCE IN X DIRECTION
%    * 4TH COLUMN: ENDING POINT FORCE IN Y DIRECTION
% 09 ELEMENT STRESSES - ROW POSITION REPRESENTS ELEMENT
%    * 1ST COLUMN: SOLVED ELEMENT STRESSES
% 10 REACTION FORCES - ROW POSITION REPRESENTS DOF
%    * 1ST COLUMN: SOLVED REACTION FORCES 
% 11 LOCAL STIFFNESS MATRICES - (:,:,N) MATRIX REPRESENTS ELEMENT
%    * ROW/COLUMN 1 ONLY: CODE NUMBERS
%    * INDICES IN [2:5,2:5]: COMPOMENTS OF STIFFNESS MATRIX
% 12 GLOBAL STIFFNESS MATRIX
%    * ROW/COLUMN 1 ONLY: CODE NUMBERS
%    * INDICES IN [2:2*ALL_DOF,2:2*ALL_DOF]: COMPONENTS OF STIFFNESS MATRIX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% DISCLAMER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% ADDITIONAL COMMENTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THIS CODE WAS TESTED WITH THE PROBLEM 1 IN PROJECT 1 CONSIDERING NODE ONE 
% AS A PIN JOINT AS WELL AS A ROLLER AS WELL AS THE TRUSS INP FILE SHOWN IN
% THE TRUSSES LECTURE IN WEEK 1. IN BOTH INSTANCES, THIS CODE WAS ABLE TO 
% OUTPUT THE SAME GLOBAL/LOCAL DISPLACEMENTS, STRESSES, 
% AND REACTION FORCES AS HAND CALCULATIONS AND ABAQUS.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% END DISCLAIMER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% START FUNCTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Extract Data From Text File into stuff Matlab Can Use
check = input('Ensure text file does not violate disclaimer (1 to proceed, 0 to abort): ');
switch check
    case 1
        clc
        fprintf('Procedure will carry out.\n')
    case 0
        clc
        fprintf('Aborted\n')
        return
end
data = fopen(input_file);
tline = fgetl(data);
NODES = [];
ELEMENTS = [];
while ~strcmp(tline,'*END STEP')
    switch true
        case startsWith(tline,'*NODE')
            % Fill out position information for nodes
            % NODE MATRIX LAYOUT
            % 1st Column: nth node
            % 2nd Column: X position [in]
            % 3rd Column: Y position [in]
            % 4th Column: X DOF Elegibility, 1 - yes, 0 - no (COMPLETED IN
            % BOUNDARY SECTION)
            % 5th Column: Y DOF Elegibility, 1 - yes, 0 - no (COMPLETED IN
            % BOUNDARY SECTION)
            i=1;
            tline = fgetl(data);
            while ~isnan(str2num(strrep(tline,',',' ')))
                NODES(i,:) = str2num(strrep(tline,',',' '))';
                i = i+1;
                tline = fgetl(data);
            end
        case startsWith(tline,'*ELEMENT,')
            % fill out position information for elements
            % ELEMENT MATRIX LAYOUT
            % 1st Column: nth element
            % 2nd Column: start node (where does element start)
            % 3rd Column: end node (where does element end)
            % 4th Column: Cross sectional area [in^2] (completed in SOLID
            % SECTION)
            i=1;
            while startsWith(tline,'*ELEMENT, ')
                tline = fgetl(data);
                ELEMENTS(i,:) = str2num(strrep(tline,',',' '))';
                tline = fgetl(data);
                i = i+1;
            end
            NODES(:,4:5) = 1; % cheap approach to figure out DOF condition
        case startsWith(tline,'*SOLID SECTION')
            % fill out additional information for elements
            while startsWith(tline,'*SOLID SECTION')
                element = str2num(tline(26:27));
                tline = fgetl(data);
                ELEMENTS(element,4) = str2num(tline);
            end
        case startsWith(tline,'*MATERIAL')
            % fill out material information
            % Vector contains modulus of elasticity and poisson's ratio
            tline = fgetl(data);
            tline = fgetl(data);
            properties = str2num(strrep(tline,',',' '))';
        case startsWith(tline,'*BOUNDARY')
            % determine degrees of freedom at each node, if applicible. if
            % there is a boundary condition on either of the x or y dofs,
            % return with a zero. If there is no boundary condition on
            % either of x or y dofs, return 1.
            % direction 1 refers to x, direction 2 refers to y
            tline = fgetl(data);
            bold = 0;
            while isnumeric(str2num(tline(1)))
                node = str2num(tline(1));
                boundary = str2num(tline);
                if boundary(1) == bold
                    tline = fgetl(data);
                    if isempty(str2num(tline))
                        break
                    end
                    node = str2num(tline(1));
                    boundary = str2num(tline);
                end
                if 1 >= boundary(2) && 1 <= boundary(3)
                    NODES(node,4) = 0; NODES(node,5) = 1;
                end
                if 2 >= boundary(2) && 2 <= boundary(3)
                    NODES(node,5) = 0; NODES(node,4) = 1;
                end
                if (1 >= boundary(2) && 1 <= boundary(3)) && ...
                        (2 >= boundary(2) && 2 <= boundary(3))
                    NODES(node,4) = 0; NODES(node,5) = 0;
                end
                bold = boundary(1);
                tline = fgetl(data);
                if isempty(str2num(tline))
                    break
                end
            end
        case startsWith(tline,'*CLOAD')
            % Create DEGREES OF FREEDOM MATRIX
            % Column 1: The degree of freedom
            % Column 2: The reference node
            % Comumn 3: The direction (x or y) - (1 or 2)
            % DOF sweeps through NODES(:,4:5) and checks if each node has
            % DOF elegibility
            % LOAD VECTOR
            % size is number of rows in the DOF Matrix
            % LOAD IS APPLIED TO CORRESPONDING index of DOF
            DOF = [];
            for i = 1:1:size(NODES,1)
                if (NODES(i,4) ==  1)
                    DOF(size(DOF,1)+1,1) = size(DOF,1)+1;
                    DOF(size(DOF,1),2) = i;
                    DOF(size(DOF,1),3) = 1;
                end
                if (NODES(i,5) == 1)
                    DOF(size(DOF,1)+1,1) = size(DOF,1)+1;
                    DOF(size(DOF,1),2) = i;
                    DOF(size(DOF,1),3) = 2;
                end
            end
            LOAD = zeros(size(DOF,1),1);
            tline = fgetl(data);
            while ~isempty(str2num(tline(1)))
                tline = str2num(tline);
                index = tline(1:2);
                for i = 1:1:length(LOAD)
                    if DOF(i,2:3) == index
                        LOAD(i) = tline(3);
                    end
                end
                tline = fgetl(data);
            end
        case startsWith(tline,'*END STEP')
            break
        otherwise
            tline = fgetl(data);
    end
end
pause(1)
fprintf('Abaqus file successfully processed.\n')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Construct Local Stiffness Matrices
% Hello. I probably created too many extra variables to keep track of what
% goes where.
Local = zeros(5,5,size(ELEMENTS,1));
T = zeros(4,4,size(ELEMENTS,1));
ke = zeros(size(ELEMENTS,1),1); le = ke;
for i  = 1:1:size(ELEMENTS,1)
    % calculate each element length
    le(i) = sqrt((NODES(ELEMENTS(i,3),3)-NODES(ELEMENTS(i,2),3))^2+...
        (NODES(ELEMENTS(i,3),2)-NODES(ELEMENTS(i,2),2))^2);
    % calculate the stiffness of each element
    ke(i) = properties(1)*ELEMENTS(i,4)/le(i);
    % calculate c and s values for each element
    c = cosd(atand((NODES(ELEMENTS(i,3),3)-NODES(ELEMENTS(i,2),3))/...
        (NODES(ELEMENTS(i,3),2)-NODES(ELEMENTS(i,2),2))));
    s = sind(atand((NODES(ELEMENTS(i,3),3)-NODES(ELEMENTS(i,2),3))/...
        (NODES(ELEMENTS(i,3),2)-NODES(ELEMENTS(i,2),2))));
    % construct local stiffness matrix
    Local(2:5,2:5,i) = ke(i) * [c^2,c*s,-c^2,-s*c;
        c*s,s^2,-s*c,-s^2;
        -c^2,-s*c,c^2,s*c;
        -s*c,-s^2,s*c,s^2];
    T(:,:,i) = [c -s 0 0;
        s c 0 0;
        0 0 c -s;
        0 0 s c];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This next part is for identifying the degree of freedom the
    % row/column represents. If there is a global degree of freedom, write
    % it. If not, it will stay as zero. This was done in order to refrence
    % any nonzero row/column when creating the global stiffness matrix.
    index = [ELEMENTS(i,2),1]; % - Index is element and DOF for iX
    for j = 1:1:length(LOAD)
        if DOF(j,2:3) == index % If there is a valid index in DOF, assign
            Local(1,2,i) = DOF(j,1);
            break
        else
            Local(1,2,i) = 0;
        end
    end
    Local(2,1,i) = Local(1,2,i); % assign equal and other location same
    % thing.
    % This process is repeated for the remainder DOFS (iY, jX, jY).
    index = [ELEMENTS(i,2),2];
    for j = 1:1:length(LOAD)
        if DOF(j,2:3) == index
            Local(1,3,i) = DOF(j,1);
            break
        else
            Local(1,3,i) = 0;
        end
    end
    Local(3,1,i) = Local(1,3,i);
    index = [ELEMENTS(i,3),1];
    for j = 1:1:length(LOAD)
        if DOF(j,2:3) == index
            Local(1,4,i) = DOF(j,1);
            break
        else
            Local(1,4,i) = 0;
        end
    end
    Local(4,1,i) = Local(1,4,i);
    index = [ELEMENTS(i,3),2];
    for j = 1:1:length(LOAD)
        if DOF(j,2:3) == index
            Local(1,5,i) = DOF(j,1);
            break
        else
            Local(1,5,i) = 0;
        end
    end
    Local(5,1,i) = Local(1,5,i);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Construct Global Stiffness Matrix
GLOBAL = zeros(length(LOAD)+1,length(LOAD)+1);
for i = 1:1:length(LOAD)
    GLOBAL(1,i+1) = DOF(i,1);
end
GLOBAL(:,1) = GLOBAL(1,:)';
% Viewer Discression is advised. But since you're looking anyways, this is
% my approach for identifying when an iX/iY/jX/jY component is nonzero,
% therefore it is a global degree of freedom. It happened to work out after
% writing it, so I do not feel inclined to change it for the remainder of
% this assignment.
for i = 1:1:size(ELEMENTS,1)
    for j = 2:1:5
        for k = 2:1:length(LOAD)+1
            if Local(1,j,i) == GLOBAL(1,k) % if column DOF matches
                for l = 2:1:5
                    for m = 2:1:length(LOAD)+1
                        if Local(l,1,i) == GLOBAL(m,1) % if row DOF matches
                            GLOBAL(m,k) = GLOBAL(m,k) + Local(l,j,i);
                        end
                    end
                end
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Solve For Global/Local Displacements
D = GLOBAL(2:length(LOAD)+1,2:length(LOAD)+1)\LOAD;
d = zeros(size(ELEMENTS,1),4); f = d;
% similar situation for the global stiffness matrix, this is just to put
% each global displancement in the correct local displacement.
for i = 1:1:size(ELEMENTS,1)
    for j = 2:1:5
        for k = 1:1:size(ELEMENTS,1)
            if Local(1,j,i) == k
                d(i,j-1) = D(k);
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Local Forces
for i = 1:1:size(d,1)
    temp = d(i,:)';
    f(i,1:4) = T(:,:,i)*Local(2:5,2:5,i)*temp;
    f(i,5) = sqrt(f(i,1)^2+f(i,2)^2);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Element Stresses
Sigma = f(:,5)./ELEMENTS(:,4);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SETUP TOTAL STIFFNESS MATRIX
% Update a new global stiffness matrix while continuing to write code
% numbers - this was done primarially for debugging purposes. If I were to
% rewrite this, I would keep things consolidated to one global stiffness
% matrix.
GLOBAL_FULL = zeros(2*size(NODES,1)+1,2*size(NODES,1)+1);
GLOBAL_FULL(1:length(LOAD)+1,1:length(LOAD)+1)=GLOBAL(1:length(LOAD)+1,:);
GLOBAL_FULL(:,1) = GLOBAL_FULL(1,:)';
for i = size(NODES,1)+1:1:2*size(NODES,1)
    GLOBAL_FULL(1,i+1) = i;
end
GLOBAL_FULL(:,1) = GLOBAL_FULL(1,:)';
GLOBAL_FULL(2:length(LOAD)+1,2:length(LOAD)+1) = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DEFINE ANY 0 DOFs AND STORE THEM IN DOF AND LOCAL
% Identify nodes that have boundary conditions imposed and assign those
% DOFS (that dont exist) a reference number in DOF matrix. this section
% covers the four total cases that a node can be
for i = 1:1:size(NODES,1)
    if NODES(i,4) == 1 && NODES(i,5) == 0
        trigger = 1;
    elseif NODES(i,4) == 0 && NODES(i,5) == 1
        trigger = 2;
    elseif NODES(i,4) == 1 && NODES(i,5) == 1
        trigger = 3;
    else
        trigger = 0;
    end
    switch trigger
        case 0 % the node has a 0 DOF in X and Y direction
            DOF(size(DOF,1)+1,1) = size(DOF,1)+1;
            DOF(size(DOF,1),2) = i;
            DOF(size(DOF,1),3) = 1;
            DOF(size(DOF,1)+1,1) = size(DOF,1)+1;
            DOF(size(DOF,1),2) = i;
            DOF(size(DOF,1),3) = 2;
        case 1 % the node has a 0 DOF in the Y direction
            DOF(size(DOF,1)+1,1) = size(DOF,1)+1;
            DOF(size(DOF,1),2) = i;
            DOF(size(DOF,1),3) = 2;
        case 2 % the node has a 0 DOF in the X direction
            DOF(size(DOF,1)+1,1) = size(DOF,1)+1;
            DOF(size(DOF,1),2) = i;
            DOF(size(DOF,1),3) = 1;
        case 3 % the node has a 1 DOF in X and Y direction - do nothing
    end
end
% Now that the DOF matrix is updated, update the local stiffness matrices
% such that code numbers are represented properly
% Go through each row and increment by two spaces each time, revealing 3
% possible cases:
% 1: the current element is zero and the element in front is nonzero
% 2: the current element is nonzero and the element in front is zero
% 3: both the current and front element is zero
for i = 1:1:size(ELEMENTS,1)
    for j = 2:2:4
        if Local(1,j,i) > 0 && Local(1,j+1,i) == 0
            Local(1,j+1,i) = DOF(DOF(:,2)==Local(1,j,i) & DOF(:,3)==2,1);
        elseif Local(1,j,i) == 0 && Local(1,j+1,i) > 0
            Local(1,j,i) = DOF(DOF(:,2)==Local(1,j+1,i) & DOF(:,3)==1,1);
        elseif Local(1,j,i) == 0 && Local(1,j+1,i) == 0
            if j == 2
                Local(1,j,i) = DOF(DOF(:,2)==ELEMENTS(i,2)&DOF(:,3)==1,1);
                Local(1,j+1,i) =DOF(DOF(:,2)==ELEMENTS(i,2)&DOF(:,3)==2,1);
            else
                Local(1,j,i) = DOF(DOF(:,2)==ELEMENTS(i,3)&DOF(:,3)==1,1);
                Local(1,j+1,i) =DOF(DOF(:,2)==ELEMENTS(i,3)&DOF(:,3)==2,1);
            end
        end
    end
    Local(:,1,i) = Local(1,:,i)';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ASSEMBLE TOTAL GLOBAL STIFFNESS MATRIX
% Put together the rest of the global matrix
% Unlike the first time the stiffness matrix was created, things need to be
% in terms of the number of nodes.
for i = 1:1:size(ELEMENTS,1)
    for j = 2:1:5
        for k = 2:1:2*size(NODES,1)+1
            if Local(1,j,i) == GLOBAL_FULL(1,k)
                for l = 2:1:5
                    for m = 2:1:2*size(NODES,1)+1
                        if Local(l,1,i) == GLOBAL_FULL(m,1)
                            GLOBAL_FULL(m,k)=GLOBAL_FULL(m,k)+Local(l,j,i);
                        end
                    end
                end
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONSTRUCT TOTAL DISPLACEMENT VECTOR
D_FULL = zeros(size(NODES,1)*2,1);
D_FULL(1:length(LOAD)) = D;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CALCULATE ALL REACTION FORCES
R_FULL = GLOBAL_FULL(2:size(GLOBAL_FULL,1),2:size(GLOBAL_FULL,1))*D_FULL;
pause(1)
fprintf('System successfully analyzed. Displaying results:\n')
pause(1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PRINT RESULTS
fprintf('------------------------------------------------------------------------\n');
fprintf('RESULTS:\n')
fprintf('========================================================================\n');
fprintf('========================================================================\n');
fprintf('Global Displacements:\n');
fprintf('------------------------------------------------------------------------\n');
fprintf('Node        Displacement     Direction\n')
for i = 1:1:length(D)
    fprintf('%d          ',DOF(i,2))
    fprintf('%.3f           ',D(i))
    if DOF(i,3) == 1
        fprintf('X\n')
    else
        fprintf('Y\n')
    end
end
fprintf('========================================================================\n');
fprintf('========================================================================\n');
fprintf('Local Displacements:\n');
fprintf('------------------------------------------------------------------------\n');
fprintf('Element    iX              iY               jX                jY\n')
for i = 1:1:size(d,1)
    fprintf('%d        ',i)
    fprintf('%.3e       ',d(i,1))
    fprintf('%.3e       ',d(i,2))
    fprintf('%.3e      ',d(i,3))
    fprintf('%.3e       \n',d(i,4))
end
fprintf('========================================================================\n');
fprintf('========================================================================\n');
fprintf('Local Forces:\n');
fprintf('------------------------------------------------------------------------\n');
fprintf('Element    fiX             fiY             fjX               fjY\n')
for i = 1:1:size(f,1)
    fprintf('%d        ',i)
    fprintf('%.3e       ',f(i,1))
    fprintf('%.3e       ',f(i,2))
    fprintf('%.3e      ',f(i,3))
    fprintf('%.3e       \n',f(i,4))
end
fprintf('========================================================================\n');
fprintf('========================================================================\n');
fprintf('Element Stresses:\n');
fprintf('------------------------------------------------------------------------\n');
fprintf('Element    Stress\n')
for i = 1:1:length(Sigma)
    fprintf('%d        ',i)
    fprintf('%.4e      \n',Sigma(i))
end
fprintf('========================================================================\n');
fprintf('========================================================================\n');
fprintf('Reaction Forces:\n');
fprintf('------------------------------------------------------------------------\n');
fprintf('Node    Reaction Force    Direction\n')
for i = length(LOAD)+1:1:length(R_FULL)
    fprintf('%d        ',DOF(i,2))
    fprintf('%.4e           ',R_FULL(i))
    if DOF(i,3) == 1
        fprintf('X\n')
    else
        fprintf('Y\n')
    end
end
fprintf('========================================================================\n');
fprintf('========================================================================\n');
fprintf('------------------------------------------------------------------------\n');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% RETURN USEFUL INFORMATION
assignin('base','Nodes',NODES);
assignin('base','Elements',ELEMENTS);
assignin('base','Properties',properties);
assignin('base','Degrees_of_Freedom',DOF);
assignin('base','Load',LOAD);
assignin('base','Global_Displacements',D);
assignin('base','Local_Displacements',d);
assignin('base','Local_Forces',f);
assignin('base','Element_Stresses',Sigma);
assignin('base','Reaction_Forces',R_FULL);
assignin('base','Local_Stiffness_Matrices',Local);
assignin('base','Global_Stiffness_Matrix',GLOBAL_FULL);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pause(1)
fprintf('Process completed successfully.\n');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END FUNCTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%