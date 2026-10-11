function exportVisualReport(reportStr, originalImg, gradCamImg, lesionImg, outFile)
%EXPORTVISUALREPORT Save a PDF screening report that includes the
%uploaded image, Grad-CAM heatmap overlay, and lesion evidence markers
%alongside the full text report.
%
%   exportVisualReport(reportStr, originalImg, gradCamImg, lesionImg, outFile)
%
%   Produces a 2-page PDF:
%     Page 1 - the three images side by side/stacked, plus a short
%              excerpt of the key findings
%     Page 2 - the complete text report (image quality, full
%              probabilities, lesion counts, recommendation, etc.)
%
%   Requires only base MATLAB graphics (exportgraphics, R2020a+) - no
%   extra toolbox needed.

    % --- Page 1: images + key summary --------------------------------------
    fig1 = figure('Visible', 'off', 'Color', 'w', 'Units', 'inches', ...
        'Position', [0 0 8.5 11]);

    annotation(fig1, 'textbox', [0.05 0.94 0.9 0.05], ...
        'String', 'Automated Diabetic Retinopathy Screening Report', ...
        'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center');

    ax1 = axes(fig1, 'Position', [0.06 0.55 0.40 0.34]);
    imshow(originalImg, 'Parent', ax1);
    title(ax1, 'Uploaded Image', 'FontSize', 9);

    ax2 = axes(fig1, 'Position', [0.54 0.55 0.40 0.34]);
    imshow(gradCamImg, 'Parent', ax2);
    title(ax2, 'Grad-CAM Heatmap Overlay', 'FontSize', 9);

    ax3 = axes(fig1, 'Position', [0.30 0.15 0.40 0.34]);
    imshow(lesionImg, 'Parent', ax3);
    title(ax3, 'Lesion Evidence Markers', 'FontSize', 9);

    lines = strsplit(reportStr, newline);
    excerptEnd = min(14, numel(lines));
    excerpt = strjoin(lines(1:excerptEnd), newline);
    annotation(fig1, 'textbox', [0.05 0.02 0.9 0.10], ...
        'String', excerpt, 'FontName', 'Consolas', 'FontSize', 7, ...
        'EdgeColor', 'none', 'Interpreter', 'none', ...
        'VerticalAlignment', 'top');

    exportgraphics(fig1, outFile);
    close(fig1);

    % --- Page 2: full text report -------------------------------------------
    fig2 = figure('Visible', 'off', 'Color', 'w', 'Units', 'inches', ...
        'Position', [0 0 8.5 11]);
    annotation(fig2, 'textbox', [0.05 0.05 0.90 0.90], ...
        'String', reportStr, 'FontName', 'Consolas', 'FontSize', 7, ...
        'EdgeColor', 'none', 'Interpreter', 'none', ...
        'VerticalAlignment', 'top');
    exportgraphics(fig2, outFile, 'Append', true);
    close(fig2);
end
