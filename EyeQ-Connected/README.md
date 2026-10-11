# EyeQ — React + MATLAB connected build

This folder merges the EyeQ React frontend with the APTOS/DR MATLAB pipeline.

**Flow:** React upload → Flask API → MATLAB preprocessing + quality/fundus checks → trained DR model → Grad-CAM → heuristic lesion evidence → JSON + visualization files → React Results.

Also included:
- Bulk Screening route (`/bulk-screening`) using the same backend pipeline.
- Dashboard counters sourced from completed backend result files instead of hard-coded demo numbers.
- Care pathway / illustrative cost information on Results.
- MATLAB `apiAnalyzeImage.m` adapter so the existing `.m` functions remain the inference source.

See `backend/README.md` for setup.

## Simulation module

The connected prototype now includes a live **Rural Telemedicine Simulation** page at `#/simulation`.
It sends district-level assumptions to MATLAB through `POST /api/simulation`, runs `runRetinaXSimulation.m`, and, when a Simulink license is available, generates and simulates `RETINA_X_Rural_DigitalTwin.slx` with `generateRetinaXSimulink.m`.

Inputs include patients/year, working days, operating hours, cameras, acquisition rate, bandwidth, image size, AI workers/throughput, and specialist reviewers/review rate. Outputs include sustainable daily/annual capacity, coverage, stage utilization, bottleneck, and estimated queue delay.

The **Optimize Resources** action calls `optimizeRetinaXResources.m` and searches engineering resource configurations against a 90% coverage target. This is an engineering planning aid, not a clinical or procurement recommendation.

## Dashboard data

The dashboard no longer contains a fabricated 10-month trend. Its screening activity chart is built from timestamps of actual completed `results/*/result.json` records. With no recorded screenings, the chart shows an explicit empty state.
