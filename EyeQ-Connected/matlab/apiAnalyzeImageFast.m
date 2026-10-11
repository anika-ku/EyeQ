function resultJson = apiAnalyzeImageFast(imagePath, outputDir)
%APIANALYZEIMAGEFAST Fast screening path: quality + fundus check + DR prediction.
% Intentionally skips Grad-CAM, lesion detection and overlay generation.
if nargin < 2 || isempty(outputDir), outputDir = fileparts(imagePath); end
if ~isfolder(outputDir), mkdir(outputDir); end
addpath(fileparts(mfilename('fullpath')));

persistent net classNames isDemoModel
[net, classNames, isDemoModel] = getCachedModel(net, classNames, isDemoModel);
displayNames = {'No DR','Mild NPDR','Moderate NPDR','Severe NPDR','Proliferative DR'};

original = imread(imagePath);
[qScore, qMsg, qOK] = assessImageQuality(original);
[isFundus, fundusConf, fundusReason] = isLikelyFundusImage(original);
[processed, ~, ~] = preprocessFundusImage(original, [224 224]);
[~, classIdx, ~, sortedScores, sortedNames] = predictDR(net, processed, classNames);
drLevel = classIdx - 1;
label = displayNames{min(classIdx,numel(displayNames))};
confidence = sortedScores(1);
referable = drLevel >= 2;

probs = zeros(1,numel(classNames));
for k=1:numel(classNames)
    idx=find(strcmp(sortedNames,classNames{k}),1);
    if ~isempty(idx), probs(k)=sortedScores(idx); end
end

result = struct();
result.label = label;
result.drLevel = double(drLevel);
result.confidence = double(confidence);
result.severity = lower(strrep(label,' ','-'));
result.referable = logical(referable);
result.summary = sprintf('%s predicted. This is an AI screening aid and requires clinician review; it is not a diagnosis.', label);
result.demoModel = logical(isDemoModel);
result.qualityScore = double(qScore);
result.qualityMessage = qMsg;
result.qualityAcceptable = logical(qOK);
result.fundusCheck = struct('isFundus',logical(isFundus),'confidence',double(fundusConf),'reason',fundusReason);
result.classProbabilities = probs;
result.analysisMode = 'fast';
resultJson = writeResult(result, outputDir);
end

function [net, classNames, isDemoModel] = getCachedModel(net, classNames, isDemoModel)
classNamesDefault = {'Level0_NoDR','Level1_Mild','Level2_Moderate','Level3_Severe','Level4_Proliferative'};
if isempty(net)
    classNames = classNamesDefault;
    modelPath = fullfile(fileparts(mfilename('fullpath')), 'trainedDRNet.mat');
    isDemoModel = true;
    if isfile(modelPath)
        s = load(modelPath);
        if isfield(s,'net'), net = s.net; else, error('trainedDRNet.mat does not contain variable net.'); end
        if isfield(s,'classNames'), classNames = s.classNames; end
        isDemoModel = false;
    else
        lgraph = buildDRModel(numel(classNames), [224 224 3], classNames);
        lgraph = removeLayers(lgraph, 'classoutput_dr');
        net = dlnetwork(lgraph);
    end
end
end

function resultJson = writeResult(result, outputDir)
resultJson = jsonencode(result);
fid=fopen(fullfile(outputDir,'result.json'),'w');
if fid < 0, error('Could not write result.json'); end
cleanup=onCleanup(@() fclose(fid));
fwrite(fid,resultJson,'char');
end
