function [processedImg, cropRect, resizedOriginal] = preprocessFundusImage(img, targetSize)
%PREPROCESSFUNDUSIMAGE Preprocess a retinal fundus image for DR screening.
%
%   [processedImg, cropRect, resizedOriginal] = preprocessFundusImage(img, targetSize)
%
%   Steps performed:
%       1. Convert to RGB uint8 (handles grayscale input too).
%       2. Detect and crop the circular fundus field-of-view, removing
%          the black borders that are common in fundus camera captures
%          (especially with lower-end rural screening cameras).
%       3. Resize to the network input size (default 224x224, matches
%          ResNet-18).
%       4. Apply CLAHE (adaptive histogram equalisation) on the
%          luminance channel to normalise illumination/contrast.
%
%   Inputs:
%       img        - original RGB (or grayscale) fundus image, uint8/double
%       targetSize - [rows cols], default [224 224]
%
%   Outputs:
%       processedImg    - preprocessed RGB image, uint8, size targetSize x 3.
%                         Feed this into the classifier / Grad-CAM.
%       cropRect        - [x y width height] of the detected FOV crop
%       resizedOriginal - cropped-but-NOT-contrast-enhanced RGB image at
%                         targetSize. Use this as the "clean" background
%                         when overlaying lesion markers, since CLAHE can
%                         make marker colours harder to read.

    if nargin < 2 || isempty(targetSize)
        targetSize = [224 224];
    end

    % --- 1. Ensure RGB uint8 -------------------------------------------
    if size(img,3) == 1
        img = repmat(img, 1, 1, 3);
    end
    if ~isa(img,'uint8')
        img = im2uint8(mat2gray(img));
    end

    % --- 2. Detect circular fundus field-of-view and crop ---------------
    gray = rgb2gray(img);
    mask = gray > (graythresh(gray) * 255 * 0.15);   % conservative dark-border mask
    mask = imfill(mask, 'holes');
    mask = bwareafilt(mask, 1);                       % keep the largest blob (the eye)

    if any(mask(:))
        stats = regionprops(mask, 'BoundingBox');
        cropRect = round(stats(1).BoundingBox);
        cropRect(1:2) = max(cropRect(1:2), 1);
        x2 = min(cropRect(1) + cropRect(3), size(img,2));
        y2 = min(cropRect(2) + cropRect(4), size(img,1));
        croppedImg = img(cropRect(2):y2, cropRect(1):x2, :);
    else
        cropRect = [1 1 size(img,2) size(img,1)];
        croppedImg = img;
    end

    % --- 3. Resize --------------------------------------------------------
    resizedOriginal = imresize(croppedImg, targetSize);

    % --- 4. CLAHE on luminance (L*a*b* colour space) -----------------------
    lab = rgb2lab(resizedOriginal);
    L = lab(:,:,1) / 100;
    L = adapthisteq(L, 'ClipLimit', 0.01, 'Distribution', 'rayleigh');
    lab(:,:,1) = L * 100;
    processedImg = im2uint8(lab2rgb(lab));
end
