function prepareDRDataset(imagesFolder, csvPath, outputFolder, idColumn, labelColumn, imageExt)
%PREPAREDRDATASET Reorganize a CSV-labeled DR dataset into class folders.
%
%   prepareDRDataset(imagesFolder, csvPath, outputFolder, idColumn, labelColumn, imageExt)
%
%   Many public DR datasets (APTOS 2019, IDRiD, Messidor-2) ship as ONE
%   folder of images plus a CSV/XLS file mapping each filename to a
%   severity grade (0-4), rather than the folder-per-class layout that
%   trainDRModel.m / imageDatastore expects. This function copies each
%   image into outputFolder/<class>/ based on its label in the CSV, so
%   you end up with exactly the structure trainDRModel.m wants:
%
%       outputFolder/
%           0_NoDR/
%           1_Mild/
%           2_Moderate/
%           3_Severe/
%           4_Proliferative/
%
%   Inputs:
%       imagesFolder - folder containing the raw images
%       csvPath      - path to the CSV/XLS file with id + label columns
%       outputFolder - where to build the class-folder structure
%                      (this becomes your `datasetRoot` in trainDRModel.m)
%       idColumn     - name of the column holding the image filename/id
%                      (WITHOUT extension), e.g. 'id_code' for APTOS
%       labelColumn  - name of the column holding the 0-4 severity grade,
%                      e.g. 'diagnosis' for APTOS
%       imageExt     - file extension of the images, e.g. '.png' or '.jpg'
%                      (include the dot)
%
%   Example - APTOS 2019 (after downloading + unzipping from Kaggle):
%       prepareDRDataset('train_images', 'train.csv', 'dataset', ...
%                         'id_code', 'diagnosis', '.png')
%
%   Example - IDRiD (Disease Grading subset):
%       prepareDRDataset( ...
%           'B. Disease Grading/Original Images/a. Training Set', ...
%           'B. Disease Grading/Groundtruths/a. IDRiD_Disease Grading_Training Labels.csv', ...
%           'dataset', 'Image name', 'Retinopathy grade', '.jpg')
%
%   Example - Messidor-2 (column names vary by release - check your CSV
%   header first with: readtable('yourfile.csv').Properties.VariableNames):
%       prepareDRDataset('IMAGES', 'messidor_data.csv', 'dataset', ...
%                         'image_id', 'adjudicated_dr_grade', '.jpg')
%
%   After running this, point datasetRoot in trainDRModel.m at
%   outputFolder and run that script as usual.

    classFolderNames = {'0_NoDR', '1_Mild', '2_Moderate', '3_Severe', '4_Proliferative'};

    if ~isfolder(imagesFolder)
        error('Images folder not found: %s', imagesFolder);
    end
    if ~isfile(csvPath)
        error('CSV/label file not found: %s', csvPath);
    end

    T = readtable(csvPath);
    if ~ismember(idColumn, T.Properties.VariableNames)
        error(['Column "%s" not found in %s. Available columns are: %s\n' ...
               'Open the file and check the exact header names.'], ...
               idColumn, csvPath, strjoin(T.Properties.VariableNames, ', '));
    end
    if ~ismember(labelColumn, T.Properties.VariableNames)
        error(['Column "%s" not found in %s. Available columns are: %s\n' ...
               'Open the file and check the exact header names.'], ...
               labelColumn, csvPath, strjoin(T.Properties.VariableNames, ', '));
    end

    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    for c = 1:numel(classFolderNames)
        classPath = fullfile(outputFolder, classFolderNames{c});
        if ~isfolder(classPath)
            mkdir(classPath);
        end
    end

    ids = T.(idColumn);
    labels = T.(labelColumn);

    nCopied = 0;
    nSkipped = 0;

    for i = 1:height(T)
        thisId = ids(i);
        if isnumeric(thisId)
            thisId = num2str(thisId);
        else
            thisId = char(string(thisId));
        end

        thisLabel = labels(i);
        if iscell(thisLabel), thisLabel = thisLabel{1}; end
        thisLabel = round(double(thisLabel));

        if thisLabel < 0 || thisLabel > 4 || isnan(thisLabel)
            nSkipped = nSkipped + 1;
            continue;
        end

        srcFile = fullfile(imagesFolder, [thisId, imageExt]);
        if ~isfile(srcFile)
            % Try without re-adding extension, in case idColumn already
            % includes it.
            srcFile = fullfile(imagesFolder, thisId);
            if ~isfile(srcFile)
                nSkipped = nSkipped + 1;
                continue;
            end
        end

        destFile = fullfile(outputFolder, classFolderNames{thisLabel + 1}, [thisId, imageExt]);
        try
            copyfile(srcFile, destFile);
            nCopied = nCopied + 1;
        catch
            nSkipped = nSkipped + 1;
        end

        if mod(i, 200) == 0
            fprintf('Processed %d / %d rows...\n', i, height(T));
        end
    end

    fprintf('Done. Copied %d images, skipped %d (missing file or invalid label).\n', ...
        nCopied, nSkipped);
    fprintf('Dataset ready at: %s\n', outputFolder);
    fprintf('Now set datasetRoot = ''%s''; in trainDRModel.m and run it.\n', outputFolder);
end
