function [riskScore, suggestion] = lesionBasedRiskScore(lesionResults)
%LESIONBASEDRISKSCORE Simple statistical cross-check, independent of the CNN.
%
%   [riskScore, suggestion] = lesionBasedRiskScore(lesionResults)
%
%   Combines lesion counts into a single 0-100 "lesion burden" score
%   using normcdf() (Statistics and Machine Learning Toolbox) to convert
%   standardised lesion counts into probability-style contributions.
%
%   This is a SECOND, INDEPENDENT signal an ophthalmologist can use to
%   sanity-check the CNN's referable/non-referable decision - if the two
%   disagree, that disagreement is itself useful explainability
%   information ("the AI says non-referable, but lesion evidence says
%   otherwise - please look closer").
%
%   NOTE: The reference mean/std below are illustrative placeholders for
%   demonstration. Calibrate them against your own dataset's lesion
%   statistics before relying on this for anything beyond a hackathon
%   demo.

    counts = [lesionResults.microaneurysms.count, ...
              lesionResults.hemorrhages.count, ...
              lesionResults.exudates.count, ...
              double(lesionResults.neovascularization.suspected) * 10];

    % Illustrative reference mean/std for a "typical mild" case
    refMean = [2, 1, 1, 0];
    refStd  = [3, 2, 2, 1];

    z = (counts - refMean) ./ refStd;
    p = normcdf(z);                 % Statistics and Machine Learning Toolbox

    weights = [0.25 0.35 0.20 0.20];
    combined = sum(p .* weights) / sum(weights);   % 0-1

    riskScore = round(100 * combined);
    riskScore = max(0, min(100, riskScore));

    if riskScore >= 40
        suggestion = 'Lesion burden suggests REFERABLE - corroborates further review.';
    else
        suggestion = 'Lesion burden suggests non-referable range.';
    end
end
