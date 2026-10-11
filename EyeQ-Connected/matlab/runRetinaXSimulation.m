function result = runRetinaXSimulation(P)
%RUNRETINAXSIMULATION District-level telemedicine capacity simulation.
% P can be a struct or a JSON string. The model estimates the sustainable
% daily throughput of acquisition, network, AI and specialist-review stages,
% then optionally builds/runs the companion Simulink model.

returnJson = false;
if nargin < 1 || isempty(P), P = retinaXSimulationParameters(); end
if ischar(P) || isstring(P), P = jsondecode(char(P)); returnJson = true; end
P = applyDefaults(P);

workingDays = P.workingDaysPerYear;
hours = P.operatingHoursPerDay;

annualDemand = P.patientsPerYear;
dailyDemand = annualDemand / workingDays;

cameraDaily = P.numCameras * P.imagesPerCameraPerHour * hours;
networkDaily = (P.bandwidthMbps * 1e6 / 8) * 3600 * hours / (P.imageSizeMB * 1024^2);
aiDaily = P.aiWorkers * P.aiImagesPerHour * hours;
reviewDaily = P.reviewers * P.reviewsPerHour * hours;

stageCaps = [cameraDaily, networkDaily, aiDaily, reviewDaily];
stageNames = {'Image acquisition','Network transfer','AI processing','Specialist review'};
[throughputDaily, bottleneckIdx] = min(stageCaps);

coverage = min(1, throughputDaily / max(dailyDemand, eps));
util = min(1, dailyDemand ./ max(stageCaps, eps));
util = util .* coverage;

% Approximate average queue delay when demand exceeds a downstream stage.
loadRatio = dailyDemand / max(throughputDaily, eps);
if loadRatio <= 1
    waitHours = 0;
else
    waitHours = min(72, (loadRatio - 1) * 8);
end

result = struct();
result.patientsPerYear = annualDemand;
result.dailyDemand = dailyDemand;
result.capacityPerDay = throughputDaily;
result.annualCapacity = throughputDaily * workingDays;
result.coveragePercent = 100 * coverage;
result.bottleneck = stageNames{bottleneckIdx};
result.bottleneckIndex = bottleneckIdx;
result.utilization = struct('acquisition',100*util(1),'network',100*util(2),'ai',100*util(3),'review',100*util(4));
result.capacity = struct('acquisitionPerDay',cameraDaily,'networkPerDay',networkDaily,'aiPerDay',aiDaily,'reviewPerDay',reviewDaily);
result.averageWaitHours = waitHours;
result.assumptions = P;
result.simulink = struct('available',false,'modelName','','message','');

% Build and run the visual Simulink digital twin when Simulink is licensed.
try
    if P.runSimulink && license('test','Simulink')
        modelName = generateRetinaXSimulink(P);
        set_param(modelName,'StopTime','1');
        sim(modelName,'StopTime','1');
        result.simulink.available = true;
        result.simulink.modelName = modelName;
        result.simulink.message = 'Simulink model generated and simulated successfully.';
    else
        result.simulink.message = 'Simulink license not available; analytical capacity model returned.';
    end
catch ME
    result.simulink.message = ['Simulink model could not be run: ' ME.message];
end
if returnJson
    result = jsonencode(result);
end
end

function P = applyDefaults(P)
def = retinaXSimulationParameters();
fields = fieldnames(def);
for i=1:numel(fields)
    f=fields{i};
    if ~isfield(P,f) || isempty(P.(f)), P.(f)=def.(f); end
end
if ~isfield(P,'runSimulink'), P.runSimulink = true; end
end
