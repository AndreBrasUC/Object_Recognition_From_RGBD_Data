% Name:     ObjectRecognitionYCB_Train
% Purpose:  Use the YCB Object and Model Set to collect shape and visual
%           features from RGB-D. These features will be used to train a
%           network, which is intended to be able to accurately recognize
%           common objects

% Author:   André Brás
% Created:  30/03/2018

%%  Changeable Properties

% Script initialization
close all; clear; clc;

% Use 'Yes' to plot the main figures and 'No' to ignore them
Plot = 'Yes';

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
                
% The point cloud includes irrelevant data. They can be trimmed based on
% the rough knowledge of the configuration between the turntable and the
% camera. The idea is to remove most of the background by taking only the
% points within a 3D bounding box where it is expected to find the
% turntable and the camera
Shape = 'Prism';                    % Geometric shape of the cloud
Center = [-0.20 -0.20 0.75];        % XYZ coordinates of the center
Dimensions = [0.20 0.30 0.30];      % Size of the output cloud

% Since the turntable's plane is removed, it is expected that only
% significant clusters and a few outliers are included. The search for
% regions of interest will allow the extraction of the ouliers and the
% segmentation of objects
Type = 'Dimensions';    % Type of data to split the grid in small cells
Values = [0.01, 0.01];  % Array including the size of cell along each axis
Mode = 'Height';        % 'Height' to count points in vertical columns and
                        % 'Depth' in columns with the depth direction.
                        
% At the end, primitive geometric shapes are fitted to the cluster, which
% allows the extraction of three shape features, namely the geometric
% shape, the corresponding fitting score and the volume of the object
Runs = 100;             % Number of runs performed for shape fitting

% Since, in this stage, it is known which object is being processed, it is
% possible to fit only the geometric shape that logically best fits to the
% object. If the object doesn't resemble a primitive shape, can use 'All'
Fit = {};       Fit {1} = {'Cylinder'};
                Fit {2} = {'Cylinder'};
                Fit {3} = {'Prism'};
                Fit {4} = {'Prism'};
                Fit {5} = {'Cylinder'};
                Fit {6} = {'Cylinder'; 'Prism'};
                Fit {7} = {'Prism'};
                Fit {8} = {'Prism'};
                Fit {9} = {'Cylinder'; 'Sphere'};
                Fit {10} = {'Cylinder'; 'Sphere'};
                Fit {11} = {'Cylinder'; 'Sphere'};
                Fit {12} = {'Cylinder'; 'Sphere'};
                Fit {13} = {'Cylinder'; 'Sphere'};
                Fit {14} = {'Cylinder'};
                Fit {15} = {'Cylinder'; 'Prism'};
                Fit {16} = {'Cylinder'; 'Sphere'};
                Fit {17} = {'Prism'};
                Fit {18} = {'Cylinder'; 'Sphere'};
                Fit {19} = {'Cylinder'; 'Sphere'};
                Fit {20} = {'Cylinder'; 'Sphere'};

%%  Initialization

% Variables to locate essential files
Folder = cd;
SetFolder = 'YCB_Object_Model_Set';

% Available cameras and positions
ViewptCam_RGB = {'N2', 'N3'};
ViewptCam_RGBD = {'NP2', 'NP3'};
ViewptAng = string (linspace (0, 357, 120));

% Angles to perform the first rotation. These values are set with the
% knowledge of the position between the camera and the turntable
Rotation = [25 45];

Samples = numel (Objects) * numel (ViewptCam_RGB) * numel (ViewptAng);
Sample = 0;
Features = zeros (Samples, 18);

%%  Main Programming

% To any object
for Object = 1 : numel (Objects)
    
    % Variables to locate essential files
    HighResFolder = strcat (Objects {Object}, '_berkeley_rgb_highres');
    RGBDFolder = strcat (Objects {Object}, '_berkeley_rgbd');
    
    % Data that will be used to generate the point cloud
	InfoFolder = strcat (Folder, '\', SetFolder, '\', RGBDFolder, '\');
	InfoObject = Objects {Object};
    
    % To any camera
    for Cam = 1 : numel (ViewptCam_RGB)
        
        % Data that will be used to generate the point cloud
        InfoCamera = ViewptCam_RGBD {Cam};
        
        % To any angle
        for Ang = 1 : numel (ViewptAng)
            
            fprintf (strcat ('Object %i seen from camera %i and in', ...
                ' position %i is being processed!\n'), Object, Cam, Ang);
            
            % Data that will be used to generate the point cloud
            InfoAngle = char (ViewptAng (Ang));
            
            %%%%%%%%%%   SHAPE FEATURES   %%%%%%%%%%
            
            % Save the properties that will be used by the generator
            save ('ObjectProperties.mat', 'InfoFolder', 'InfoObject', ...
                'InfoCamera', 'InfoAngle')
            
            % Generate the point cloud and load it. Then, remove all the
            % invalid points, which are points with invalid position
            !C:/Python27/python ycb_generate_point_cloud.py
            PtCloud = strcat (SetFolder, '\', RGBDFolder, '\', ...
                Objects {Object}, '\clouds\pc_', ViewptCam_RGBD {Cam}, ...
                '_NP5_', ViewptAng (Ang), '.ply');
            
            PtCloud = pcread (PtCloud);
            PtCloud = PtCloud.removeInvalidPoints;
            
            % The point cloud is ready to be displayed
            if strcmpi (Plot, 'Yes')
                
                figure ('Name', 'ORIGINAL POINT CLOUD', ...
                    'NumberTitle', 'off');
                pcshow (PtCloud); title ('Original Point Cloud');
                xlabel ('X [m]'); ylabel ('Y [m]'); zlabel ('Z [m]');
                
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
            % Then, a fine tune rotation is executed by plane fitting
            Matrix = vrrotvec2mat ([1 0 0 (deg2rad (Rotation (Cam)))]);
            Matrix (4, 1 : 4) = [0 0 0 1];
            Matrix = affine3d (Matrix);
            RotatedCloud = pctransform (PtCloud, Matrix);
            
            ReferenceVector = [0 1 0];
            [RotatedCloud, ~, ~, ~] = RotatePointCloud (RotatedCloud, ...
                'No', ReferenceVector);
            
            if strcmpi (Plot, 'Yes')
                figure ('Name', 'ROTATED POINT CLOUD', ...
                    'NumberTitle', 'off');
                subplot (1, 2, 1); pcshow (PtCloud); view (3);
                title ('Point Cloud Before Rotation');
                xlabel ('X [m]'); ylabel ('Y [m]'); zlabel ('Z [m]');
                subplot (1, 2, 2); pcshow (RotatedCloud); view (3);
                title ('Point Cloud After Rotation');
                xlabel ('X [m]'); ylabel ('Y [m]'); zlabel ('Z [m]');
            end
            
            PtCloud = RemoveFloor(RotatedCloud, Plot);
            
            % Since the turntable's plane is removed, it is expected that
            % only significant clusters and a few outliers are included.
            % The search for regions of interest will allow the extraction
            % of the outliers and the segmentation of objects
            Clusters = FindROIs (PtCloud, 'Type', Type, 'Values', ...
                Values, 'Mode', Mode);
            
            % Check the number of clusters segmented. We know that there
            % is only one object on the turntable and, therefore, it is
            % only considered the object with the higher number of points
            if numel (Clusters) > 1
                
                Significance = [];
                
                for i = 1 : numel (Clusters)
                    
                    Cluster = Clusters {i};
                    Significance (i) = Cluster.Count;
                    
                end
                
                [~, BiggestCluster] = max (Significance);
                Cluster = Clusters {BiggestCluster};
                Cluster = {Cluster};
                
            else
                
                Cluster = Clusters;
                
            end
            
            % The point cloud of the object is ready to be displayed
            if strcmpi (Plot, 'Yes')
                figure ('Name', 'SEGMENTED POINT CLOUD', ...
                    'NumberTitle', 'off');
                subplot (1, 2, 1); pcshow (PtCloud); view (3);
                title ('Point Cloud Before Segmentation');
                xlabel ('X [m]'); ylabel ('Y [m]'); zlabel ('Z [m]');
                subplot (1, 2, 2); pcshow (Cluster {1}); view (3);
                title ('Point Cloud After Segmentation');
                xlabel ('X [m]'); ylabel ('Y [m]'); zlabel ('Z [m]');
            end
            
            % At the end, primitive geometric shapes are fitted to the
            % cluster, which allows the extraction of three shape features,
            % namely the geometric shape, the corresponding fitting score
            % and the estimated volume of the object. The function is also
            % able to output the geometric centre of the object
            [Geometry, Quality, Volume, ~] = ...
                ExtractShapeFeatures (Cluster, Runs, Fit {Object}, Plot);
            
            %%%%%%%%%%   VISUAL FEATURES   %%%%%%%%%%
            
            % Load the high resolution image to extract the main colours
            HighResIm = strcat (SetFolder, '\', HighResFolder, '\', ...
                Objects {Object}, '\', ViewptCam_RGB {Cam}, '_', ...
                ViewptAng (Ang), '.jpg');
            
            HighResIm = imread (char (HighResIm));
            
            % Search for the corresponding mask
            HighResMask = strcat (SetFolder, '\', HighResFolder, '\', ...
                Objects {Object}, '\masks\', ViewptCam_RGB {Cam}, '_', ...
                ViewptAng (31), '_mask.pbm');

            HighResMask = imread (char (HighResMask));
            
            % Search the limits of the object using the corresponding mask
            BorderTop = 0; BorderBottom = 0;
            BorderLeft = 0; BorderRight = 0;
            [NumRows, NumColumns] = size (HighResMask);
            
            for i = 1 : NumRows

                if ~ all (HighResMask (i, :) == 1) && BorderTop == 0
                    BorderTop = i;
                elseif ~ all (HighResMask (NumRows - i, :) == 1) && ...
                        BorderBottom == 0
                BorderBottom = NumRows - i;
                end

                if BorderTop ~= 0 && BorderBottom ~= 0, break; end

            end
            
            for i = 1 : NumColumns

                if ~ all (HighResMask (:, i) == 1) && BorderLeft == 0
                    BorderLeft = i;
                elseif ~ all (HighResMask (:, NumColumns - i) == 1) && ...
                        BorderRight == 0
                    BorderRight = NumColumns - i;
                end

                if BorderLeft ~= 0 && BorderRight ~= 0, break; end

            end
            
            NumRows = BorderBottom - BorderTop + 1;
            NumColumns = BorderRight - BorderLeft + 1;
            
            BorderTop = BorderTop + floor (0.10 * NumRows);
            BorderBottom = BorderBottom - floor (0.10 * NumRows);
            BorderLeft = BorderLeft + floor (0.10 * NumColumns);
            BorderRight = BorderRight - floor (0.10 * NumColumns);

            NumRows = BorderBottom - BorderTop + 1;
            NumColumns = BorderRight - BorderLeft + 1;
            
            % Since the margins of the object are already known, it is
            % possible to segment it
            HighResIm = HighResIm (BorderTop : BorderBottom, ...
                BorderLeft : BorderRight, :);
            
            % Reshape the image to a matrix where each line corresponds to
            % a pixel and the columns to the RGB channels
            HighResImShaped = double (reshape (HighResIm, ...
                [NumRows * NumColumns, 3]));
            
            % Extract the primary color and the three secondary colors
            [~, MainColor] = kmeans (HighResImShaped, 1);
            [Idx, SecondaryColors] = kmeans (HighResImShaped, 3);
            
            % Sort the secondary colors in descending order of importance
            Counts = [sum(Idx == 1), sum(Idx == 2), sum(Idx == 3)];
            
            if ~ issorted (flip (Counts))

                [~, Order] = sort (Counts, 'descend');
                SecondaryColors = SecondaryColors (Order, :);

            end
            
            if strcmpi (Plot, 'Yes')

                figure ('Name', 'VISUAL FEATURE EXTRACTION', ...
                    'NumberTitle', 'off');
                subplot (1, 5, 1); imshow (HighResIm); title ("Object")

                Color = [];
                Color (1, 1, 1 : 3) = MainColor;
                Color = repmat (uint8 (Color), 20);
                subplot (1, 5, 2); imshow (Color); title ("Main Color")

                for i = 1 : 3
                    Color = [];
                    Color (1, 1, 1 : 3) = SecondaryColors (i, :);
                    Color = repmat (uint8 (Color), 20);
                    subplot (1, 5, 2 + i); imshow (Color);
                    title (strcat ("Color ", string (i)));
                end

            end
            
            Sample = Sample + 1;
            
            % The first three columns are only for information. They are
            % not features
            Features (Sample, :) = [Object, Cam, Ang * 3 - 3, Geometry, ...
                Quality, Volume, MainColor, (SecondaryColors (1, :)), ...
                (SecondaryColors (2, :)), (SecondaryColors (3, :))];
            
        end
        
    end
    
    save ('ObjectRecognitionYCB_Features.mat', 'Features');
    
end

