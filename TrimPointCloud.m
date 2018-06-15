function [TrimmedCloud] = TrimPointCloud (Cloud, Shape, Center, Size, Plot)

%   TRIMPOINTCLOUD trims the point cloud given as input by a sphere, a
%   cube, a prism or an ellipsoid. The trimming operation is based on the
%   distance to the specified center position

%%  Inputs

%   Cloud       Input point cloud
%   Shape       Can be an integer or a string specifying the shape that
%               will be trimmed: 1 - 'Cube', 2 - 'Sphere', 3 - 'Prism', 4 -
%               'Ellipsoid'
%   Center      1-by-3 or 3-by-1 vector with XYZ coordinates of center
%   Size        Size of the shape that will be trimmed. If you selected the
%               Cube or the Sphere, you only have to give one dimension,
%               which is the side length or the radius, respectively. If
%               you chose the Prism or the Ellipsoid, you should specify
%               three dimensions, being them the side lengths or the
%               radiuses, respectively, along the three cartesian axes
%   Plot        Use 'Yes' to plot the main figures and 'No' to ignore them

%%  Output

%   TrimmedCloud    Trimmed point cloud

%%  Input Parsing

% Errors
if ((isnumeric (Shape) && Shape == 3) || strcmpi (Shape, 'Prism')) ...
        && numel (Size) ~= 3
    error (strcat ('Prism requires three dimensions, which are the', ...
        ' side lengths.'));
end
if ((isnumeric (Shape) && Shape == 4) || strcmpi (Shape, 'Ellipsoid')) ...
        && numel (Size) ~= 3
    error (strcat ('Ellipsoid requires three dimensions, which are', ...
        ' the radiuses along the XYZ axes.'));
end

% Warnings
if ((isnumeric (Shape) && Shape == 1) || strcmpi (Shape, 'Cube')) ...
        && numel (Size) > 1
    warning (strcat ('Cube only needs one dimensions, which is the', ...
        ' side length. This function will, therefore, use only the', ...
        ' first specified dimension.'));
end
if ((isnumeric (Shape) && Shape == 2) || strcmpi (Shape, 'Sphere')) ...
        && numel (Size) > 1
    warning (strcat ('Sphere only needs one dimensions, which is the', ...
        ' radius. This function will, therefore, use only the first', ...
        ' specified dimension.'));
end

%%  Preallocation of Variables

Coordinates = double (Cloud.Location);
Dimensionality = numel (size (Coordinates));

if Dimensionality == 3
    Norms = zeros (size (Coordinates, 1), size (Coordinates, 2));
    UsefullPoints = zeros (size (Coordinates, 1), size (Coordinates, 2));
elseif Dimensionality == 2
    Norms = zeros (1, size (Coordinates, 1));
    UsefullPoints = zeros (1, size (Coordinates, 1));
end

%%  Trimming Operation

% Cube
if ((isnumeric (Shape) && Shape == 1) || strcmpi (Shape, 'Cube'))
    Size = Size (1) / 2;
    Limits = zeros (2, 3);
    Limits (1, 1 : 3) = Center (1 : 3) - Size;
    Limits (2, 1 : 3) = Center (1 : 3) + Size;
    UsefulIndices = findPointsInROI (Cloud, Limits');
    
% Sphere
elseif ((isnumeric (Shape) && Shape == 2) || strcmpi (Shape, 'Sphere'))
    if Dimensionality == 3
        for i = 1 : size (Coordinates, 1)
            for j = 2 : size (Coordinates, 2)
                Point = Coordinates (i, j, :);
                Norms (i, j) = pdist ([(Point (:))'; ...
                    Center(1) Center(2) Center(3)]);
            end
        end
    elseif Dimensionality == 2
        for i = 1 : size (Coordinates, 1)
            Point = Coordinates (i, :);
            Norms (i) = pdist ([Point; Center(1) Center(2) Center(3)]);
        end
    end
    UsefulIndices = find (Norms (:) <= Size (1));
    
% Prism
elseif ((isnumeric (Shape) && Shape == 3) || strcmpi (Shape, 'Prism'))
    Size = Size ./ 2;
    Limits = zeros (2, 3);
    Limits (1, 1 : 3) = Center (1 : 3) - Size (1 : 3);
    Limits (2, 1 : 3) = Center (1 : 3) + Size (1 : 3);
    UsefulIndices = findPointsInROI (Cloud, Limits');
    
% Ellipsoid
elseif ((isnumeric (Shape) && Shape == 4) || strcmpi (Shape, 'Ellipsoid'))
    % The implict equation of the ellipsoid has the following standard
    % form: (x^2)/(a^2) + (y^2)/(b^2) + (z^2)/(c^2) = 1, being a, b and c
    % the radiuses along the XYZ axes. Since the points of interest are in
    % the ellipsoid and inside it, the equal to signal is replaced by the
    % smaller than or equal to signal
    if Dimensionality == 3
        for i = 1 : size (Coordinates, 1)
            for j = 2 : size (Coordinates, 2)
                Point = Coordinates (i, j, :);
                UsefullPoints (i, j) = ( ...
                    ((Center (1) - Point (1)) ^ 2) / (Size (1) ^ 2) + ...
                    ((Center (2) - Point (2)) ^ 2) / (Size (2) ^ 2) + ...
                    ((Center (3) - Point (3)) ^ 2) / (Size (3) ^ 2)) <= 1;
            end
        end
    elseif Dimensionality == 2
        for i = 1 : size (Coordinates, 1)
            Point = Coordinates (i, :);
            UsefullPoints (i) = ( ...
                ((Center (1) - Point (1)) ^ 2) / (Size (1) ^ 2) + ...
                ((Center (2) - Point (2)) ^ 2) / (Size (2) ^ 2) + ...
                ((Center (3) - Point (3)) ^ 2) / (Size (3) ^ 2)) <= 1;
        end
    end
    UsefulIndices = find (UsefullPoints (:) == 1);
end

TrimmedCloud = select (Cloud, UsefulIndices);

%%  Plotting

if strcmpi (Plot, 'Yes')
    
    figure ('Name', 'BACKGROUND REMOVAL', 'NumberTitle', 'off');
    MyAxes = pcshow (TrimmedCloud);
    
    MyAxes.XTick = [-0.3 -0.2 -0.1 0 0.1 0.2 0.3];
    MyAxes.XTickLabelMode = 'manual';
    MyAxes.XTickLabel = {'', '', '', '', '', '', ''};
    
    MyAxes.YTick = [-0.3 -0.2 -0.1 0 0.1 0.2 0.3];
    MyAxes.YTickLabelMode = 'manual';
    MyAxes.YTickLabel = {'', '', '', '', '', '', ''};
    
    MyAxes.ZTick = [0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 1.3 1.4 1.5];
    MyAxes.ZTickLabelMode = 'manual';
    MyAxes.ZTickLabel = {'', '', '', '', '', '', '', '', '', '', ''};
    
    MyAxes.CameraPositionMode = 'manual';
    MyAxes.CameraPosition = [-10, -25, -35];
    MyAxes.CameraUpVector = [0 -1 0];
    
%     print (gcf, '2_BackgroundRemoval.emf', ...
%         '-dmeta', '-r300', '-painters');
    
%     xlabel ('X [m]'); ylabel ('Y [m]'); zlabel ('Z [m]');

elseif strcmpi (Plot, 'Test')

    figure ('Name', 'BACKGROUND REMOVAL', 'NumberTitle', 'off');
    MyAxes = pcshow (TrimmedCloud);

    MyAxes.CameraPositionMode = 'manual';
    MyAxes.CameraPosition = [-10, -25, -35];
    MyAxes.CameraUpVector = [0 -1 0];
    
end

end
