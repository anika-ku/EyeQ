function apiAnalyzeBatchFast(manifestPath)
%APIANALYZEBATCHFAST Process an entire bulk batch in one MATLAB process.
% Manifest JSON: {"items":[{"imagePath":"...","outputDir":"..."}, ...]}
addpath(fileparts(mfilename('fullpath')));
manifest = jsondecode(fileread(manifestPath));
items = manifest.items;
for i = 1:numel(items)
    try
        apiAnalyzeImageFast(char(items(i).imagePath), char(items(i).outputDir));
    catch ME
        outDir = char(items(i).outputDir);
        if ~isfolder(outDir), mkdir(outDir); end
        result = struct('error', ME.message, 'analysisMode', 'fast');
        fid = fopen(fullfile(outDir,'result.json'),'w');
        if fid >= 0
            fwrite(fid, jsonencode(result), 'char'); fclose(fid);
        end
    end
end
end
