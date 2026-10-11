function [overlayImg, heatmap] = computeGradCAMHeatmap(net, img, classIdx, featureLayer, reductionLayer)
%COMPUTEGRADCAMHEATMAP Compute a Grad-CAM heatmap and overlay it on img.
%
%   [overlayImg, heatmap] = computeGradCAMHeatmap(net, img, classIdx, ...
%                                                  featureLayer, reductionLayer)
%
%   Wraps MATLAB's built-in gradCAM (Deep Learning Toolbox, R2021b+) and
%   returns both the raw heatmap and a ready-to-display RGB overlay
%   (jet colormap at ~45% alpha over the original image) - this is what
%   an ophthalmologist actually wants to look at.
%
%   For a ResNet-18 backbone, 'res5b_relu' (last residual block output)
%   is a good default feature layer. If the supplied layer name doesn't
%   exist on this network (e.g. a different backbone, or a MATLAB
%   version with different internal layer names), this function falls
%   back to gradCAM's own automatic layer selection, so it keeps working
%   regardless of exact architecture/version.

    if nargin < 4 || isempty(featureLayer), featureLayer = 'res5b_relu'; end
    if nargin < 5, reductionLayer = ''; end

    try
        if isempty(reductionLayer)
            heatmap = gradCAM(net, img, classIdx, 'FeatureLayer', featureLayer);
        else
            heatmap = gradCAM(net, img, classIdx, ...
                'FeatureLayer', featureLayer, 'ReductionLayer', reductionLayer);
        end
    catch
        % Layer name mismatch / unsupported name-value pair on this
        % MATLAB version or backbone - let gradCAM auto-select layers.
        heatmap = gradCAM(net, img, classIdx);
    end

    % Normalise 0-1 and resize to the image size
    heatmap = rescale(heatmap);
    heatmap = imresize(heatmap, [size(img,1), size(img,2)]);

    cmap = jet(256);
    heatColor = ind2rgb(gray2ind(heatmap, 256), cmap);
    heatColor = im2uint8(heatColor);

    alpha = 0.45;
    overlayImg = im2uint8(im2double(img) * (1-alpha) + im2double(heatColor) * alpha);
end
