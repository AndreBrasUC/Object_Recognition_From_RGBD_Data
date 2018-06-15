function [X, Z] = FuncToIntersectPlanes (P1, P2, Y)

%   FUNCTOINTERSECTPLANES intersects two vertical planes and returns the X
%   and Y coordinates of the intersection line, at a specific height

%%	Inputs

%   P1      Plane to intersect with P2
%   P2      Plane to intersect with P1
%   Z       Specific height at which the intersection is computed

%%	Outputs

%   X       X coordinate of the intersection line, at a specific height
%   Y       Y coordinate of the intersection line, at a specific height

%%  Planes Intersection

P1Parameters = P1.Parameters;
P2Parameters = P2.Parameters;

A1 = P1Parameters (1);  A2 = P2Parameters (1);
B1 = P1Parameters (2);  B2 = P2Parameters (2);
C1 = P1Parameters (3);  C2 = P2Parameters (3);
D1 = P1Parameters (4);  D2 = P2Parameters (4);

% It only remains to solve the problem M * x = b
M = [A1, C1; A2, C2];
b = [(- B1 * Y - D1); (- B2 * Y - D2)];
x = M \ b;

X = x (1);
Z = x (2);