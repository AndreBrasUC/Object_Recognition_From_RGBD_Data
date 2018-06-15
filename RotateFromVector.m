function [RotatedCloud, varargout] = RotateFromVector (Cloud, V1, V2, ...
    varargin)

%   ROTATEFROMVECtor creates an affine transformation matrix from two
%   vectors, which represent the normal of the planes that are to be
%   aligned. Then, the point cloud is rotated and translated according to
%   this matrix

%%	Inputs

%   Cloud       Input point cloud
%   V1          Normal vector of the original orientation
%   V2          Normal vector of the new orientation

%   varargin
%   T           Translation vector, containing the translation distance

%%	Outputs

%   RotatedCloud    Rotated point cloud

%   varargout
%   Matrix          Affine transformation matrix
%   Axis            Axis about which the rotation is executed
%   Angle           Angle of rotation about the Axis.

%%  Input Parsing

if nargin == 3, T = zeros (1, 3);
elseif nargin == 4, T (1, 1 : 3) = varargin {1};
elseif nargin > 4, error (message ('MATLAB:narginchk:tooManyInputs'));
end

%%  Creation of Affine Transformation Function

Orientations (1, 1 : 3) = V1;
Orientations (2, 1 : 3) = V2;

Rotation = vrrotvec (Orientations (1, :), Orientations (2, :));
Axis = Rotation (1 : 3);
Angle = Rotation (4);

Matrix = vrrotvec2mat (Rotation); Matrix (4, 1 : 4) = [(T(:))' 1];
Matrix = affine3d (Matrix);

RotatedCloud = pctransform (Cloud, Matrix);

%%  Output Parsing

if nargout >= 2, varargout {1} = Matrix; end
if nargout >= 3, varargout {2} = Axis; end
if nargout == 4, varargout {3} = Angle; end
if nargout > 4, error (message ('MATLAB:nargoutchk:tooManyOutputs')); end

end