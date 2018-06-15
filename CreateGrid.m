function [Grid, varargout] = CreateGrid (Cloud, Divisions, Mode)

%   CREATEGRID creates a grid according to the number of divisions of each
%   axis and counts the number of points in each cell of this grid

%%	Inputs

%   Cloud       Input point cloud
%   Divisions   Number of divisions each axis is split
%   Mode        'Height' to count points in vertical columns and 'Depth' to
%               count the points in columns with the depth direction.

%%	Outputs

%   Grid        Output cell of size 2. The first cell is an array with the
%               number of points in each cell of the grid. The second cell
%               is an array of cells, each one listing the indexes of all
%               points included by the corresponding cell of the grid

%   varargout
%   GridLimits  Struct with the values that define the limits of each cell
%               of the grid along each axis
%   GridSize    Size of each cell along each axis
%   MidPoints   Struct with the midpoint value of each cell along each axis

%%  Input Parsing

if (strcmpi (Mode, 'Height') || strcmpi (Mode, 'Depth')) && ...
        numel (Divisions) ~= 2
    info = strcat ('''Heigth'' and ''Depth'' modes of creating a grid', ...
        ' only allow bidimensional division. So the input Divisions', ...
        ' shoud be a bidimensional array with two values.');
    error (info);
end

%%  Preallocation of Variables

Limits = [Cloud.XLimits; Cloud.YLimits; Cloud.ZLimits];

GridHeight = cell (1, 2);
GridHeight {1, 1} = zeros (Divisions (1), Divisions (2));
GridHeight {1, 2} = cell (Divisions (1), Divisions (2));
GridDepth = cell (1, 2);
GridDepth {1, 1} = zeros (Divisions (1), Divisions (2));
GridDepth {1, 2} = cell (Divisions (1), Divisions (2));

%%  Grid Creation

% Define the size of each cell along each axis
SizeHeight = [(Limits(1, 2) - Limits(1, 1)) / Divisions(1), ...
    (Limits(2, 2) - Limits(2, 1)) / Divisions(2)];
SizeDepth = [(Limits(1, 2) - Limits(1, 1)) / Divisions(1), ...
	(Limits(3, 2) - Limits(3, 1)) / Divisions(2)];

% Define the limits of each cell of the grid along each axis
LimitsHeight = struct ();
LimitsHeight.X = Limits (1, 1) + (0 : Divisions (1)) * SizeHeight (1);
LimitsHeight.Y = Limits (2, 1) + (0 : Divisions (2)) * SizeHeight (2);
LimitsDepth = struct ();
LimitsDepth.X = Limits (1, 1) + (0 : Divisions (1)) * SizeDepth (1);
LimitsDepth.Z = Limits (3, 1) + (0 : Divisions (2)) * SizeDepth (2);

% Define the midpoint of each cell
MidHeight = struct ();
MidHeight.X = (LimitsHeight.X (2 : Divisions (1) + 1) + ...
    LimitsHeight.X (1 : Divisions (1))) / 2;
MidHeight.Y = (LimitsHeight.Y (2 : Divisions (2) + 1) + ...
    LimitsHeight.Y (1 : Divisions (2))) / 2;
MidDepth = struct ();
MidDepth.X = (LimitsDepth.X (2 : Divisions (1) + 1) + ...
    LimitsDepth.X (1 : Divisions (1))) / 2;
MidDepth.Z = (LimitsDepth.Z (2 : Divisions (2) + 1) + ...
    LimitsDepth.Z (1 : Divisions (2))) / 2;

%%  Counting of the Points in Each Cell

for i = 1 : Divisions (1)
    for j = 1 : Divisions (2)
        UsefulPoints = findPointsInROI (Cloud, ...
            [(Limits(1, 1) + SizeHeight(1) * (i - 1)), ...
            (Limits(1, 1) + SizeHeight(1) * (i)); ...
            (Limits(2, 1) + SizeHeight(2) * (j - 1)), ...
            (Limits(2, 1) + SizeHeight(2) * (j)); -inf, inf]);
        GridHeight {1, 1} (i, j) = numel (UsefulPoints);
        GridHeight {1, 2} {i, j} = UsefulPoints;

        UsefulPoints = findPointsInROI (Cloud, ...
            [(Limits(1, 1) + SizeDepth(1) * (i - 1)), ...
            (Limits(1, 1) + SizeDepth(1) * (i)); -inf, inf; ...
            (Limits(3, 1) + SizeDepth(2) * (j - 1)), ...
            (Limits(3, 1) + SizeDepth(2) * (j))]);
        GridDepth {1, 1} (i, j) = numel (UsefulPoints);
        GridDepth {1, 2} {i, j} = UsefulPoints;
    end
end

%%  Output Parsing

if strcmpi (Mode, 'Height'), Grid = GridHeight;
elseif strcmpi (Mode, 'Depth'), Grid = GridDepth; end
if nargout >= 2
    if strcmpi (Mode, 'Height'), varargout {1} = LimitsHeight;
    elseif strcmpi (Mode, 'Depth'), varargout {1} = LimitsDepth; end
end
if nargout >= 3
    if strcmpi (Mode, 'Height'), varargout {2} = SizeHeight;
    elseif strcmpi (Mode, 'Depth'), varargout {2} = SizeDepth; end
end
if nargout == 4
    if strcmpi (Mode, 'Height'), varargout {3} = MidHeight;
    elseif strcmpi (Mode, 'Depth'), varargout {3} = MidDepth; end
elseif nargout > 4
    error (message ('MATLAB:nargoutchk:tooManyOutputs'));
end

end