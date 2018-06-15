% Name:     Train Network
% Purpose:  Features extracted from the images acquired with the Kinect
%           sensor are used to train an Artificial Neural Network

% Author:   André Brás
% Created:  12/06/2018

%%  Changeable Properties

% Script initialization
close all; clear; clc;

% Set the desired objects from the YCB Object and Model Set
Objects = {};   Objects {1, 1} = 'chips_can';
                Objects {1, 2} = 'master_chef_can';
                Objects {1, 3} = 'cracker_box';
                Objects {1, 4} = 'sugar_box';
                Objects {1, 5} = 'tomato_soup_can';
                Objects {1, 6} = 'mustard_bottle';
                Objects {1, 7} = 'gelatin_box';
                Objects {1, 8} = 'potted_meat_can';
                Objects {1, 9} = 'apple';
                Objects {1, 10} = 'lemon';
                Objects {1, 11} = 'peach';
                Objects {1, 12} = 'orange';
                Objects {1, 13} = 'plum';
                Objects {1, 14} = 'pitcher_base';
                Objects {1, 15} = 'bleach_cleanser';
                Objects {1, 16} = 'bowl';
                Objects {1, 17} = 'wood_block';
                Objects {1, 18} = 'softball';
                Objects {1, 19} = 'baseball';
                Objects {1, 20} = 'tennis_ball';
                
% Set 'Start' equal to 1 if you want use both color and visual features or
% equal to 4 if you intend to only use color features
Start = 4;

% Set the percentages to split data into training, validation and test sets
trainRatio = 70/100; valRatio = 15/100; testRatio = 15/100;

%%  Preallocation of Variables

trainInd = []; valInd = []; testInd = [];

Inputs = []; Outputs = [];

%%  Main

% Load features extracted from the images acquired with the Kinect sensor
load ('Kinect_Features.mat')

% For each object, used the percentages defined above and split data into
% training, validation and test sets randomly
for i = 1 : numel (Features)
    
    Data = Features {i} (:, Start : end); Samples = size (Data, 1);
    Indices = randperm (Samples) + size (Inputs, 1);
    
    Aux = Indices (1 : floor (Samples * trainRatio));
    trainInd = [trainInd, Aux];
    
    Aux = Indices (floor (Samples * trainRatio + 1) : ...
        floor (Samples * (trainRatio + valRatio)));
    valInd = [valInd, Aux];
    
    Aux = Indices (floor (Samples * (trainRatio + valRatio) + 1) : end);
    testInd = [testInd, Aux];
    
    Targets = zeros (Samples, numel (Objects)); Targets (:, i) = 1;
    
    Inputs = [Inputs; Data]; Outputs = [Outputs; Targets];
    
end

x = Inputs'; t = Outputs';

% Choose a Training Function
% For a list of all training functions type: help nntrain
% 'trainlm' is usually fastest.
% 'trainbr' takes longer but may be better for challenging problems.
% 'trainscg' uses less memory. Suitable in low memory situations.
trainFcn = 'trainscg';  % Scaled conjugate gradient backpropagation.

% Create a Pattern Recognition Network
hiddenLayerSize = [20 20];
net = patternnet(hiddenLayerSize, trainFcn);

% Set up Division of Data for Training, Validation, Testing
net.divideFcn = 'divideind';

net.divideParam.trainInd = trainInd;
net.divideParam.valInd = valInd;
net.divideParam.testInd = testInd;

net.layers {1}.transferFcn = 'logsig';
net.layers {2}.transferFcn = 'logsig';

% Train the Network
[net, tr] = train (net, x, t);

% Test the Network
y = net (x);
e = gsubtract (t, y);
performance = perform(net, t, y)
tind = vec2ind (t);
yind = vec2ind (y);
percentErrors = sum(tind ~= yind) / numel(tind);

% View the Network
view (net)

% Save the Network
save ('Train_Network_Color_3.mat', 'net');

% Creat and Plot the Confusion Matrix
testOutputs = Outputs (testInd', :);
groundTruth = vec2ind (testOutputs');
groundTruth = groundTruth';

testInputs = Inputs (testInd', :);
y = net (testInputs');
[~, predictions] = max (y);
predictions = predictions';

confusionMatrix = confusionmat (groundTruth, predictions);

imagesc (confusionMatrix);
colormap (flipud (gray));

textStrings = num2str (confusionMatrix (:), '%i');
textStrings = strtrim (cellstr(textStrings));
idx = find (strcmp (textStrings(:), '0'));
textStrings(idx) = {' '};
[x, y] = meshgrid (1 : numel (Objects));
hStrings = text(x (:), y (:), textStrings (:), 'FontSize', 9, ...
    'HorizontalAlignment', 'center');
midValue = mean (get (gca, 'CLim'));
textColors = repmat (confusionMatrix (:) > midValue, 1, 3);
set(hStrings, {'Color'}, num2cell(textColors, 2));

ticks = [0.0 9.0 18.0 27.0 36.0 45.0];
caxis ([0.0 45.0])
colorbar ('FontSize', 11, 'YTick', ticks, 'YTickLabel', ticks);

set (gca, 'XTick', 1 : 20, 'XTickLabel', {'chips can', ...
    'master chef can', 'cracker box', 'sugar box', 'tomato soup can', ...
    'mustard bottle', 'gelatin box', 'potted meat can', 'apple', ...
    'lemon', 'peach', 'orange', 'plum', 'pitcher base', ...
    'bleach cleanser', 'bowl', 'wood block', 'softball', 'baseball', ...
    'tennis ball'}, 'XTickLabelRotation', 60, 'YTick', 1 : 20, ...
    'YTickLabel', {'chips can', 'master chef can', 'cracker box', ...
    'sugar box', 'tomato soup can', 'mustard bottle', 'gelatin box', ...
    'potted meat can', 'apple', 'lemon', 'peach', 'orange', 'plum', ...
    'pitcher base', 'bleach cleanser', 'bowl', 'wood block', ...
    'softball', 'baseball', 'tennis ball'},'YTickLabelRotation', 30)

ylabel ('Ground Truth', 'FontSize', 12, 'FontWeight', 'Bold')
xlabel ('Prediction', 'FontSize', 12, 'FontWeight', 'Bold')