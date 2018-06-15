function [Geometries, Qualities, Volumes, Locations] = ...
    ExtractShapeFeatures (Clusters, Runs, Fit, Plot)

%   EXTRACTSHAPEFEATURES chooses the best primitive shape that fits each
%   cluster and gives the corresponding score, volume and center point

%%	Inputs

%   Clusters    Input point clouds, each one comprising one cluster
%   Runs        Number of runs performed for shape fitting
%   Fit         Primitive geometric shape that will be fitted
%   Plot        Use 'Yes' to plot the main figures and 'No' to ignore them

%%	Outputs

%   Geometries  Best geometry fitted to each cluster
%   Scores      Quality of the best fitting to each cluster
%   Volumes     Volume of the best geometry fitted to each cluster
%   Locations   Center point of the best geometry fitted to each cluster

%%  Preallocation of Variables

TotalClusters = numel (Clusters);
Geometries = zeros (TotalClusters, 1);
Qualities = zeros (TotalClusters, 1);
Volumes = zeros (TotalClusters, 1);
Locations = zeros (TotalClusters, 3);

%%  Shape Fitting

for i = 1 : TotalClusters
    Cluster = Clusters {i};
    Limits = [Cluster.XLimits; Cluster.YLimits; Cluster.ZLimits];
    Size (1 : 3, 1) = Limits (1 : 3, 2) - Limits (1 : 3, 1);
    PointCloudVolume = Size (1) * Size (2) * Size (3);
    PointCloudCenter = [(sum(Cluster.XLimits) / 2), ...
            (sum(Cluster.YLimits) / 2), (sum(Cluster.ZLimits) / 2)];
    % Fit the primitive geometric shapes to the cluster
    [Models, Scores, ~] = FitPrimitiveShapes (Cluster, Runs, Fit, Plot);
    % Look for the maximum score and the corresponding geometry
    [Score, Geometry] = max (Scores);
    % If all scores are below of 0.50, then the object has no primitive
    % shape. Their volume and location should be computed based on the
    % limits of the cloud
    if Score <= 0.50
        Geometry = 4;
        Score = 1;
        Volume = PointCloudVolume;
        Location = PointCloudCenter;
    else
        if Geometry == 1
            Model = Models {Geometry};
            Radius = Model.Radius;
            Height = Model.Height;
            Volume = pi * (Radius ^ 2) * Height;
            Location = Model.Center;
        elseif Geometry == 2
            Model = Models {Geometry};
            Radius = Model.Radius;
            Volume = (4 / 3) * pi * (Radius ^ 3);
            Location = Model.Center;
        elseif Geometry == 3
            Model = Models {Geometry};
            PlaneP1P2 = Model {1};
            PlaneP3P4 = Model {2};
            PlaneP1P3 = Model {3};
            PlaneP2P4 = Model {4};
            PlaneTop = Model {5};
            PlaneFloor = Model {6};
            [X1, Z1] = FuncToIntersectPlanes (...
                PlaneP1P2, PlaneP1P3, PointCloudCenter (2));
            [X2, Z2] = FuncToIntersectPlanes (...
                PlaneP1P2, PlaneP2P4, PointCloudCenter (2));
            [X3, Z3] = FuncToIntersectPlanes (...
                PlaneP1P3, PlaneP3P4, PointCloudCenter (2));
            [~, Z4] = FuncToIntersectPlanes (...
                PlaneP2P4, PlaneP3P4, PointCloudCenter (2));
            % Compute the height of top plane at the center of prism
            Center = [((X2 + X3) / 2), ((Z1 + Z4) / 2)];
            Param = PlaneTop.Parameters;
            PlaneTopHeight = (- Param (1) * Center (1) - ...
                Param (3) * Center (2) - Param (4)) / Param (2);
            % Compute the height of floor plane at the center of prism
            Param = PlaneFloor.Parameters;
            PlaneFloorHeight = (- Param (1) * Center (1) - ...
                Param (3) * Center (2) - Param (4)) / Param (2);
            % Compute the height of the prism
            Height = abs (PlaneTopHeight - PlaneFloorHeight);
            % Compute the side sizes of the prism
            Length = sqrt ((X2 - X1) ^ 2 + (Z2 - Z1) ^ 2);
            Width = sqrt ((X3 - X1) ^ 2 + (Z3 - Z1) ^ 2);
            Volume = Length * Width * Height;
            Location = [Center(1), ((PlaneTopHeight + ...
                (- PlaneFloor.Parameters(4))) / 2), Center(2)];
        end
        if  Volume > PointCloudVolume
            Volume = PointCloudVolume;
            Location = PointCloudCenter;
        end
    end
    Geometries (i) = Geometry;
    Qualities (i) = Score;
    Volumes (i) = Volume;
    Locations (i, :) = Location;
end

end