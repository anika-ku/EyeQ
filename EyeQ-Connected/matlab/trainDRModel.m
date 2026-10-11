%% trainDRModel.m
% ---------------------------------------------------------------------
% Training script for the Diabetic Retinopathy severity classifier.
%
% Run this SEPARATELY (offline, ideally with a GPU) once a labelled
% fundus dataset is available. It is NOT called automatically by the
% app - the app only *loads* the resulting trainedDRNet.mat if present,
% and otherwise falls back to an untrained demo model.
%
% Recommended public datasets (check licence/usage terms before use):
%   - APTOS 2019 Blindness Detection (Kaggle)
%   - EyePACS Diabetic Retinopathy Detection (Kaggle)
%   - IDRiD - Indian Diabetic Retinopathy Image Dataset (good fit for
%     your "rural India" framing - it's actually Indian clinical data)
%   - Messidor-2
%
% Expected folder layout (imageDatastore, labelled by folder name):
%   datasetRoot/
%       0_NoDR/            *.jpg / *.png
%       1_Mild/
%       2_Moderate/
%       3_Severe/
%       4_Proliferative/
% ---------------------------------------------------------------------

clear; clc;

%% 1. Point this at your dataset -----------------------------------------
datasetRoot = fullfile(pwd, 'dataset');   % <-- EDIT THIS

if ~isfolder(datasetRoot)
    error(['Dataset folder not found: %s\n' ...
           'Download a DR dataset (see comments above), organise it into ' ...
           'class subfolders, and point datasetRoot at it.'], datasetRoot);
end

imds = imageDatastore(datasetRoot, ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

classNames = categories(imds.Labels);
numClasses = numel(classNames);
fprintf('Found %d images across %d classes: %s\n', ...
    numel(imds.Files), numClasses, strjoin(string(classNames), ', '));

%% 2. Train / validation split --------------------------------------------
[imdsTrain, imdsVal] = splitEachLabel(imds, 0.85, 'randomized');

inputSize = [224 224 3];

% Address class imbalance (very common in DR datasets - "No DR" usually
% dominates heavily) with an inverse-frequency weighted loss.
labelCounts = countEachLabel(imdsTrain);
classWeights = numel(imdsTrain.Files) ./ (numClasses * labelCounts.Count);

%% 3. Data augmentation ------------------------------------------------------
augmenter = imageDataAugmenter( ...
    'RandRotation', [-15 15], ...
    'RandXReflection', true, ...
    'RandXTranslation', [-10 10], ...
    'RandYTranslation', [-10 10], ...
    'RandScale', [0.9 1.1]);

augImdsTrain = augmentedImageDatastore(inputSize, imdsTrain, ...
    'ColorPreprocessing', 'gray2rgb', 'DataAugmentation', augmenter);
augImdsVal = augmentedImageDatastore(inputSize, imdsVal, ...
    'ColorPreprocessing', 'gray2rgb');

%% 4. Build network ------------------------------------------------------------
lgraph = buildDRModel(numClasses, inputSize, classNames);

% Swap in a class-weighted classification layer to help with imbalance.
lgraph = replaceLayer(lgraph, 'classoutput_dr', ...
    classificationLayer('Name', 'classoutput_dr', ...
    'Classes', classNames, 'ClassWeights', classWeights));

%% 5. Training options ----------------------------------------------------------
options = trainingOptions('adam', ...
    'InitialLearnRate', 3e-4, ...
    'MaxEpochs', 15, ...
    'MiniBatchSize', 32, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData', augImdsVal, ...
    'ValidationFrequency', 30, ...
    'Verbose', true, ...
    'Plots', 'training-progress', ...
    'ExecutionEnvironment', 'auto');   % uses GPU automatically if available

%% 6. Train ------------------------------------------------------------------------
[net, trainInfo] = trainNetwork(augImdsTrain, lgraph, options); %#ok<ASGLU>

%% 7. Quick validation report -------------------------------------------------------
predLabels = classify(net, augImdsVal);
trueLabels = imdsVal.Labels;
acc = mean(predLabels == trueLabels);
fprintf('Validation accuracy: %.2f%%\n', acc*100);

figure; confusionchart(trueLabels, predLabels);
title('DR Severity - Validation Confusion Matrix');

%% 8. Save for the app ----------------------------------------------------------------
save('trainedDRNet.mat', 'net', 'classNames');
fprintf('Saved trainedDRNet.mat - copy it into the app folder and restart the app.\n');
