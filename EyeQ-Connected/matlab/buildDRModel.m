function net = buildDRModel(numClasses, inputSize, classNames)
%BUILDDRMODEL Build a transfer-learning CNN for 5-class DR grading.
%
%   net = buildDRModel(numClasses, inputSize, classNames)
%
%   Uses ResNet-18 (small, fast, works well for hackathon-scale training
%   on a laptop GPU/CPU) pretrained on ImageNet as the backbone, and
%   replaces the final fully-connected + classification layers with new
%   ones sized for the 5-level DR grading task.
%
%   Returns an UNTRAINED (freshly-headed) layerGraph. Train it with
%   trainDRModel.m on a labelled DR dataset (APTOS 2019, EyePACS, IDRiD,
%   Messidor-2) before using it for real predictions. Until trained,
%   only the ImageNet backbone weights are meaningful - the new head is
%   randomly initialised, so the assembled network is only useful for
%   demonstrating the pipeline end-to-end, not for real classification.
%
%   Requires: Deep Learning Toolbox + "Deep Learning Toolbox Model for
%   ResNet-18 Network" support package (installable via Add-On Explorer).

    if nargin < 1 || isempty(numClasses), numClasses = 5; end
    if nargin < 2 || isempty(inputSize),  inputSize  = [224 224 3]; end
    if nargin < 3 || isempty(classNames)
        classNames = arrayfun(@(i) sprintf('Level%d', i-1), 1:numClasses, 'UniformOutput', false);
    end

    try
        baseNet = resnet18;   % pretrained ImageNet weights, if the support package is installed
        lgraph = layerGraph(baseNet);
    catch
        % "Deep Learning Toolbox Model for ResNet-18 Network" support package
        % not installed. Fall back to the untrained architecture - this is
        % enough to demonstrate the full pipeline (forward pass, Grad-CAM,
        % etc.), just without ImageNet-pretrained backbone features.
        % Note: resnet18('Weights','none') returns a layerGraph directly
        % (not a DAGNetwork), so it must NOT be passed through layerGraph()
        % again.
        warning(['ResNet-18 pretrained weights not installed - using untrained ' ...
            'architecture instead. Install the "Deep Learning Toolbox Model for ' ...
            'ResNet-18 Network" support package via Add-On Explorer for better ' ...
            'transfer-learning results once you train on real DR data.']);
        lgraph = resnet18('Weights', 'none');
    end

    newFC = fullyConnectedLayer(numClasses, 'Name', 'fc_dr', ...
        'WeightLearnRateFactor', 10, 'BiasLearnRateFactor', 10);
    newClassLayer = classificationLayer('Name', 'classoutput_dr', 'Classes', classNames);

    lgraph = replaceLayer(lgraph, 'fc1000', newFC);
    lgraph = replaceLayer(lgraph, 'ClassificationLayer_predictions', newClassLayer);

    net = lgraph;
end
