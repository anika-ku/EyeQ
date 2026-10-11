function [qualityScore, qualityMsg, isAcceptable] = assessImageQuality(img)
%ASSESSIMAGEQUALITY Heuristic quality check for a fundus image.
%
%   [qualityScore, qualityMsg, isAcceptable] = assessImageQuality(img)
%
%   Combines three fast indicators commonly used in fundus QC:
%       - Brightness   (mean luminance should be in a reasonable range)
%       - Contrast     (std of luminance; low std => washed out image)
%       - Sharpness    (variance of Laplacian; low => blurred / out of focus)
%
%   This is a lightweight, demonstration-grade quality gate - NOT a
%   substitute for a dedicated image-quality-assessment network. It is
%   meant to flag obviously unusable rural-camera captures before they
%   reach the classifier.
%
%   Outputs:
%       qualityScore - 0-100 composite score
%       qualityMsg   - human readable explanation
%       isAcceptable - logical, true if score >= 50

    gray = im2double(rgb2gray(img));

    brightness = mean(gray(:)) * 255;               % 0-255
    contrastVal = std(gray(:)) * 255;                % 0-255
    lap = fspecial('laplacian');
    sharpness = var(imfilter(gray, lap, 'replicate'), 0, 'all') * 1e4;

    brightnessScore = 100 - min(100, abs(brightness - 130) * 1.2);
    contrastScore   = min(100, contrastVal * 3);
    sharpnessScore  = min(100, sharpness * 8);

    qualityScore = round(0.35*brightnessScore + 0.35*contrastScore + 0.30*sharpnessScore);
    qualityScore = max(0, min(100, qualityScore));

    isAcceptable = qualityScore >= 50;

    if qualityScore >= 75
        qualityMsg = sprintf('Good image quality (%d/100).', qualityScore);
    elseif qualityScore >= 50
        qualityMsg = sprintf('Acceptable quality (%d/100) - usable but not ideal.', qualityScore);
    else
        qualityMsg = sprintf(['Poor quality (%d/100) - image may be too dark, ' ...
            'low-contrast or blurred. Consider re-capturing.'], qualityScore);
    end
end
