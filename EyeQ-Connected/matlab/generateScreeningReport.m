function reportStr = generateScreeningReport(info)
%GENERATESCREENINGREPORT Build a human-readable automated screening report.
%
%   reportStr = generateScreeningReport(info)
%
%   info fields expected:
%       .patientID          - string/char
%       .imageQuality       - struct with .score, .msg
%       .drLevel            - 0-4
%       .drLabel            - e.g. 'Moderate NPDR'
%       .referable          - logical
%       .confidence         - 0-100
%       .allScores          - 1x5 sorted probabilities
%       .allNames           - corresponding class names (sorted)
%       .lesions            - struct returned by detectLesions
%       .riskScore          - 0-100, from lesionBasedRiskScore
%       .riskSuggestion     - char, from lesionBasedRiskScore
%       .isDemoModel        - logical, true if network is untrained/demo

    ts = datestr(now, 'dd-mmm-yyyy HH:MM');

    lines = {};
    lines{end+1} = '=====================================================';
    lines{end+1} = '   AUTOMATED DIABETIC RETINOPATHY SCREENING REPORT';
    lines{end+1} = '=====================================================';
    lines{end+1} = sprintf('Generated: %s', ts);
    lines{end+1} = sprintf('Patient / Image ID: %s', info.patientID);
    lines{end+1} = '';

    if isfield(info, 'isFundus') && ~info.isFundus
        lines{end+1} = '*** WARNING: NOT LIKELY A FUNDUS PHOTO ***';
        lines{end+1} = sprintf('Fundus-likeness confidence: %d%%', info.fundusConfidence);
        lines{end+1} = info.fundusReason;
        lines{end+1} = 'All results below should be disregarded until the correct image is uploaded.';
        lines{end+1} = '';
    end

    if info.isDemoModel
        lines{end+1} = '*** DEMONSTRATION MODE ***';
        lines{end+1} = ['The classification network is running on ImageNet-pretrained ' ...
                         'weights only and has NOT been trained/validated on diabetic ' ...
                         'retinopathy data. Predictions below illustrate the ' ...
                         'EXPLAINABILITY PIPELINE end-to-end and must NOT be interpreted ' ...
                         'as a clinically valid diagnosis. Train the model with ' ...
                         'trainDRModel.m on a real DR dataset before any clinical or ' ...
                         'field use.'];
        lines{end+1} = '';
    end

    lines{end+1} = '--- Image Quality --------------------------------------';
    lines{end+1} = info.imageQuality.msg;
    lines{end+1} = '';

    lines{end+1} = '--- Prediction -------------------------------------------';
    lines{end+1} = sprintf('DR Severity Level : %d - %s', info.drLevel, info.drLabel);
    if info.referable
        lines{end+1} = 'Referral Status   : REFERABLE DR (Level >= 2) - refer to ophthalmologist';
    else
        lines{end+1} = 'Referral Status   : Non-referable (routine annual screening)';
    end
    lines{end+1} = sprintf('Model Confidence  : %.1f%%', info.confidence);
    lines{end+1} = '';
    lines{end+1} = 'Full class probabilities:';
    for i = 1:numel(info.allNames)
        lines{end+1} = sprintf('   %-22s : %5.1f%%', string(info.allNames{i}), info.allScores(i)*100); %#ok<AGROW>
    end
    lines{end+1} = '';

    lines{end+1} = '--- Visual Evidence (Grad-CAM + Lesion Heuristics) --------';
    lines{end+1} = 'Grad-CAM highlights the retinal regions that most influenced';
    lines{end+1} = 'the severity prediction (see heatmap panel).';
    lines{end+1} = '';
    lesions = info.lesions;
    lines{end+1} = sprintf('   Microaneurysms (candidate)      : %d', lesions.microaneurysms.count);
    lines{end+1} = sprintf('   Hemorrhages (candidate)         : %d', lesions.hemorrhages.count);
    lines{end+1} = sprintf('   Exudates (candidate)            : %d', lesions.exudates.count);
    if lesions.neovascularization.suspected
        lines{end+1} = '   Neovascularization              : SUSPECTED (abnormal vessel density hot-spot)';
    else
        lines{end+1} = '   Neovascularization              : Not suspected';
    end
    lines{end+1} = '   (Lesion counts are heuristic image-processing estimates,';
    lines{end+1} = '    intended as reviewer pointers, not a validated detector.)';
    lines{end+1} = '';

    lines{end+1} = '--- Independent Statistical Cross-Check -------------------';
    lines{end+1} = sprintf('Lesion-burden risk score : %d/100', info.riskScore);
    lines{end+1} = info.riskSuggestion;
    if (info.riskScore >= 40) ~= info.referable
        lines{end+1} = '** NOTE: This independent lesion-based signal disagrees with';
        lines{end+1} = '   the CNN classification above - recommend manual review.';
    end
    lines{end+1} = '';

    lines{end+1} = '--- Recommendation ------------------------------------------';
    switch info.drLevel
        case 0
            rec = 'No DR detected. Recommend routine annual screening.';
        case 1
            rec = 'Mild NPDR. Recommend re-screening in 9-12 months.';
        case 2
            rec = 'Moderate NPDR. Recommend ophthalmologist review within 3-6 months.';
        case 3
            rec = 'Severe NPDR. Recommend prompt ophthalmologist referral (within weeks).';
        case 4
            rec = 'Proliferative DR. Recommend URGENT ophthalmologist referral.';
        otherwise
            rec = 'Recommend ophthalmologist review.';
    end
    lines{end+1} = rec;
    lines{end+1} = '';
    lines{end+1} = ['This report is generated by an AI-assisted screening tool and is ' ...
                     'intended to support, not replace, clinical judgement.'];
    lines{end+1} = '=====================================================';

    reportStr = strjoin(lines, newline);
end
