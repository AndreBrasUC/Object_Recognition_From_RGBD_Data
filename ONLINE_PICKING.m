% Name:     Real Time Object Recognition
% Purpose:  RGB-D images are collect from the Microsoft Kinect V2, feature
%           extraction is performed and object recognition is finally
%           accomplished with a previously trained neural network

% Author:   André Brás
% Created:  04/06/2018

%%  Establish Connection with KUKA LBR iiwa

% Script initialization
close all; clear; clc;

addpath (strcat ('C:\Users\hp\Desktop\KUKA Sunrise Toolbox\', ...
    'OtherFlavours\RKST\Matlab_server'));

% Set the IP of the controller and start a connection with the server
ip = '172.31.1.147'; t = net_establishConnection (ip);

% Set the IP of the raspberry and start a connection with the server
ip = '192.168.1.196'; u = tcpip (ip, 1080, 'Terminator', 'CR/LF');
fopen (u);

%%  Changeable Properties

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
DownsampleParameter = 0.60;

% The point cloud includes irrelevant data. They can be trimmed based on
% the rough knowledge of the configuration between the turntable and the
% camera. The idea is to remove most of the background by taking only the
% points within a 3D bounding box where it is expected to find the
% turntable and the camera
Shape = 'Prism';                    % Geometric shape of the cloud

% Use this values when using Kinect on the table
% Center = [0.00 0.00 1.00];          % XYZ coordinates of the center
% Dimensions = [0.60 0.80 1.00];      % Size of the output cloud

% Use this values when testing with KUKA LBR iiwa
Center = [0.15 -0.25 1.00];         % XYZ coordinates of the center
Dimensions = [0.50 1.50 1.00];      % Size of the output cloud

% During the testing, the table plan is not so flat as during the feature
% extraction. Hence, after the extraction of this plane, there are a few
% table points remaining. One possible solution to remove them is to use
% the denoise function. Here, we define the number of neighbors
Neighbors = 50;

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

% Set the minimum accuracy that an object has to achieve to be considered
Threshold = 0.50;

%% Feature Extraction

% The Kinect for Windows Sensor shows up as two separate devices
KinectInfo = imaqhwinfo ('kinect');

% Create the VIDEODEVICE objects for the color and depth streams
ColorDevice = imaq.VideoDevice ('kinect', 1);
DepthDevice = imaq.VideoDevice ('kinect', 2);
        
load ('Kinect_Networks\Train_Network_Color_3.mat');
load ('ONLINE_PICKING_DATA.mat')

while Runs

    % Acquire an RGB-D frame, which will be used to build the point cloud.
    % After the acquisition, the objects should be released
    ColorImage = step (ColorDevice);
    DepthImage = step (DepthDevice);

    release (ColorDevice);
    release (DepthDevice);

    % The depth image is used to build the point cloud. The RGB image is
    % also used in order to color the point cloud
    PtCloud = pcfromkinect (DepthDevice, DepthImage, ColorImage);
    PtCloud = PtCloud.removeInvalidPoints;

    % The input point cloud is downsampled to ensure coverage and speed.
    % We choose a reasonable sampling parameter to specify the portion of
    % the input to be returned by the output
    PtCloud = pcdownsample (PtCloud, 'random', DownsampleParameter);

    if strcmpi (Plot, 'Yes')

        figure ('Name', 'POINT CLOUD ACQUISITION', 'NumberTitle', 'off');
        MyAxes = pcshow (PtCloud);

        MyAxes.XLim = [-2 2];
        MyAxes.YLim = [-1 1];
        MyAxes.ZLim = [0 3];

        MyAxes.XTick = [-2 -1 0 1 2];
        MyAxes.XTickLabelMode = 'auto';
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
        
    elseif strcmpi (Plot, 'Test')
        
        figure ('Name', 'POINT CLOUD ACQUISITION', 'NumberTitle', 'off');
        MyAxes = pcshow (PtCloud);
        
        MyAxes.XLim = [-1 1];
        MyAxes.YLim = [-1 1];
        MyAxes.ZLim = [0 2];
        
        MyAxes.CameraPositionMode = 'manual';
        MyAxes.CameraPosition = [-10, -25, -35];
        MyAxes.CameraUpVector = [0 -1 0];
        
    end
    
    % The point cloud includes irrelevant data. They can be trimmed based
    % on the rough knowledge of the configuration between the turntable and
    % the camera. The idea is to remove most of the background by taking
    % only the points within a 3D bounding box where it is expected to find
    % the turntable and the camera
    PtCloud = TrimPointCloud (PtCloud, Shape, Center, ...
        Dimensions, Plot);

    % To ease the extraction of turntable's plane, it should be aligned
    % with the frontal plane XOZ, like if this plane was a wall. Firstly, a
    % rotation is performed based on the rough knowledge of the angle
    % between the camera and the turntable. Then, a fine tune rotation is
    % executed through plane fitting
    
    % Use this values when using Kinect on the table
    % Matrix = vrrotvec2mat ([1 0 0 (deg2rad (30))]);
    
    % Use this values when testing with KUKA LBR iiwa
    Matrix = vrrotvec2mat ([1 0 0 (deg2rad (37))]);
    Matrix (4, 1 : 4) = [0 0 0 1];
    Matrix = affine3d (Matrix);
    RotatedCloud = pctransform (PtCloud, Matrix);

%     ReferenceVector = [0 1 0];
%     [RotatedCloud, ~, ~, ~] = RotatePointCloud (RotatedCloud, 'No', ...
%         ReferenceVector);

    if strcmpi (Plot, 'Yes')

        figure ('Name', 'POINT CLOUD ROTATION', 'NumberTitle', 'off');
        MyAxes = pcshow (RotatedCloud);

        MyAxes.XTick = [-0.3 -0.2 -0.1 0 0.1 0.2 0.3];
        MyAxes.XTickLabelMode = 'manual';
        MyAxes.XTickLabel = {'', '', '', '', '', '', ''};

        MyAxes.YTick = [0 0.1 0.2 0.3 0.4 0.5];
        MyAxes.YTickLabelMode = 'manual';
        MyAxes.YTickLabel = {'', '', '', '', '', ''};

        MyAxes.ZTick = [0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 1.3 1.4 1.5];
        MyAxes.ZTickLabelMode = 'manual';
        MyAxes.ZTickLabel = {'', '', '', '', '', '', '', '', '', '', ...
            '', '', ''};

        MyAxes.CameraPositionMode = 'manual';
        MyAxes.CameraPosition = [-10, -25, -35];
        MyAxes.CameraUpVector = [0 -1 0];
        
    elseif strcmpi (Plot, 'Test')
        
        figure ('Name', 'POINT CLOUD ROTATION', 'NumberTitle', 'off');
        MyAxes = pcshow (RotatedCloud);
        
        MyAxes.CameraPositionMode = 'manual';
        MyAxes.CameraPosition = [-10, -25, -35];
        MyAxes.CameraUpVector = [0 -1 0];

    end

    PtCloud = RemoveFloor(RotatedCloud, Plot);

    % After the extraction of the table's plane, there are a few table
    % points remaining. A possible solution to remove them is to use the
    % denoise function
    PtCloud = pcdenoise (PtCloud, 'NumNeighbors', Neighbors);
    PtCloud = pcdenoise (PtCloud, 'NumNeighbors', Neighbors);
    PtCloud = pcdenoise (PtCloud, 'NumNeighbors', ceil (Neighbors / 2));
    PtCloud = pcdenoise (PtCloud, 'NumNeighbors', ceil (Neighbors / 10));
    PtCloud = pcdenoise (PtCloud, 'NumNeighbors', ceil (Neighbors / 10));

    if strcmpi (Plot, 'Yes')

        figure ('Name', 'POINT CLOUD DENOISING', 'NumberTitle', 'off');
        MyAxes = pcshow (PtCloud);

        MyAxes.XTick = [-0.3 -0.2 -0.1 0 0.1 0.2 0.3];
        MyAxes.XTickLabelMode = 'manual';
        MyAxes.XTickLabel = {'', '', '', '', '', '', ''};

        MyAxes.YTick = [0 0.1 0.2 0.3 0.4 0.5];
        MyAxes.YTickLabelMode = 'manual';
        MyAxes.YTickLabel = {'', '', '', '', '', ''};

        MyAxes.ZTick = [0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 1.3 1.4 1.5];
        MyAxes.ZTickLabelMode = 'manual';
        MyAxes.ZTickLabel = {'', '', '', '', '', '', '', '', '', '', ...
            '', '', ''};

        MyAxes.CameraPositionMode = 'manual';
        MyAxes.CameraPosition = [-10, -25, -35];
        MyAxes.CameraUpVector = [0 -1 0];
        
    elseif strcmpi (Plot, 'Test')
        
        figure ('Name', 'POINT CLOUD DENOISING', 'NumberTitle', 'off');
        MyAxes = pcshow (PtCloud);
        
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

            ROI = ROIs {i}; Significance (i) = ROI.Count;

        end

        if ~ issorted (flip (Significance))

            [~, Order] = sort (Significance, 'descend');
            ROIs = ROIs (1, Order);

        end

    end

    if strcmpi (Plot, 'Yes')

        figure ('Name', 'REGIONS OF INTEREST', 'NumberTitle', 'off');
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
        
    elseif strcmpi (Plot, 'Test')
        
        figure ('Name', 'REGIONS OF INTEREST', 'NumberTitle', 'off');
        Rows = ceil (TotalROIs / 2);
        Columns = min ([TotalROIs, 2]);

        for i = 1 : TotalROIs

            subplot (Rows, Columns, i); 
            MyAxes = pcshow (ROIs {i});

            MyAxes.CameraPositionMode = 'manual';
            MyAxes.CameraPosition = [-10, -25, -35];
            MyAxes.CameraUpVector = [0 -1 0];

        end

    end

%     % At the end, primitive geometric shapes are fitted to the
%     % cluster, which allows the extraction of three shape features,
%     % namely the geometric shape, the corresponding fitting score
%     % and the volume of the object
%     [Geometry, Quality, Volume, ~] = ...
%         ExtractShapeFeatures (ROIs, Runs, {'All'}, Plot);

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

    if strcmpi (Plot, 'Yes') || strcmpi (Plot, 'Test')

        figure ('Name', 'VISUAL FEATURE EXTRACTION', 'NumberTitle', 'off');

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
                Color (1, 1, 1 : 3) = ...
                    ColorFeatures (i, j * 3 + 1 : j * 3 + 3);
                Color = repmat (uint8 (Color), 20);
                subplot (TotalROIs, 5, 2 + j + (i - 1) * 5);
                imshow (Color); title (strcat ("Color ", string (j)));
                
            end

        end

    end
    
    SpottedObjects = [];
    
    if any (ColorFeatures)
        
        Scores = net (ColorFeatures');
        [Max, Obj] = max (Scores, [], 1);
        
        for i = 1 : numel (Max)
            
            if Max (i) >= Threshold
                
                % SpottedObjects = [Position Object Score]
                SpottedObjects (end + 1, 1 : 3) = [i (Obj (i)) (Max (i))];
                
            end
            
        end
        
        % Each object can only be spotted once but if the method says that
        % an object exists twice, we keep the one with the highest score
        [~, Order] = sort (SpottedObjects (:, 3), 'descend');
        SpottedObjects = SpottedObjects (Order, :);
        
        [~, Order, ~] = unique (SpottedObjects (:, 2), 'first');
        SpottedObjects = SpottedObjects (Order, :);
        
        % Compute the center position for each object
        for Region = 1 : size (SpottedObjects, 1)
            
            ROI = ROIs {SpottedObjects (Region, 1)};
            
            Coords = [(sum(ROI.XLimits) / 2), (sum(ROI.YLimits) / 2), ...
                (sum(ROI.ZLimits) / 2)];
            
            SpottedObjects (Region, 4 : 6) = Coords;
            
        end

    end
    
    % Find the center position of each object relative to the robot
    A = (SpottedObjects (:, [4, 6]))';
    B = (X.s * X.R *A + X.t)'; SpottedObjects (:, [7, 8]) = B;
    
    % Select the object to be picked
    (SpottedObjects (: , 2))'
    Question = 'What object do you want to pick? ';
    Answer = input (Question);
    Line = 0;
    
    for Region = 1 : size (SpottedObjects, 1)
        
        if SpottedObjects (Region, 2) == Answer
            
            Line = Region ; break
            
        end
        
    end
    
    if Line == 0
        
        error ('You should select an available object!');
        
    end
    
    % Lower the robot to the grip position of the highest object
    HighestGripPosition = max (GripPosition);
    Diff = HomePosition_Cartesian {3} - HighestGripPosition;
    
    Velocity = 200; Velocity_Rel = 0.5 ;Target_Rel = {0, 0, Diff};
    movePTPLineEefRelEef(t , Target_Rel, Velocity)
    
    % Move the robot along the horizontal plane to the vertical above the
    % selected object
    CurrentPosition = getEEFPos(t);
    CurrentPosition {1} = SpottedObjects (Line, 7);
    CurrentPosition {2} = SpottedObjects (Line, 8);
    movePTPLineEEF(t , CurrentPosition, Velocity)
    
    % Move the robot to the correct grip position
    CurrentPosition = getEEFPos(t);
    CurrentPosition {3} = GripPosition (SpottedObjects (Line, 2));
    movePTPLineEEF(t, CurrentPosition, Velocity / 2)
    
    % Close hand
    fprintf (u, 'O11'); % CLOSE HAND
    pause (3)
    
    % Move to the deliver position
    CurrentPosition = getEEFPos(t);
    CurrentPosition {3} = HighestGripPosition;
    movePTPLineEEF(t , CurrentPosition, Velocity / 2)
    movePTPJointSpace(t, DeliverPosition_JointSpace, Velocity_Rel / 2);
    
    % Open hamd
    fprintf (u, 'O10');
    pause (3)
    
    % Move the robot to home position
    movePTPJointSpace(t, HomePosition_JointSpace, Velocity_Rel);
    
    close all

end

net_turnOffServer (t);
fclose (u);