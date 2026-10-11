function result = optimizeRetinaXResources(P)
%OPTIMIZERETINAXRESOURCES Find a low-resource configuration meeting target coverage.
returnJson = false;
if nargin < 1 || isempty(P), P = retinaXSimulationParameters(); end
if ischar(P) || isstring(P), P = jsondecode(char(P)); returnJson = true; end
if ~isfield(P,'targetCoveragePercent'), P.targetCoveragePercent = 90; end

best = [];
for cameras = 5:5:50
    for aiWorkers = 1:12
        for reviewers = 1:20
            for bandwidth = [2 5 10 20 50]
                Q = P;
                Q.runSimulink = false;
                Q.numCameras = cameras;
                Q.aiWorkers = aiWorkers;
                Q.reviewers = reviewers;
                Q.bandwidthMbps = bandwidth;
                r = runRetinaXSimulation(Q);
                if ischar(r), r = jsondecode(r); end
                if r.coveragePercent >= P.targetCoveragePercent
                    % Simple transparent engineering cost: hardware + network + staff.
                    cost = cameras*1 + aiWorkers*4 + reviewers*3 + bandwidth*0.25;
                    if isempty(best) || cost < best.cost
                        best = struct('cameras',cameras,'aiWorkers',aiWorkers,'reviewers',reviewers,'bandwidthMbps',bandwidth,'coveragePercent',r.coveragePercent,'capacityPerDay',r.capacityPerDay,'costIndex',cost,'bottleneck',r.bottleneck);
                    end
                end
            end
        end
    end
end
if isempty(best)
    result = struct('found',false,'message','No tested configuration reached the target coverage. Increase resources or revise assumptions.');
else
    result = struct('found',true,'targetCoveragePercent',P.targetCoveragePercent,'recommendation',best,'message','Engineering resource configuration only; validate assumptions before deployment.');
end
if returnJson
    result = jsonencode(result);
end
end
