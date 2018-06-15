function [Models, Qualities, Inliers] = FitPrimitiveShapes ( ...
    Cluster, Runs, Fit, Plot)

%   FUNCTOFITPRIMITIVESHAPES fits primitive geometric shapes to the input
%   cluster, which is a group of points represeting only one object

%%	Inputs

%   Cluster     Input point cloud with one cluster
%   Runs        Number of runs performed for shape fitting
%   Fit         Primitive geometric shapes that will be fitted
%   Plot        Use 'Yes' to plot the main figures and 'No' to ignore them

%%	Outputs

%   Models      Best model, if exists, of each primitive shape fitted
%   Qualities   Quality of the fitting of each primitive shape, if exists
%   Inliers     Points from cluster that are included by primitive shapes

%%  Changeable Properties

% Set the maximum allowable distance from an inlier point to each shape.
% Set also the maximum angular distance between a fitted plane and the
% corresponding reference orientation
MaxDistanceCyl = 0.0075;
MaxDistanceSph = 0.0050;
MaxDistancePln = 0.0050;
MaxAngularDistance = 5;

% Parameters that define the accuracy of plane fitting
MaxNumTrials = 1000;    % Maximum number of trials for finding inliers
Confidence = 99.9;      % Confidence percentage for finding inliers

%%  Input Parsing

FitCylinder = 0;
FitSphere = 0;
FitPrism = 0;

for i = 1 : size (Fit, 1)
    switch  (Fit {i})
        case 'Cylinder',    FitCylinder = 1;
        case 'Sphere',      FitSphere = 1;
        case 'Prism',       FitPrism = 1;
        case 'All',         FitCylinder = 1; FitSphere = 1; FitPrism = 1;
    end
end

warning ('off', 'all')

%%  Preallocation of Variables and Thresholds Definition

ModelCyl = [];
ModelSph = [];
ModelPln = [];

InlierIndicesCyl = [];
InlierIndicesSph = [];
InlierIndicesPln = [];

QualityCyl = 0;
QualitySph = 0;
QualityPln = 0;

Coordinates = Cluster.Location;
Limits = [Cluster.XLimits; Cluster.YLimits; Cluster.ZLimits];
Size (1 : 3, 1) = Limits (1 : 3, 2) - Limits (1 : 3, 1);
MaxRadius = max (Size) / 2;

%%  Cylinder Fitting

if FitCylinder == 1

    % Fit a cylinder to the cluster of points
    for i = 1 : Runs
        [Model, InlierIndices] = pcfitcylinder (Cluster, ...
            MaxDistanceCyl, 'MaxNumTrials', MaxNumTrials, ...
            'Confidence', Confidence);
        % if Model.Radius > MaxRadius, Quality = 0;     % Training
        if Model.Radius > 2 * MaxRadius, Quality = 0;   % Testing
        else, Quality = numel (InlierIndices) / Cluster.Count; end
        if Quality > QualityCyl
            ModelCyl = Model;
            InlierIndicesCyl = InlierIndices;
            QualityCyl = Quality;
        end
    end

    if QualityCyl > 0 && strcmpi (Plot, 'Yes')
        
        Cylinder = select (Cluster, InlierIndicesCyl);
        
        figure ('Name', 'BEST CYLINDER FITTING', 'NumberTitle', 'off');
        MyAxes = pcshow (Cylinder.Location, 'r');
        hold on; plot (ModelCyl); hold off;
        
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
        
%         xlabel ('X [m]'); ylabel ('Y [m]'); zlabel ('Z [m]');
        
        title (sprintf (strcat ('Best Cylinder Fitting. Score: %0.4f'), ...
            QualityCyl));
        
    end

end

%%  Sphere Fitting

if FitSphere == 1

    % Fit a sphere to the cluster of points
    for i = 1 : Runs
        [Model, InlierIndices] = pcfitsphere (Cluster, MaxDistanceSph, ...
            'MaxNumTrials', MaxNumTrials, 'Confidence', Confidence);
        if Model.Radius > MaxRadius, Quality = 0;
        else, Quality = numel (InlierIndices) / Cluster.Count; end
        if Quality > QualitySph
            ModelSph = Model;
            InlierIndicesSph = InlierIndices;
            QualitySph = Quality;
        end
    end

    if QualitySph > 0 && strcmpi (Plot, 'Yes')
        
        Sphere = select (Cluster, InlierIndicesSph);
        
        figure ('Name', 'BEST SPHERE FITTING', 'NumberTitle', 'off');
        MyAxes = pcshow (Sphere.Location, 'r');
        hold on; plot (ModelSph); hold off;
        
        MyAxes.XTick = [-0.3 -0.2 -0.1 0 0.1 0.2 0.3];
        MyAxes.XTickLabelMode = 'manual';
        MyAxes.XTickLabel = {'', '', '', '', '', '', ''};

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
        
%         xlabel ('X [m]'); ylabel ('Y [m]'); zlabel ('Z [m]');
        
        title (sprintf (strcat ('Best Sphere Fitting. Score: %0.4f'), ...
            QualitySph));
        
    end

end

%%  Prism Fitting

if FitPrism == 1

% Compute reference vectors for plane fitting
[~, P1] = min (Coordinates (:, 3)); P1 = Coordinates (P1, :);
[~, P2] = max (Coordinates (:, 1)); P2 = Coordinates (P2, :);
[~, P3] = min (Coordinates (:, 1)); P3 = Coordinates (P3, :);
[~, P4] = max (Coordinates (:, 3)); P4 = Coordinates (P4, :);
[~, P5] = max (Coordinates (:, 2)); P5 = Coordinates (P5, :);
[~, P6] = min (Coordinates (:, 2)); P6 = Coordinates (P6, :);

for i = 1 : Runs
    % Try to fit a rectangular prism to the object. To do so, the frontal
    % top planes should be fitted in first place. Realize that the top
    % plane should near the top of the object
    [ModelFrontal, InlierIndicesFrontal, OutlierIndicesFrontal] = ...
        pcfitplane (Cluster, MaxDistancePln, 'MaxNumTrials', ...
        MaxNumTrials, 'Confidence', Confidence);
    
    SampleIndices = findPointsInROI (Cluster, [-inf, inf; ...
        (Limits (2, 1)), (Limits (2, 1) + Size (2) / 3); -inf, inf]);
    [ModelTop, InlierIndicesTop] = pcfitplane (Cluster, ...
        MaxDistancePln, [0, 1, 0], MaxAngularDistance, ...
        'SampleIndices', SampleIndices);
    % If doesn't exist a top plane, create a horizontal plane containing
    % the point with the higher Y coordinate
    if isempty (ModelTop)
        ModelTop = planeModel ([0, 1, 0, (-P6 (2))]);
    end
    
    % Retrieve the unique values of inliers and compute model quality
    InlierIndices = [InlierIndicesFrontal; InlierIndicesTop];
    InlierIndices = unique (InlierIndices);
    Quality = numel (InlierIndices) / Cluster.Count;
    
    % If it was possible to fit the frontal and top planes, the system
    % admits that the object can be rough by a prism. In this case, the
    % remaining planes should be determined to compute the object's volume
    if ~ isempty (InlierIndices) && ~ isempty (OutlierIndicesFrontal) ...
            && Quality > QualityPln
        % The back plane is parallel to the frontal plane and contains the
        % farthest point from this plane. So, this farthest point needs to
        % be computed
        ParamFrontal = ModelFrontal.Parameters;
        MaxDistance = 0;
        for j = 1 : numel (OutlierIndicesFrontal)
            Point = Coordinates (OutlierIndicesFrontal (j), :);
            Distance = abs (dot (ParamFrontal (1 : 3), Point) + ...
                ParamFrontal (4)) / norm (ParamFrontal (1 : 3));
            if Distance > MaxDistance
                MaxDistance = Distance;
                FarthestPoint = Point;
            end
        end
        D = - (ParamFrontal (1) * FarthestPoint (1) + ...
            ParamFrontal (2) * FarthestPoint (2) + ...
            ParamFrontal (3) * FarthestPoint (3));
        ModelFrontalBack = planeModel ([ParamFrontal(1), ...
            ParamFrontal(2), ParamFrontal(3), D]);
        
        % The left vertical plane is perpendicular to frontal and back
        % planes and contains the most left point. The opposite plane,
        % which is the right vertical plane is parallel to the previous
        % plane and contains the most right point
        ParamLeftRight = [(ParamFrontal (3)), 0, (- ParamFrontal (1))];
        D = - (ParamLeftRight (1) * P3 (1) + ParamLeftRight (3) * P3 (3));
        ModelFrontalLeft = planeModel ([ParamLeftRight, D]);
        
        D = - (ParamLeftRight (1) * P2 (1) + ParamLeftRight (3) * P2 (3));
        ModelFrontalRight = planeModel ([ParamLeftRight, D]);
        
        % The floor plane is parallel to the top plane, but contain the
        % point with lowest Y coordinate
        ParamFloor = ModelTop.Parameters;
        D = - (ParamFloor (1) * P5 (1) + ParamFloor (2) * P5 (2) + ...
            ParamFloor (3) * P5 (3));
        ModelFloor = planeModel ([(ParamFloor (1 : 3)), D]);
        
    end
    if Quality > QualityPln && ~ isempty (OutlierIndicesFrontal)
        ModelPln = {ModelFrontal; ModelFrontalBack; ...
            ModelFrontalLeft; ModelFrontalRight; ModelTop; ModelFloor};
        InlierIndicesPln = InlierIndices;
        QualityPln = Quality;
    end
end

if QualityPln > 0 && strcmpi (Plot, 'Yes')
    
        Prism = select (Cluster, InlierIndicesPln);
        
        figure ('Name', 'BEST PRISM FITTING', 'NumberTitle', 'off');
        MyAxes = pcshow (Prism.Location, 'g');
        
        XLimits (1) = Prism.XLimits (1) - 0.25 * (Prism.XLimits (2) - ...
            Prism.XLimits (1));
        XLimits (2) = Prism.XLimits (2) + 0.25 * (Prism.XLimits (2) - ...
            Prism.XLimits (1));
        YLimits (1) = Prism.YLimits (1) - 0.25 * (Prism.YLimits (2) - ...
            Prism.YLimits (1));
        YLimits (2) = Prism.YLimits (2) + 0.25 * (Prism.YLimits (2) - ...
            Prism.YLimits (1));
        ZLimits (1) = Prism.ZLimits (1) - 0.25 * (Prism.ZLimits (2) - ...
            Prism.ZLimits (1));
        ZLimits (2) = Prism.ZLimits (2) + 0.25 * (Prism.ZLimits (2) - ...
            Prism.ZLimits (1));
        
        MyAxes.XLim = XLimits;
        MyAxes.YLim = YLimits;
        MyAxes.ZLim = ZLimits;
        
        hold on; plot (ModelPln {1}); plot (ModelPln {5}); hold off;
        
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
        
%         xlabel ('X [m]'); ylabel ('Y [m]'); zlabel ('Z [m]');
        
        title (sprintf (strcat ('Best Prism Fitting. Score: %0.4f'), ...
            QualityPln));
        
end

end

%%  Output Parsing

Models = {ModelCyl; ModelSph; ModelPln};
Qualities = [QualityCyl; QualitySph; QualityPln];
Inliers = {InlierIndicesCyl; InlierIndicesSph; InlierIndicesPln};

end