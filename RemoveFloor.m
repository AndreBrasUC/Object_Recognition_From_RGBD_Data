function [TrimmedCloud]= RemoveFloor (Cloud, Plot)

%   REMOVEFLOOR checks the existence of a floor plane. If it is
%   present, the function removes it

%%	Inputs

%   Cloud       Input point cloud
%   Plot        Use 'Yes' to plot the main figures and 'No' to ignore them

%%	Outputs

%   TrimmedCloud    Output point cloud without the floor plane

%%  Changeable Properties

% Set the width of each bin of the histogram and the offset between the
% biggest bin and the bin used to trim the floor plane. During feature
% extraction, use an offset of 20, but raise it for 25/30 during testing
BinWidth = 0.001;
Offset = 30;

% Define the cloud height, in number of bins, below which the floor plane
% should be located. Use 10 bins during feature extraction and 100 bins
% durting testing
Threshold = 100;

%%  Searching for the Floor Plane

% To avoid fitting a plane to the chess table instead the real turntable,
% the search for the table is executed only on the initial bins
SampleIndices = findPointsInROI (Cloud, [-inf, inf; ...
    (Cloud.YLimits (2) - Threshold * BinWidth), (Cloud.YLimits (2));  ...
    -inf, inf]);
Plane = select (Cloud, SampleIndices);

% Create a histrogram to show the number of points between each pair of
% horizontal planes
Locations = Plane.Location;
Counts = histcounts (- Locations (:, 2), 'BinWidth', BinWidth);

% Locate the floor plane, knowing that it is the biggest provider of
% points. Add the offset and trim the floor by the trimming bin
[~, BiggestBin] = max (Counts);
TrimmingBin = BiggestBin + Offset;

Inliers = findPointsInROI (Cloud, [-inf, inf; -inf, ...
    (Cloud.YLimits (2) - TrimmingBin * BinWidth); -inf, inf]);
Outliers = findPointsInROI (Cloud, [-inf, inf; ...
    (Cloud.YLimits (2) - TrimmingBin * BinWidth), inf; -inf, inf]);

TrimmedCloud = select (Cloud, Inliers);
PlaneTrimmed = select (Cloud, Outliers);

%%  Plotting

if strcmpi (Plot, 'Yes')
    
    figure ('Name', 'HISTOGRAM OF POINTS AT Y''S NEGATIVE DIRECTION', ...
        'NumberTitle', 'off');
    plot (Counts);
    xlabel ('Bins'); ylabel ('Number of Points');
    
    figure ('Name', 'REMOVAL OF TABLE PLANE', 'NumberTitle', 'off');
    MyAxes = pcshow (TrimmedCloud);
    
    MyAxes.XTick = [-0.3 -0.2 -0.1 0 0.1 0.2 0.3];
    MyAxes.XTickLabelMode = 'manual';
    MyAxes.XTickLabel = {'', '', '', '', '', '', ''};
    
    MyAxes.YTick = [0 0.1 0.2 0.3 0.4 0.5];
    MyAxes.YTickLabelMode = 'manual';
    MyAxes.YTickLabel = {'', '', '', '', '', ''};
    
    MyAxes.ZTick = [0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 1.3 1.4 1.5];
    MyAxes.ZTickLabelMode = 'manual';
    MyAxes.ZTickLabel = {'', '', '', '', '', '', '', '', '', '', '', ...
        '', ''};

    MyAxes.CameraPositionMode = 'manual';
    MyAxes.CameraPosition = [-10, -25, -35];
    MyAxes.CameraUpVector = [0 -1 0];
    
%     print (gcf, '4_RemovalOfTablePlane.emf', ...
%         '-dmeta', '-r300', '-painters');
    
%     xlabel ('X [m]'); ylabel ('Y [m]'); zlabel ('Z [m]');
    
elseif strcmpi (Plot, 'Test')

    figure ('Name', 'HISTOGRAM OF POINTS AT Y''S NEGATIVE DIRECTION', ...
        'NumberTitle', 'off');
    plot (Counts);
    xlabel ('Bins'); ylabel ('Number of Points');
    
    figure ('Name', 'REMOVAL OF TABLE PLANE', 'NumberTitle', 'off');
    MyAxes = pcshow (TrimmedCloud);

    MyAxes.CameraPositionMode = 'manual';
    MyAxes.CameraPosition = [-10, -25, -35];
    MyAxes.CameraUpVector = [0 -1 0];
    
end

end