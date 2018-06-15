function [RotatedCloud, AlfaPlane, InlierIndices, OutlierIndices] = ...
    RotatePointCloud (Cloud, Plot, varargin)

%   ROTATEPOINTCLOUD fits a plane to the given point cloud. This plane will
%   help the rotation of the cloud

%%  Inputs

%   Cloud       Input point cloud
%   Plot        Use 'Yes' to plot the main figures and 'No' to ignore them

%   varargin
%   ReferenceVector     Orientation constraints to the fitted plane

%%  Outputs

%   RotatedCloud    Rotated point cloud
%   AlfaPlane       Geometrical model that describes the plane
%   InlierIndices   Linear indices to the inlier points in the plane
%   OutlierIndices  Linear indices to the outlier points in the plane

%%  Input Parsing

if nargin == 2, ReferenceVector = [];
elseif nargin == 3, ReferenceVector = varargin {1};
elseif nargin > 3, error (message ('MATLAB:narginchk:tooManyInputs'));
end

%%  Changeable Properties

% Define the minimum number of points of the cloud, in percentage, that the
% plane should include to the fitting be considered
Threshold = 0;

% Parameters that define the accuracy of plane fitting
MaxDistance = 0.0025;   % Maximum gap from an inlier point to the plane
MaxAngDistance = 5;     % Maximum distance from the specified orientation
MaxNumTrials = 1000;    % Maximum number of trials for finding inliers
Confidence = 99.9;      % Confidence percentage for finding inliers

%%  Plane Fitting

warning ('off', 'vision:ransac:maxTrialsReached')

% Fit the first accurate plane to the point cloud
if isempty (ReferenceVector)
    [AlfaPlane, InlierIndices, OutlierIndices] = pcfitplane (Cloud, ...
        MaxDistance, 'MaxNumTrials', MaxNumTrials, ...
        'Confidence', Confidence);
else
    [AlfaPlane, InlierIndices, OutlierIndices] = pcfitplane (Cloud, ...
        MaxDistance, ReferenceVector, MaxAngDistance, 'MaxNumTrials', ...
        MaxNumTrials, 'Confidence', Confidence);
end
Significance = numel (InlierIndices) / Cloud.Count * 100;

% Try a more accurate fitting
if isempty (ReferenceVector)
    for i = 1 : 20
        [Plane, Inliers, Outliers] = pcfitplane (Cloud, MaxDistance, ...
            'MaxNumTrials', MaxNumTrials, 'Confidence', Confidence);
        if numel (Inliers) / Cloud.Count * 100 > Significance
            AlfaPlane = Plane;
            InlierIndices = Inliers;
            OutlierIndices = Outliers;
            Significance = numel (InlierIndices) / Cloud.Count * 100;
        end
    end
else
    for i = 1 : 20
        [Plane, Inliers, Outliers] = pcfitplane (Cloud, MaxDistance, ...
            ReferenceVector, MaxAngDistance, 'MaxNumTrials', ...
            MaxNumTrials, 'Confidence', Confidence);
        if numel (Inliers) / Cloud.Count * 100 > Significance
            AlfaPlane = Plane;
            InlierIndices = Inliers;
            OutlierIndices = Outliers;
            Significance = numel (InlierIndices) / Cloud.Count * 100;
        end
    end
end

if Significance >= Threshold
%     info = strcat ('Plane fitting successful.', ...
%         ' Inliers represent %4.2f%% of total points.\n');
%     fprintf (info, Significance);
else
%     info = strcat ('Plane fitting unsuccessful.', ...
%         ' Inliers represent %4.2f%% of total points.\n');
%     warning (info, Significance);
    RotatedCloud = Cloud;
    return
end

%%  Point Cloud Rotation

% Rotate the point cloud, aligning the normal of the cloud to the Z axis
N1 = [0, 1, 0];
N2 = AlfaPlane.Normal;

RotatedCloud = RotateFromVector (Cloud, N1, N2);

% % Check the orientation of the rotated cloud
% Locations = double (RotatedCloud.Location);
% Inliers = Locations (InlierIndices, :);
% InliersHeight = mean (Inliers (:, 2));
% Outliers = Locations (OutlierIndices, :);
% OutliersHeight = mean (Outliers (:, 2));
% 
% if OutliersHeight > InliersHeight
%     Locations = [Locations(:, 1), -Locations(:, 2), Locations(:, 3)];
%     RotatedCloud = pointCloud (single (Locations));
%     Parameters = AlfaPlane.Parameters;
%     AlfaPlane = planeModel (Parameters .* [1 -1 1 1]);
% end

%%  Plotting

if strcmpi (Plot, 'Yes')
    figure ('Name', 'ROTATED POINT CLOUD', 'NumberTitle', 'off');
    subplot (1, 2, 1); pcshow (Cloud); view (3);
    title ('Point Cloud Before Rotation');
    xlabel ('X [m]'); ylabel ('Y [m]'); zlabel ('Z [m]');
    subplot (1, 2, 2); pcshow (RotatedCloud); view (3);
    title ('Point Cloud After Rotation');
    xlabel ('X [m]'); ylabel ('Y [m]'); zlabel ('Z [m]');
end

end