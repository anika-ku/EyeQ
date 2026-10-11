function [isFundus, confidence, reason] = isLikelyFundusImage(img)
%ISLIKELYFUNDUSIMAGE Heuristic check for whether an image looks like a
%retinal fundus photograph, to catch accidental uploads of an unrelated
%photo (selfies, screenshots, random pictures, etc.).
%
%   [isFundus, confidence, reason] = isLikelyFundusImage(img)
%
%   Combines several cheap, explainable signals, in order of reliability:
%     1. Face detection (Computer Vision Toolbox, if available) - a
%        human face is an almost certain sign this is NOT a fundus
%        photo. This is the strongest and most reliable signal here.
%     2. Aspect ratio - fundus photos are almost always close to square
%        (the circular field-of-view sits centred in a near-square
%        frame); ordinary phone/camera photos are usually clearly
%        rectangular (portrait or landscape).
%     3. Colour profile - fundus photos are strongly red/orange-dominant
%        (retinal tissue + blood vessels).
%     4. Field-of-view shape - a roughly circular illuminated region
%        surrounded by a dark border.
%
%   This is a heuristic sanity check, NOT a certified fundus-photo
%   classifier - it can occasionally be wrong. Treat it as a warning to
%   double-check, not an unbreakable gate.
%
%   Outputs:
%       isFundus   - logical, best guess
%       confidence - 0-100, how confident the heuristic is
%       reason     - char, human-readable explanation

    img = im2double(img);
    [h, w, ~] = size(img);

    % --- Warm (red/orange/brown) hue fraction - computed early so it can ---
    % also act as a safety check against false-positive face detections.
    % Retinal tissue is consistently orange/red/brown regardless of the
    % exact photo crop, aspect ratio, or camera style.
    hsv = rgb2hsv(img);
    hue = hsv(:,:,1);
    val = hsv(:,:,3);
    validPixels = val > 0.08;   % exclude near-black border/corner pixels
    warmPixels = validPixels & (hue < 0.14 | hue > 0.92);
    if any(validPixels(:))
        warmFraction = sum(warmPixels(:)) / sum(validPixels(:));
    else
        warmFraction = 0;
    end

    % --- Signal 1: face detection (strong signal, but not infallible) ------
    % Cascade face detectors can occasionally fire on round, textured
    % patterns (like a fundus photo's bright optic disc glow), so we only
    % trust a face detection when the image ISN'T already overwhelmingly
    % retina-coloured - a real face photo essentially never has this much
    % warm/red/orange coverage.
    faceDetected = false;
    if warmFraction < 0.45
        try
            detector = vision.CascadeObjectDetector();
            detector.MergeThreshold = 8;   % fewer, more confident detections
            bboxes = step(detector, im2uint8(img));
            faceDetected = ~isempty(bboxes);
        catch
            % Computer Vision Toolbox / this detector not available - skip.
        end
    end

    if faceDetected
        isFundus = false;
        confidence = 0;
        reason = ['A human face was detected in this image, so it is almost ' ...
            'certainly not a retinal fundus photo. Please upload the correct ' ...
            'fundus image.'];
        return;
    end

    colorScore = round(min(60, warmFraction * 100));

    % --- Signal 3: roughly compact bright field-of-view region --------------
    % Not gated on aspect ratio - wide-field/dual-lobe fundus photos and
    % square ones should both be able to earn this.
    gray = rgb2gray(img);
    mask = gray > (graythresh(gray) * 0.4);
    mask = imfill(mask, 'holes');
    mask = bwareafilt(mask, 1);

    shapeScore = 0;
    if any(mask(:))
        stats = regionprops(mask, 'Area', 'Extent');
        fillRatio = stats(1).Area / numel(gray);
        if fillRatio > 0.15 && fillRatio < 0.98 && stats(1).Extent > 0.45
            shapeScore = 25;
        elseif fillRatio >= 0.98
            shapeScore = 12;
        end
    end

    % --- Signal 4: aspect ratio - now just a small bonus, not a gate --------
    aspect = max(h, w) / min(h, w);
    if aspect <= 1.15
        aspectScore = 15;
    elseif aspect <= 1.6
        aspectScore = 8;
    elseif aspect <= 2.2
        aspectScore = 3;
    else
        aspectScore = 0;
    end

    confidence = round(colorScore + shapeScore + aspectScore);
    confidence = max(0, min(100, confidence));
    isFundus = confidence >= 40;

    if isFundus
        reason = 'Colour profile, field-of-view shape, and aspect ratio are consistent with a fundus photo.';
    else
        reason = ['This does not look like a typical retinal fundus photo ' ...
            '(insufficient warm/reddish colour content and/or field-of-view ' ...
            'shape). Predictions on non-fundus images are meaningless - ' ...
            'please double check you uploaded the correct image.'];
    end
end
