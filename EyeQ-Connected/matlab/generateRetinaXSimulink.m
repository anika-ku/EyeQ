function modelName = generateRetinaXSimulink(P)
%GENERATERETINAXSIMULINK Create a lightweight visual digital twin.
% The model represents demand moving through acquisition, network, AI and
% specialist-review capacity. It is regenerated from the current parameters.

if nargin < 1 || isempty(P), P = retinaXSimulationParameters(); end
if ischar(P) || isstring(P), P = jsondecode(char(P)); end

modelName = 'RETINA_X_Rural_DigitalTwin';
if bdIsLoaded(modelName), close_system(modelName,0); end
if exist([modelName '.slx'],'file'), delete([modelName '.slx']); end

new_system(modelName); open_system(modelName);
set_param(modelName,'StopTime','1');

% Stage capacities are represented as constant signals. The analytical
% engine computes the exact bottleneck; the model provides an auditable
% Simulink representation for demonstration and further extension.
blocks = {
 {'Demand','simulink/Sources/Constant',[30 80 130 110],P.patientsPerYear/P.workingDaysPerYear},
 {'Acquisition','simulink/Sources/Constant',[190 20 300 50],P.numCameras*P.imagesPerCameraPerHour*P.operatingHoursPerDay},
 {'Network','simulink/Sources/Constant',[190 80 300 110],(P.bandwidthMbps*1e6/8)*3600*P.operatingHoursPerDay/(P.imageSizeMB*1024^2)},
 {'AI','simulink/Sources/Constant',[190 140 300 170],P.aiWorkers*P.aiImagesPerHour*P.operatingHoursPerDay},
 {'Review','simulink/Sources/Constant',[190 200 300 230],P.reviewers*P.reviewsPerHour*P.operatingHoursPerDay},
 {'CapacityMux','simulink/Signal Routing/Mux',[350 65 380 225],4},
 {'CapacityDisplay','simulink/Sinks/Display',[450 95 560 125],[]}
};
for i=1:numel(blocks)
    b=blocks{i};
    add_block(b{2},[modelName '/' b{1}],'Position',b{3});
    if ~isempty(b{4}) && strcmp(b{2},'simulink/Sources/Constant')
        set_param([modelName '/' b{1}],'Value',num2str(b{4}));
    elseif strcmp(b{1},'CapacityMux')
        set_param([modelName '/' b{1}],'Inputs','4');
    end
end

add_line(modelName,'Acquisition/1','CapacityMux/1');
add_line(modelName,'Network/1','CapacityMux/2');
add_line(modelName,'AI/1','CapacityMux/3');
add_line(modelName,'Review/1','CapacityMux/4');
add_line(modelName,'CapacityMux/1','CapacityDisplay/1');

add_block('simulink/Sinks/Display',[modelName '/DemandDisplay'],'Position',[190 280 300 310]);
add_line(modelName,'Demand/1','DemandDisplay/1');

save_system(modelName,[modelName '.slx']);
end
