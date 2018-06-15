% Name:     From Images To Features
% Purpose:  RGB-D images were collect from the Microsoft Kinect V2. Now,
%           they will be to extract both shape and visual features

% Author:   André Brás
% Created:  28/05/2018

%%  Changeable Properties

% Script initialization
close all; clear; clc;

% Use 'Yes' to plot the main figures and 'No' to ignore them
Plot = 'No';

% Set the desired objects from the YCB Object and Model Set
Objects = {};   Objects {1, 1} = '001_chips_can';
                Objects {1, 2} = '002_master_chef_can';
                Objects {1, 3} = '003_cracker_box';
                Objects {1, 4} = '004_sugar_box';
                Objects {1, 5} = '005_tomato_soup_can';
                Objects {1, 6} = '006_mustard_bottle';
                Objects {1, 7} = '009_gelatin_box';
                Objects {1, 8} = '010_potted_meat_can';
                Objects {1, 9} = '013_apple';
                Objects {1, 10} = '014_lemon';
                Objects {1, 11} = '015_peach';
                Objects {1, 12} = '017_orange';
                Objects {1, 13} = '018_plum';
                Objects {1, 14} = '019_pitcher_base';
                Objects {1, 15} = '021_bleach_cleanser';
                Objects {1, 16} = '024_bowl';
                Objects {1, 17} = '036_wood_block';
                Objects {1, 18} = '054_softball';
                Objects {1, 19} = '055_baseball';
                Objects {1, 20} = '056_tennis_ball';
                

% The input point cloud is downsampled to ensure coverage and speed. We
% choose a reasonable sampling parameter which specifies the portion of
% the input to be returned by the output
DownsampleParam = 0.60;

% The point cloud includes irrelevant data. They can be trimmed based on
% the rough knowledge of the configuration between the turntable and the
% camera. The idea is to remove most of the background by taking only the
% points within a 3D bounding box where it is expected to find the
% turntable and the camera
Shape = 'Prism';                    % Geometric shape of the cloud
Center = [0.00 0.00 1.00];          % XYZ coordinates of the center
Dimensions = [0.60 0.80 1.00];      % Size of the output cloud

% During the testing, the table plan is not so flat as during the feature
% extraction. Hence, after the extraction of this plane, there are a few
% table points remaining. One possible solution to remove them is to use
% the denoise function. Here, we define the number of neighbors
NumNeighbors = 50;

% Since the turntable's plane is removed, it is expected that only
% significant clusters and a few outliers are included. The search for
% regions of interest will allow the extraction of the ouliers and the
% segmentation of objects
Type = 'Dimensions';    % Type of data to split the grid in small cells
Values = [0.01, 0.01];  % Array including the size of cell along each axis
Mode = 'Depth';         % 'Height' to count points in vertical columns and
                        % 'Depth' in columns with the depth direction.
                        
% At the end, primitive geometric shapes are fitted to the cluster, which
% allows the extraction of three shape features, namely the geometric
% shape, the corresponding fitting score and the volume of the object
Runs = 100;             % Number of runs performed for shape fitting

%% Feature Extraction

Features = cell (20, 1);

% The Kinect for Windows Sensor shows up as two separate devices
KinectInfo = imaqhwinfo ('kinect');

% Create the VIDEODEVICE objects for the color and depth streams
ColorDevice = imaq.VideoDevice ('kinect', 1);
DepthDevice = imaq.VideoDevice ('kinect', 2);

for Object = 1 : 20
    
    Iteration = 0;
        
    load (strcat ('/object_', string (Object), '.mat'));

    for Sample = 1 : length (ColorImages)

        ColorImage = ColorImages {Sample};
        DepthImage = DepthImages {Sample};

        % The depth image is used to build the point cloud. The RGB
        % image is also used in order to color the point cloud
        PtCloud = pcfromkinect (DepthDevice, DepthImage, ColorImage);
        PtCloud = PtCloud.removeInvalidPoints;

        % The input point cloud is downsampled to ensure coverage and
        % speed. We choose a reasonable sampling parameter to specify
        % the portion of the input to be returned by the output
        PtCloud = pcdownsample (PtCloud, 'random', DownsampleParam);

        if strcmpi (Plot, 'Yes')

            figure ('Name', 'POINT CLOUD ACQUISITION', ...
                'NumberTitle', 'off');
            MyAxes = pcshow (PtCloud);

            MyAxes.XLim = [-2 2];
            MyAxes.YLim = [-1 1];
            MyAxes.ZLim = [0 3];

            MyAxes.XTick = [-2 -1 0 1 2];
            MyAxes.XTickLabelMode = 'manual';
            MyAxes.XTickLabel = {'', '', '', '', ''};

            MyAxes.YTick = [-1 0 1];
            MyAxes.YTickLabelMode = 'manual';
            MyAxes.YTickLabel = {'', '', ''};

            MyAxes.ZTick = [0 1 2 3];
            MyAxes.ZTickLabelMode = 'manual';
            MyAxes.ZTickLabel = {'', '', '', ''};

            MyAxes.CameraPositionMode = 'manual';
            MyAxes.CameraPosition = [-10, -25, -35];
            MyAxes.CameraUpVector = [0 -1 0];

        end

        % The point cloud includes irrelevant data. They can be trimmed
        % based on the rough knowledge of the configuration between the
        % turntable and the camera. The idea is to remove most of the
        % background by taking only the points within a 3D bounding box
        % where it is expected to find the turntable and the camera
        PtCloud = TrimPointCloud (PtCloud, Shape, Center, ...
            Dimensions, Plot);

        % To ease the extraction of turntable's plane, it should be
        % aligned with the frontal plane XOZ, like if this plane was a
        % wall. Firstly, a rotation is performed based on the rough
        % knowledge of the angle between the camera and the turntable.
        % Then, a fine tune rotation is executed through plane fitting
        Matrix = vrrotvec2mat ([1 0 0 (deg2rad (30))]);
        Matrix (4, 1 : 4) = [0 0 0 1];
        Matrix = affine3d (Matrix);
        RotatedCloud = pctransform (PtCloud, Matrix);

        ReferenceVector = [0 1 0];
        [RotatedCloud, ~, ~, ~] = RotatePointCloud (RotatedCloud, ...
            'No', ReferenceVector);

        if strcmpi (Plot, 'Yes')

            figure ('Name', 'POINT CLOUD ROTATION', ...
                'NumberTitle', 'off');
            MyAxes = pcshow (RotatedCloud);

            MyAxes.XTick = [-0.3 -0.2 -0.1 0 0.1 0.2 0.3];
            MyAxes.XTickLabelMode = 'manual';
            MyAxes.XTickLabel = {'', '', '', '', '', '', ''};

            MyAxes.YTick = [0 0.1 0.2 0.3 0.4 0.5];
            MyAxes.YTickLabelMode = 'manual';
            MyAxes.YTickLabel = {'', '', '', '', '', ''};

            MyAxes.ZTick = [0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 ...
                1.3 1.4 1.5];
            MyAxes.ZTickLabelMode = 'manual';
            MyAxes.ZTickLabel = {'', '', '', '', '', '', '', '', ...
                '', '', '', '', ''};

            MyAxes.CameraPositionMode = 'manual';
            MyAxes.CameraPosition = [-10, -25, -35];
            MyAxes.CameraUpVector = [0 -1 0];

        end

        PtCloud = RemoveFloor(RotatedCloud, Plot);

        % After the extraction of the table's plane, there are a few
        % table points remaining. A possible solution to remove them
        % is to use the denoise function
        PtCloud = pcdenoise (PtCloud, 'NumNeighbors', NumNeighbors);
        PtCloud = pcdenoise (PtCloud, 'NumNeighbors', NumNeighbors);

        if strcmpi (Plot, 'Yes')

            figure ('Name', 'POINT CLOUD DENOISING', ...
                'NumberTitle', 'off');
            MyAxes = pcshow (PtCloud);

            MyAxes.XTick = [-0.3 -0.2 -0.1 0 0.1 0.2 0.3];
            MyAxes.XTickLabelMode = 'manual';
            MyAxes.XTickLabel = {'', '', '', '', '', '', ''};

            MyAxes.YTick = [0 0.1 0.2 0.3 0.4 0.5];
            MyAxes.YTickLabelMode = 'manual';
            MyAxes.YTickLabel = {'', '', '', '', '', ''};

            MyAxes.ZTick = [0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 ...
                1.3 1.4 1.5];
            MyAxes.ZTickLabelMode = 'manual';
            MyAxes.ZTickLabel = {'', '', '', '', '', '', '', '', ...
                '', '', '', '', ''};

            MyAxes.CameraPositionMode = 'manual';
            MyAxes.CameraPosition = [-10, -25, -35];
            MyAxes.CameraUpVector = [0 -1 0];

        end

        % Since the turntable's plane is removed, it is expected that
        % only significant clusters and a few outliers are included.
        % The search for regions of interest will allow the extraction
        % of the ouliers and the segmentation of objects. Sort the
        % segmented clusters by ascending order of number of points
        ROIs = FindROIs (PtCloud, 'Type', Type, 'Values', Values, ...
            'Mode', Mode); TotalROIs = numel (ROIs);

        if TotalROIs > 1

            Significance = zeros (1, TotalROIs);

            for i = 1 : TotalROIs

                ROI = ROIs {i};
                Significance (i) = ROI.Count;

            end

            if ~ issorted (flip (Significance))

                [~, Order] = sort (Significance, 'descend');
                ROIs = ROIs (1, Order);

            end

            ROIs = ROIs (1); TotalROIs = 1;

        end

        if strcmpi (Plot, 'Yes')

            figure ('Name', 'REGIONS OF INTEREST', ...
                'NumberTitle', 'off');
            Rows = ceil (TotalROIs / 2);
            Columns = min ([TotalROIs, 2]);

            for i = 1 : TotalROIs

                subplot (Rows, Columns, i); 
                MyAxes = pcshow (ROIs {i});

                MyAxes.XTick = [-0.3 -0.2 -0.1 0 0.1 0.2 0.3];
                MyAxes.XTickLabelMode = 'manual';
                MyAxes.XTickLabel = {'', '', '', '', '', '', ''};

                MyAxes.YTick = [0 0.1 0.2 0.3 0.4 0.5];
                MyAxes.YTickLabelMode = 'manual';
                MyAxes.YTickLabel = {'', '', '', '', '', ''};

                MyAxes.ZTick = [0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1.1 ...
                    1.2 1.3 1.4 1.5];
                MyAxes.ZTickLabelMode = 'manual';
                MyAxes.ZTickLabel = {'', '', '', '', '', '', '', ...
                    '', '', '', '', '', ''};

                MyAxes.CameraPositionMode = 'manual';
                MyAxes.CameraPosition = [-10, -25, -35];
                MyAxes.CameraUpVector = [0 -1 0];

            end

        end

        % At the end, primitive geometric shapes are fitted to the
        % cluster, which allows the extraction of three shape features,
        % namely the geometric shape, the corresponding fitting score
        % and the volume of the object
        [Geometry, Quality, Volume, ~] = ...
            ExtractShapeFeatures (ROIs, Runs, {'All'}, Plot);

        % Extract the primary color and the three secondary colors for
        % each cluster
        ColorFeatures = zeros (TotalROIs, 12);

        for i = 1 : TotalROIs

            ROI = ROIs {i};
            [~, MainColor] = kmeans (double (ROI.Color), 1);
            [Idx, SecondaryColors] = kmeans (double (ROI.Color), 3);

            % Sort the secondary colors in descending order of
            % importance
            Counts = [sum(Idx == 1), sum(Idx == 2), sum(Idx == 3)];

            if ~ issorted (flip (Counts))

                [~, Order] = sort (Counts, 'descend');
                SecondaryColors = SecondaryColors (Order, :);

            end

            ColorFeatures (i, :) = ...
                [MainColor (SecondaryColors (1, :)) ...
                (SecondaryColors (2, :)) (SecondaryColors (3, :))];

        end

        if strcmpi (Plot, 'Yes')

            figure ('Name', strcat (string (Object), '_', ...
                string (Folder)), 'NumberTitle', 'off');

            for i = 1 : TotalROIs

                subplot (TotalROIs, 5, 1 + (i - 1) * 5);
                pcshow (ROIs {i}); title (sprintf ('ROI %i', i));

                Color = [];
                Color (1, 1, 1 : 3) = ColorFeatures (i, 1 : 3);
                Color = repmat (uint8 (Color), 20);
                subplot (TotalROIs, 5, 2 + (i - 1) * 5);
                imshow (Color); title ("Main Color")

                for j = 1 : 3
                    Color = [];
                    Color (1, 1, 1 : 3) = ColorFeatures (i, j * 3 + 1 : j * 3 + 3);
                    Color = repmat (uint8 (Color), 20);
                    subplot (TotalROIs, 5, 2 + j + (i - 1) * 5);
                    imshow (Color); title (strcat ("Color ", string (j)));
                end

            end

        end

        if ~ isempty (Geometry)

            Iteration = Iteration + 1;
            Features {Object, 1} (end + 1, :) = ...
                [Geometry, Quality, Volume, ColorFeatures];

        end
        
    end
    
    save ('Kinect_Features.mat', 'Features')
    
end