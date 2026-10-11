function lesionResults = detectLesions(img)
%DETECTLESIONS Heuristic, classical-image-processing lesion evidence.
%
%   lesionResults = detectLesions(img)
%
%   IMPORTANT: These are fast, explainable, morphology-based heuristics
%   meant to give an ophthalmologist quick visual pointers alongside the
%   Grad-CAM heatmap. They are NOT a validated lesion-detection model -
%   treat counts/masks as approximate, demonstration-level evidence and
%   label them as such in the report and UI.
%
%   Approximates:
%       - Microaneurysms      : small round dark spots (green channel)
%       - Hemorrhages         : larger, irregular dark blotches
%       - Exudates            : bright yellow-white lesions
%       - Neovascularization  : abnormal local vessel-density hot spots
%
%   Output struct fields:
%       .microaneurysms.count / .mask / .centroids
%       .hemorrhages.count    / .mask / .centroids
%       .exudates.count       / .mask / .centroids
%       .neovascularization.suspected (logical) / .mask
%       .overlayImg  - RGB image with all findings marked, for display
%
%   Requires: Image Processing Toolbox. Uses Computer Vision Toolbox's
%   insertShape for nicer markers where available (falls back gracefully
%   if not installed).

    img = im2double(img);
    green = img(:,:,2);   % green channel gives the best vessel/lesion contrast

    % Rough optic-disc mask (brightest, largest compact blob), so the
    % optic disc itself isn't misread as an exudate. prctile() is a
    % Statistics and Machine Learning Toolbox function.
    discCandidate = green > prctile(green(:), 99.2);
    discCandidate = imopen(discCandidate, strel('disk', 3));
    discMask = bwareafilt(discCandidate, 1);
    if any(discMask(:))
        discMask = imdilate(discMask, strel('disk', 8));
    end

    %% --- Dark lesions: microaneurysms + hemorrhages -----------------------
    greenEq = adapthisteq(green, 'ClipLimit', 0.01);
    darkTopHat = imbothat(greenEq, strel('disk', 8));
    darkMask = darkTopHat > (graythresh(darkTopHat) * 1.3);
    darkMask = bwareaopen(darkMask, 3);
    darkMask = darkMask & ~discMask;

    cc = bwconncomp(darkMask);
    stats = regionprops(cc, 'Area', 'Centroid');
    areas = [stats.Area];

    % Small + round -> microaneurysm candidates; larger -> hemorrhage candidates
    isMA  = areas > 0 & areas <= 15;
    isHem = areas > 15;

    maCentroids  = safeCentroids(stats, isMA);
    hemCentroids = safeCentroids(stats, isHem);

    lbl = labelmatrix(cc);
    maMask  = ismember(lbl, find(isMA));
    hemMask = ismember(lbl, find(isHem));

    %% --- Bright lesions: exudates -------------------------------------------
    brightTopHat = imtophat(greenEq, strel('disk', 10));
    exudateMask = brightTopHat > (graythresh(brightTopHat) * 1.5);
    exudateMask = bwareaopen(exudateMask, 5);
    exudateMask = exudateMask & ~discMask;

    ccEx = bwconncomp(exudateMask);
    statsEx = regionprops(ccEx, 'Centroid');
    exCentroids = safeCentroids(statsEx, true(1, numel(statsEx)));

    %% --- Neovascularization heuristic: abnormal local vessel density --------
    vesselish = imbinarize(imcomplement(greenEq), 'adaptive', 'Sensitivity', 0.45);
    vesselish = bwareaopen(vesselish, 10) & ~discMask;
    density = imfilter(double(vesselish), fspecial('average', 25));
    hotspot = density > (mean(density(:)) + 3*std(density(:)));
    hotspot = bwareaopen(hotspot, 20);
    neoSuspected = any(hotspot(:));

    %% --- Package results --------------------------------------------------------
    lesionResults.microaneurysms.count = sum(isMA);
    lesionResults.microaneurysms.mask = maMask;
    lesionResults.microaneurysms.centroids = maCentroids;

    lesionResults.hemorrhages.count = sum(isHem);
    lesionResults.hemorrhages.mask = hemMask;
    lesionResults.hemorrhages.centroids = hemCentroids;

    lesionResults.exudates.count = size(exCentroids, 1);
    lesionResults.exudates.mask = exudateMask;
    lesionResults.exudates.centroids = exCentroids;

    lesionResults.neovascularization.suspected = neoSuspected;
    lesionResults.neovascularization.mask = hotspot;

    %% --- Build a marked overlay image for display --------------------------------
    overlay = im2uint8(img);
    overlay = insertMarkerSafe(overlay, maCentroids,  'yellow', 4);
    overlay = insertMarkerSafe(overlay, hemCentroids, 'red',    6);
    overlay = insertMarkerSafe(overlay, exCentroids,  'cyan',   6);
    if neoSuspected
        try
            overlay = imoverlay(overlay, bwperim(hotspot), 'magenta');
        catch
            % Image Processing Toolbox version mismatch - skip overlay.
        end
    end
    lesionResults.overlayImg = overlay;
end

function c = safeCentroids(stats, mask)
%SAFECENTROIDS Extract centroids for a logical selection, returns Nx2
%(empty Nx2, not 0x0, so downstream code can safely check size(.,1)).
    if isempty(stats) || ~any(mask)
        c = zeros(0, 2);
        return;
    end
    sel = stats(mask);
    c = reshape([sel.Centroid], 2, [])';
end

function outImg = insertMarkerSafe(img, points, color, sz)
%INSERTMARKERSAFE Draw simple circular markers using Computer Vision
%Toolbox's insertShape. Falls back to returning the image unmarked if
%the toolbox isn't available - counts/masks are still returned by the
%caller regardless.
    outImg = img;
    if isempty(points), return; end
    try
        outImg = insertShape(img, 'circle', [points, repmat(sz, size(points,1), 1)], ...
            'Color', color, 'LineWidth', 2);
    catch
        % Computer Vision Toolbox not available - skip visual markers.
    end
end
