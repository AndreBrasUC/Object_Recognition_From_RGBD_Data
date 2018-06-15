function Clusters = FindROIs (Cloud, varargin)

%   FINDROIS segments regions of interest from point clouds. This function
%   returns clusters of points joined by the analysis of density

%%	Inputs

%   Cloud       Input point cloud

%   varargin
%   Type        To check the points density, it is created a grid which is
%               split in small cells. The input should be 'Divisions' or
%               'Dimensions'
%   Values      If Type is 'Divisions', 'Values' should be an array with
%               the number of cells each axis is split. Otherwise, the
%               array should include the size of cells along each axis
%   Mode        'Height' to count points in vertical columns and 'Depth' to
%               count the points in columns with the depth direction.
%   MinPoints   Minimum number of point that a cluster should include to be
%               considered as a significant cluster

%%	Outputs

%   Clusters	Output cell with the clusters

%%  Input Parsing

VarArgInCheck = [0 0 0 0];
if nargin > 1
    for i = 1 : 2 : length (varargin)
        switch char (varargin {i})
            case 'Type'
                Type = varargin {i + 1};
                VarArgInCheck (1) = 1;
            case 'Values'
                Values = varargin {i + 1};
                VarArgInCheck (2) = 1;
            case 'Mode'
                Mode = varargin {i + 1};
                VarArgInCheck (3) = 1;
            case 'MinPoints'
                MinPoints = varargin {i + 1};
                VarArgInCheck (4) = 1;
        end
    end
end

% Set standard values for missing input arguments
if VarArgInCheck (1) == 0, Type = 'Divisions'; end
if VarArgInCheck (2) == 0, Type = 'Divisions'; Values = [40 40]; end
if VarArgInCheck (3) == 0, Mode = 'Height'; end
if VarArgInCheck (4) == 0, MinPoints = 500; end

if strcmpi (Type, 'Divisions')
    Divisions = Values;
elseif strcmpi (Type, 'Dimensions')
    Dimensions = Values;
    Limits = [Cloud.XLimits; Cloud.YLimits; Cloud.ZLimits];
    Size (1 : 3, 1) = Limits (1 : 3, 2) - Limits (1 : 3, 1);
    Divisions (1) = ceil (Size (1) / Dimensions (1));
    Divisions (2) = ceil (Size (2) / Dimensions (2));
end

%%	Point Clustering

% Create a grid and count the number of point in each cell. The function
% called here also returns the indices of points between each cell
Grid = CreateGrid (Cloud, Divisions, Mode);
GridCounts = Grid {1};
GridIndices = Grid {2};
% Use the count in each cell to cluster groups of points
ObjectsIndices = zeros (size (GridCounts));
Iterate = 1;
while Iterate == 1
    Iterate = 0;
    Count = 1;
    for i = 1 : Divisions (1)
        for j = 1 : Divisions (2)
            if GridCounts (i, j) ~= 0
                % Save the original object attached to the cell
                OldIndice = ObjectsIndices (i, j);
                % Define the neighbourhood that will be parsed
                L = max ([(j - 1), 1]);
                R = min ([(j + 1), Divisions(2)]);
                T = max ([(i - 1), 1]);
                B = min ([(i + 1), Divisions(1)]);
                % Verify if neighbour cells already have a group attached
                Groups = unique (ObjectsIndices (T : B, L : R));
                if numel (Groups) > 1
                    % When the neighbour cells have different indices, it
                    % possibly means that the same object is marked as
                    % being multiple objects. So, the cell being analysed
                    % is set with the lowest value in the neighbourhood)
                    ObjectsIndices (i, j) = min (Groups (Groups > 0));
                else
                    if Groups > 0
                        ObjectsIndices (i, j) = Groups;
                    else
                        ObjectsIndices (i, j) = Count;
                        Count = Count + 1;
                    end
                end
                % Case the object attached to the cell is different from
                % the original, it is necessary iterate once again
                if ObjectsIndices (i, j) ~= OldIndice, Iterate = 1; end
            end
        end
    end
end

% Get the unique values in indices grid and the total number of clusters.
% Then, change the values, making them consecutive integers
Values = unique (ObjectsIndices (:));
Values = Values (Values > 0);
TotalClusters = numel (Values);
for i = 1 : TotalClusters
    ObjectsIndices (ObjectsIndices == Values (i)) = i;
end

%%  Cluster Processing

% Find significant clusters checking the number of points they include and
% their relation between number of points and number of cells populated
Clusters = {};
SignificantClusters = 0;
for Cluster = 1 : TotalClusters
    % Look for cells where the points of a cluster are included and select
    % the corresponding indices
    ObjectCells = (ObjectsIndices == Cluster);
    ObjectIndices = GridIndices (ObjectCells);
    % Count the number of cells populated by a cluster. Then, concatenate
    % all corresponding indices to count the number of points included
    PopulatedCells = size (ObjectIndices, 1);
    SetIndices = [];
    for Cell = 1 : PopulatedCells
        SetIndices = [SetIndices; (ObjectIndices {Cell, 1})];
    end
    TotalPoints = size (SetIndices, 1);
    % Save a cluster if the number of points included is greater than the
    % number of populated cells by at least one order of magnitude and the
    % number of points is simultaneously greater than a minimum value
    if floor (log10 (TotalPoints)) > floor (log10 (PopulatedCells)) ...
            && TotalPoints >= MinPoints
        SignificantClusters = SignificantClusters + 1;
        Clusters {SignificantClusters} = select (Cloud, SetIndices);
    end
end

end