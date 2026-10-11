classdef DRExplainabilityApp < matlab.apps.AppBase
%DREXPLAINABILITYAPP Explainable AI for Diabetic Retinopathy Screening.
%
%   Smart India Hackathon 2026 prototype - EXPLAINABILITY PIPELINE.
%
%   Workflow implemented:
%       Upload Fundus Image
%         -> Image Quality / Preprocessing
%         -> DR Severity Prediction (5-level ICDR scale)
%         -> Referable DR Decision (Level >= 2)
%         -> Grad-CAM Explainability
%         -> Lesion / Evidence Display (heuristic)
%         -> Confidence Score
%         -> Automated Screening Report
%
%   IMPORTANT: If no trained network (trainedDRNet.mat) is found next to
%   this file, the app runs in DEMO MODE using an ImageNet-pretrained
%   ResNet-18 backbone with an UNTRAINED classification head. This lets
%   you demonstrate the full pipeline (including a real forward pass and
%   real Grad-CAM gradients) without a trained model, but predictions in
%   that mode are NOT clinically meaningful - the app labels this
%   clearly on screen and in the report. Run trainDRModel.m on a real DR
%   dataset to get real predictions.
%
%   Run with:  app = DRExplainabilityApp;   (or just: DRExplainabilityApp)

    % ---------------------------------------------------------------
    % UI component handles
    % ---------------------------------------------------------------
    properties (Access = public)
        UIFigure
        MainGrid

        % Left: input
        LeftPanel
        LeftGrid
        OriginalAxes
        UploadButton
        PatientIDLabel
        PatientIDField
        QualityLabel
        DemoBanner
        RunButton

        % Middle: prediction
        MiddlePanel
        MiddleGrid
        DRGradeValueLabel
        ReferableValueLabel
        ConfidenceValueLabel
        ProbAxes
        StatusLabel

        % Right: explainability
        RightPanel
        RightGrid
        GradCAMAxes
        LesionAxes
        LesionTable
        RiskLabel

        % Bottom: report
        BottomPanel
        BottomGrid
        ReportTextArea
        ExportReportButton
        ExportPDFButton
    end

    % ---------------------------------------------------------------
    % App data
    % ---------------------------------------------------------------
    properties (Access = private)
        OriginalImage = []
        DisplayImage = []
        PreprocessedImage = []
        Net = []
        ClassNames = {'Level0_NoDR','Level1_Mild','Level2_Moderate','Level3_Severe','Level4_Proliferative'}
        DisplayNames = {'No DR','Mild NPDR','Moderate NPDR','Severe NPDR','Proliferative DR'}
        IsDemoModel = true
        LastLesionResults = []
        LastGradCAMOverlay = []
    end

    % ---------------------------------------------------------------
    % Callbacks
    % ---------------------------------------------------------------
    methods (Access = private)

        function startupFcn(app)
            app.StatusLabel.Text = 'Loading model...';
            drawnow;
            try
                if isfile('trainedDRNet.mat')
                    s = load('trainedDRNet.mat');
                    app.Net = s.net;
                    if isfield(s, 'classNames')
                        app.ClassNames = s.classNames;
                    end
                    app.IsDemoModel = false;
                    app.DemoBanner.Text = '';
                    app.StatusLabel.Text = 'Trained DR model loaded.';
                else
                    app.Net = buildDemoNetwork(app);
                    app.IsDemoModel = true;
                    app.DemoBanner.Text = sprintf(['DEMO MODEL: no trained network found ' ...
                        '(trainedDRNet.mat). Using an untrained ImageNet backbone - ' ...
                        'predictions are for PIPELINE DEMONSTRATION only, not clinical use.']);
                    app.StatusLabel.Text = 'Demo model ready (untrained head).';
                end
            catch ME
                app.StatusLabel.Text = ['Model load error: ' ME.message];
                uialert(app.UIFigure, ME.message, 'Model load failed');
            end
        end

        function net = buildDemoNetwork(app)
            lgraph = buildDRModel(numel(app.ClassNames), [224 224 3], app.ClassNames);
            % dlnetwork does not allow a classification/regression output
            % layer in the graph at all (unlike assembleNetwork/
            % trainNetwork) - it must be removed first. The preceding
            % softmax ('prob') layer stays, so the network still outputs
            % probabilities.
            lgraph = removeLayers(lgraph, 'classoutput_dr');
            % dlnetwork automatically initialises any layer whose learnable
            % parameters are empty (Glorot/He initialisation) - unlike
            % assembleNetwork, which requires every layer to already have
            % valid weights. This is exactly what we need for an untrained
            % demo network.
            net = dlnetwork(lgraph);
        end

        function UploadButtonPushed(app, ~)
            [file, path] = uigetfile({'*.jpg;*.jpeg;*.png;*.tif;*.tiff', 'Fundus Images'}, ...
                'Select a retinal fundus image');
            if isequal(file, 0)
                return;
            end
            try
                app.OriginalImage = imread(fullfile(path, file));
                imshow(app.OriginalImage, 'Parent', app.OriginalAxes);
                title(app.OriginalAxes, file, 'Interpreter', 'none');

                [~, qMsg, qOK] = assessImageQuality(app.OriginalImage);
                app.QualityLabel.Text = ['Image quality: ' qMsg];
                if qOK
                    app.QualityLabel.FontColor = [0.1 0.5 0.1];
                else
                    app.QualityLabel.FontColor = [0.75 0 0];
                end

                [isFundus, fundusConf, fundusReason] = isLikelyFundusImage(app.OriginalImage);
                if ~isFundus
                    uialert(app.UIFigure, fundusReason, ...
                        sprintf('This may not be a fundus photo (%d%% confidence it is)', fundusConf), ...
                        'Icon', 'warning');
                end

                app.RunButton.Enable = 'on';
                app.StatusLabel.Text = 'Image loaded. Ready to run pipeline.';

                cla(app.GradCAMAxes);
                cla(app.LesionAxes);
                cla(app.ProbAxes);
                app.DRGradeValueLabel.Text = 'DR Grade: -';
                app.DRGradeValueLabel.FontColor = [0 0 0];
                app.ReferableValueLabel.Text = 'Referable status: -';
                app.ReferableValueLabel.FontColor = [0.3 0.3 0.3];
                app.ConfidenceValueLabel.Text = 'Confidence: -';
                app.RiskLabel.Text = 'Lesion-based cross-check: -';
                app.RiskLabel.FontColor = [0.3 0.3 0.3];
                app.LesionTable.Data = {'Microaneurysms','-'; 'Hemorrhages','-'; ...
                    'Exudates','-'; 'Neovascularization','-'};
                app.ReportTextArea.Value = {'Click "Run Screening Pipeline" to generate the report.'};
                app.ExportReportButton.Enable = 'off';
                app.ExportPDFButton.Enable = 'off';
            catch ME
                uialert(app.UIFigure, ME.message, 'Could not load image');
            end
        end

        function RunButtonPushed(app, ~)
            if isempty(app.OriginalImage)
                uialert(app.UIFigure, 'Please upload a fundus image first.', 'No image');
                return;
            end
            app.StatusLabel.Text = 'Running pipeline...';
            app.RunButton.Enable = 'off';
            drawnow;

            try
                targetSize = [224 224];

                % 1. Preprocess ------------------------------------------------
                [app.PreprocessedImage, ~, app.DisplayImage] = ...
                    preprocessFundusImage(app.OriginalImage, targetSize);
                [qScore, qMsg, ~] = assessImageQuality(app.OriginalImage);
                app.QualityLabel.Text = ['Image quality: ' qMsg];

                [isFundus, fundusConf, fundusReason] = isLikelyFundusImage(app.OriginalImage);

                % 2. Predict severity ---------------------------------------------
                [~, classIdx, ~, sortedScores, sortedNames] = ...
                    predictDR(app.Net, app.PreprocessedImage, app.ClassNames);

                drLevel = classIdx - 1;
                drLabelText = app.DisplayNames{classIdx};
                confidence = sortedScores(1) * 100;
                referable = drLevel >= 2;

                app.DRGradeValueLabel.Text = sprintf('DR Grade: Level %d', drLevel);
                severityColors = [0.10 0.60 0.10; 0.55 0.70 0.10; 0.90 0.60 0.00; ...
                                   0.85 0.30 0.00; 0.70 0.00 0.00];
                app.DRGradeValueLabel.FontColor = severityColors(drLevel+1, :);

                if referable
                    app.ReferableValueLabel.Text = sprintf('%s  (REFERABLE)', drLabelText);
                    app.ReferableValueLabel.FontColor = [0.75 0 0];
                else
                    app.ReferableValueLabel.Text = sprintf('%s  (Non-referable)', drLabelText);
                    app.ReferableValueLabel.FontColor = [0.1 0.5 0.1];
                end
                app.ConfidenceValueLabel.Text = sprintf('Confidence: %.1f%%', confidence);

                % Probability bar chart, fixed class order (Level 0..4)
                origOrder = zeros(1, numel(app.ClassNames));
                for k = 1:numel(app.ClassNames)
                    idx = find(strcmp(sortedNames, app.ClassNames{k}), 1);
                    origOrder(k) = sortedScores(idx) * 100;
                end
                bar(app.ProbAxes, categorical(app.DisplayNames, app.DisplayNames), origOrder);
                ylabel(app.ProbAxes, 'Probability (%)');
                title(app.ProbAxes, 'Class Probabilities');
                ylim(app.ProbAxes, [0 100]);

                % 3. Grad-CAM ---------------------------------------------------------
                overlayImg = computeGradCAMHeatmap(app.Net, app.PreprocessedImage, classIdx);
                app.LastGradCAMOverlay = overlayImg;
                imshow(overlayImg, 'Parent', app.GradCAMAxes);
                title(app.GradCAMAxes, sprintf('Grad-CAM for "%s"', drLabelText));

                % 4. Lesion evidence --------------------------------------------------
                lesionResults = detectLesions(app.DisplayImage);
                app.LastLesionResults = lesionResults;
                imshow(lesionResults.overlayImg, 'Parent', app.LesionAxes);
                title(app.LesionAxes, 'Candidate Lesion Markers');

                neoText = 'Not suspected';
                if lesionResults.neovascularization.suspected
                    neoText = 'SUSPECTED';
                end
                app.LesionTable.Data = { ...
                    'Microaneurysms', num2str(lesionResults.microaneurysms.count); ...
                    'Hemorrhages', num2str(lesionResults.hemorrhages.count); ...
                    'Exudates', num2str(lesionResults.exudates.count); ...
                    'Neovascularization', neoText};

                % 4b. Independent statistical cross-check ------------------------------
                [riskScore, riskSuggestion] = lesionBasedRiskScore(lesionResults);
                app.RiskLabel.Text = sprintf('Lesion-based cross-check: %d/100 - %s', ...
                    riskScore, riskSuggestion);
                if (riskScore >= 40) ~= referable
                    app.RiskLabel.FontColor = [0.85 0.5 0];
                else
                    app.RiskLabel.FontColor = [0.3 0.3 0.3];
                end

                % 5. Report ------------------------------------------------------------
                info.patientID = app.PatientIDField.Value;
                info.imageQuality.score = qScore;
                info.imageQuality.msg = qMsg;
                info.drLevel = drLevel;
                info.drLabel = drLabelText;
                info.referable = referable;
                info.confidence = confidence;
                info.allScores = sortedScores;
                info.allNames = sortedNames;
                info.lesions = lesionResults;
                info.riskScore = riskScore;
                info.riskSuggestion = riskSuggestion;
                info.isDemoModel = app.IsDemoModel;
                info.isFundus = isFundus;
                info.fundusConfidence = fundusConf;
                info.fundusReason = fundusReason;

                reportStr = generateScreeningReport(info);
                app.ReportTextArea.Value = strsplit(reportStr, newline);
                app.ExportReportButton.Enable = 'on';
                app.ExportPDFButton.Enable = 'on';

                app.StatusLabel.Text = 'Pipeline complete.';
            catch ME
                app.StatusLabel.Text = 'Error during pipeline.';
                uialert(app.UIFigure, ME.message, 'Pipeline error');
            end
            app.RunButton.Enable = 'on';
        end

        function ExportReportButtonPushed(app, ~)
            defaultName = sprintf('%s_DR_Report.txt', app.PatientIDField.Value);
            [file, path] = uiputfile('*.txt', 'Save Screening Report', defaultName);
            if isequal(file, 0)
                return;
            end
            try
                fid = fopen(fullfile(path, file), 'w');
                fprintf(fid, '%s', strjoin(app.ReportTextArea.Value, newline));
                fclose(fid);
                app.StatusLabel.Text = ['Report saved: ' file];
            catch ME
                uialert(app.UIFigure, ME.message, 'Save failed');
            end
        end

        function ExportPDFButtonPushed(app, ~)
            if isempty(app.LastGradCAMOverlay) || isempty(app.LastLesionResults)
                uialert(app.UIFigure, 'Run the screening pipeline first.', 'Nothing to export');
                return;
            end
            defaultName = sprintf('%s_DR_Report.pdf', app.PatientIDField.Value);
            [file, path] = uiputfile('*.pdf', 'Save Full Report (with images)', defaultName);
            if isequal(file, 0)
                return;
            end
            try
                app.StatusLabel.Text = 'Exporting PDF...';
                drawnow;
                reportStr = strjoin(app.ReportTextArea.Value, newline);
                exportVisualReport(reportStr, app.DisplayImage, app.LastGradCAMOverlay, ...
                    app.LastLesionResults.overlayImg, fullfile(path, file));
                app.StatusLabel.Text = ['Full report saved: ' file];
            catch ME
                app.StatusLabel.Text = 'PDF export failed.';
                uialert(app.UIFigure, ME.message, 'Save failed');
            end
        end
    end

    % ---------------------------------------------------------------
    % Component creation
    % ---------------------------------------------------------------
    methods (Access = private)

        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [50 50 1400 850];
            app.UIFigure.Name = 'Explainable AI - Diabetic Retinopathy Screening (SIH 2026 Prototype)';
            app.UIFigure.Color = [0.96 0.97 0.98];

            app.MainGrid = uigridlayout(app.UIFigure, [2 3]);
            app.MainGrid.RowHeight = {'1x', 260};
            app.MainGrid.ColumnWidth = {'1x', '1x', '1x'};
            app.MainGrid.RowSpacing = 10;
            app.MainGrid.ColumnSpacing = 10;
            app.MainGrid.Padding = [10 10 10 10];

            % ============= LEFT PANEL: INPUT ====================================
            app.LeftPanel = uipanel(app.MainGrid, 'Title', '1. Input Fundus Image', ...
                'FontWeight', 'bold', 'FontSize', 13);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            app.LeftGrid = uigridlayout(app.LeftPanel, [6 1]);
            app.LeftGrid.RowHeight = {'1x', 34, 34, 44, 70, 44};

            app.OriginalAxes = uiaxes(app.LeftGrid);
            app.OriginalAxes.Layout.Row = 1;
            app.OriginalAxes.Layout.Column = 1;
            title(app.OriginalAxes, 'Uploaded Image');
            app.OriginalAxes.XTick = [];
            app.OriginalAxes.YTick = [];

            app.UploadButton = uibutton(app.LeftGrid, 'push', ...
                'Text', 'Upload Fundus Image...', ...
                'ButtonPushedFcn', @(btn, event) UploadButtonPushed(app, event));
            app.UploadButton.Layout.Row = 2;
            app.UploadButton.Layout.Column = 1;

            idGrid = uigridlayout(app.LeftGrid, [1 2]);
            idGrid.Layout.Row = 3;
            idGrid.Layout.Column = 1;
            idGrid.ColumnWidth = {90, '1x'};
            idGrid.Padding = [0 0 0 0];
            app.PatientIDLabel = uilabel(idGrid, 'Text', 'Image ID:');
            app.PatientIDField = uieditfield(idGrid, 'text', 'Value', 'PATIENT-0001');

            app.QualityLabel = uilabel(app.LeftGrid, ...
                'Text', 'Image quality: (upload an image)', ...
                'FontColor', [0.4 0.4 0.4], 'WordWrap', 'on');
            app.QualityLabel.Layout.Row = 4;
            app.QualityLabel.Layout.Column = 1;

            app.DemoBanner = uilabel(app.LeftGrid, ...
                'Text', '', 'FontColor', [0.75 0 0], 'FontWeight', 'bold', 'WordWrap', 'on');
            app.DemoBanner.Layout.Row = 5;
            app.DemoBanner.Layout.Column = 1;

            app.RunButton = uibutton(app.LeftGrid, 'push', ...
                'Text', 'Run Screening Pipeline', ...
                'BackgroundColor', [0.15 0.45 0.85], 'FontColor', 'w', 'FontWeight', 'bold', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(btn, event) RunButtonPushed(app, event));
            app.RunButton.Layout.Row = 6;
            app.RunButton.Layout.Column = 1;

            % ============= MIDDLE PANEL: PREDICTION =============================
            app.MiddlePanel = uipanel(app.MainGrid, 'Title', '2. DR Prediction', ...
                'FontWeight', 'bold', 'FontSize', 13);
            app.MiddlePanel.Layout.Row = 1;
            app.MiddlePanel.Layout.Column = 2;

            app.MiddleGrid = uigridlayout(app.MiddlePanel, [5 1]);
            app.MiddleGrid.RowHeight = {60, 50, 50, '1x', 30};

            app.DRGradeValueLabel = uilabel(app.MiddleGrid, ...
                'Text', 'DR Grade: -', 'FontSize', 20, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center');
            app.DRGradeValueLabel.Layout.Row = 1;

            app.ReferableValueLabel = uilabel(app.MiddleGrid, ...
                'Text', 'Referable status: -', 'FontSize', 16, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', 'FontColor', [0.3 0.3 0.3]);
            app.ReferableValueLabel.Layout.Row = 2;

            app.ConfidenceValueLabel = uilabel(app.MiddleGrid, ...
                'Text', 'Confidence: -', 'FontSize', 15, ...
                'HorizontalAlignment', 'center');
            app.ConfidenceValueLabel.Layout.Row = 3;

            app.ProbAxes = uiaxes(app.MiddleGrid);
            app.ProbAxes.Layout.Row = 4;
            title(app.ProbAxes, 'Class Probabilities');

            app.StatusLabel = uilabel(app.MiddleGrid, 'Text', 'Ready.', ...
                'FontColor', [0.4 0.4 0.4], 'HorizontalAlignment', 'center');
            app.StatusLabel.Layout.Row = 5;

            % ============= RIGHT PANEL: EXPLAINABILITY ============================
            app.RightPanel = uipanel(app.MainGrid, ...
                'Title', '3. Explainability (Grad-CAM + Lesion Evidence)', ...
                'FontWeight', 'bold', 'FontSize', 13);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 3;

            app.RightGrid = uigridlayout(app.RightPanel, [4 1]);
            app.RightGrid.RowHeight = {'1.3x', '1x', 90, 26};

            app.GradCAMAxes = uiaxes(app.RightGrid);
            app.GradCAMAxes.Layout.Row = 1;
            title(app.GradCAMAxes, 'Grad-CAM Heatmap Overlay');
            app.GradCAMAxes.XTick = [];
            app.GradCAMAxes.YTick = [];

            app.LesionAxes = uiaxes(app.RightGrid);
            app.LesionAxes.Layout.Row = 2;
            title(app.LesionAxes, 'Lesion Evidence Markers');
            app.LesionAxes.XTick = [];
            app.LesionAxes.YTick = [];

            app.LesionTable = uitable(app.RightGrid, ...
                'ColumnName', {'Lesion Type', 'Finding'}, ...
                'ColumnWidth', {140, '1x'}, ...
                'Data', {'Microaneurysms', '-'; 'Hemorrhages', '-'; ...
                         'Exudates', '-'; 'Neovascularization', '-'});
            app.LesionTable.Layout.Row = 3;

            app.RiskLabel = uilabel(app.RightGrid, ...
                'Text', 'Lesion-based cross-check: -', 'FontColor', [0.3 0.3 0.3]);
            app.RiskLabel.Layout.Row = 4;

            % ============= BOTTOM: REPORT ==========================================
            app.BottomPanel = uipanel(app.MainGrid, 'Title', '4. Automated Screening Report', ...
                'FontWeight', 'bold', 'FontSize', 13);
            app.BottomPanel.Layout.Row = 2;
            app.BottomPanel.Layout.Column = [1 3];

            app.BottomGrid = uigridlayout(app.BottomPanel, [1 2]);
            app.BottomGrid.ColumnWidth = {'1x', 160};

            app.ReportTextArea = uitextarea(app.BottomGrid, ...
                'Value', {'Upload a fundus image and click "Run Screening Pipeline" to generate a report.'}, ...
                'Editable', 'off', 'FontName', 'Consolas', 'FontSize', 12);
            app.ReportTextArea.Layout.Column = 1;

            exportGrid = uigridlayout(app.BottomGrid, [2 1]);
            exportGrid.Layout.Column = 2;
            exportGrid.Padding = [0 0 0 0];
            exportGrid.RowSpacing = 8;

            app.ExportReportButton = uibutton(exportGrid, 'push', ...
                'Text', 'Export Report (.txt)', 'Enable', 'off', ...
                'ButtonPushedFcn', @(btn, event) ExportReportButtonPushed(app, event));
            app.ExportReportButton.Layout.Row = 1;

            app.ExportPDFButton = uibutton(exportGrid, 'push', ...
                'Text', 'Export Full Report (PDF, with images)', 'Enable', 'off', ...
                'ButtonPushedFcn', @(btn, event) ExportPDFButtonPushed(app, event));
            app.ExportPDFButton.Layout.Row = 2;

            app.UIFigure.CloseRequestFcn = @(src, event) delete(app);
            app.UIFigure.Visible = 'on';
        end
    end

    % ---------------------------------------------------------------
    % App creation and deletion
    % ---------------------------------------------------------------
    methods (Access = public)

        function app = DRExplainabilityApp
            createComponents(app)
            registerApp(app, app.UIFigure)
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        function delete(app)
            delete(app.UIFigure)
        end
    end
end
