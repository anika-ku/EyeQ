# Explainable AI for Diabetic Retinopathy Screening — Explainability Pipeline Prototype
Smart India Hackathon 2026 — MATLAB / App Designer prototype

## What this is

A working MATLAB prototype of the **explainability pipeline** for a DR screening
system: upload a fundus image → preprocess → classify into 5 ICDR severity
levels → referable/non-referable decision → Grad-CAM heatmap → heuristic
lesion evidence → confidence score → automated report. Built entirely in
MATLAB (no Python) using Deep Learning Toolbox, Image Processing Toolbox,
Computer Vision Toolbox, and Statistics and Machine Learning Toolbox.

**I was not able to run/compile this inside MATLAB before handing it to you**
(no MATLAB available in the environment I built it in), so please do a short
test pass before your demo — see "Known things to check" below.

## Files

| File | Purpose |
|---|---|
| `DRExplainabilityApp.m` | Main App Designer-style app (run this) |
| `preprocessFundusImage.m` | FOV crop, resize, CLAHE contrast enhancement |
| `assessImageQuality.m` | Brightness/contrast/sharpness quality gate |
| `buildDRModel.m` | ResNet-18 transfer-learning architecture (untrained head) |
| `trainDRModel.m` | **Run separately** to train on a real DR dataset |
| `predictDR.m` | Classification wrapper, returns sorted class probabilities |
| `computeGradCAMHeatmap.m` | Grad-CAM heatmap + overlay (Deep Learning Toolbox) |
| `detectLesions.m` | Heuristic microaneurysm/hemorrhage/exudate/neovascularization detection |
| `lesionBasedRiskScore.m` | Independent statistics-based cross-check (uses `normcdf`) |
| `generateScreeningReport.m` | Builds the text report shown at the bottom of the app |

## Requirements

- MATLAB R2022b or later recommended (uses `uigridlayout`, `gradCAM`)
- Deep Learning Toolbox
- **Deep Learning Toolbox Model for ResNet-18 Network** (separate Add-On —
  install via Add-On Explorer if `resnet18` errors with "not installed")
- Image Processing Toolbox
- Computer Vision Toolbox (used for nicer lesion markers via `insertShape`;
  the app still runs without it, just without marker circles)
- Statistics and Machine Learning Toolbox (`prctile`, `normcdf`)

## Running it

1. Put all files in one folder and make it your MATLAB **Current Folder**
   (or `addpath` it).
2. In the Command Window:
   ```matlab
   DRExplainabilityApp
   ```
3. Click **Upload Fundus Image...**, pick a `.jpg`/`.png` fundus photo,
   then click **Run Screening Pipeline**.

On first run (no trained model present) the app displays a red **DEMO MODEL**
banner and uses an ImageNet-pretrained ResNet-18 backbone with an untrained
classification head — this proves out the *entire pipeline* (real forward
pass, real Grad-CAM gradients, real image-processing lesion heuristics) but
the DR grade itself is **not clinically meaningful** yet. The report and UI
say this explicitly so nobody mistakes it for a validated result.

## Getting a real trained model

1. Download a DR dataset — good options:
   - **IDRiD** (Indian Diabetic Retinopathy Image Dataset) — genuinely Indian
     clinical data, a strong fit for your "rural India" framing
   - APTOS 2019 Blindness Detection (Kaggle)
   - EyePACS Diabetic Retinopathy Detection (Kaggle)
   - Messidor-2
2. Organise it into folders `0_NoDR/ 1_Mild/ 2_Moderate/ 3_Severe/ 4_Proliferative/`
   inside a `dataset/` folder next to these scripts.
3. Edit and run `trainDRModel.m` (a GPU helps a lot; CPU training will be slow
   but works). It saves `trainedDRNet.mat`.
4. Put `trainedDRNet.mat` next to `DRExplainabilityApp.m` and restart the app —
   the demo banner disappears and predictions come from your trained model.

## Design notes / how it maps to the requirements

- **Preprocessing**: FOV auto-crop (removes black borders common on rural
  camera captures) + CLAHE contrast normalisation, plus a lightweight
  brightness/contrast/sharpness quality gate so obviously bad captures are
  flagged before they reach the model.
- **Classification**: ResNet-18 transfer learning (small enough to train on a
  laptop in a hackathon timeframe), 5-class softmax head, class-weighted loss
  in `trainDRModel.m` to handle DR's typical heavy "No DR" class imbalance.
- **Referable decision**: simple, transparent rule (`Level >= 2`) — easy for
  an ophthalmologist to audit, no hidden logic.
- **Grad-CAM**: MATLAB's built-in `gradCAM`, with automatic fallback if the
  hard-coded ResNet-18 layer name doesn't match your MATLAB version/backbone.
- **Lesion evidence**: intentionally *classical* image processing (top-hat/
  bottom-hat morphology, adaptive thresholding), not a second deep model —
  this keeps it fast, fully explainable (every step is a named, inspectable
  operation), and honest about being heuristic rather than a validated
  detector. This is clearly labelled everywhere it's shown.
- **Statistics and ML Toolbox usage**: `prctile` (optic disc detection) and
  `normcdf` (the independent lesion-based risk cross-check in
  `lesionBasedRiskScore.m`) — a second, independent signal that can flag
  disagreement with the CNN, which is a genuinely useful explainability
  feature to highlight in your presentation ("two independent signals, not
  just one black-box score").
- **Report**: plain-text, generated fresh each run, exportable as `.txt` —
  deliberately simple/robust for a demo; extending to a formatted PDF via
  MATLAB Report Generator would be a natural next step if you have time.

## Known things to check on your machine (since I couldn't test-run this)

- `resnet18` requires its separate support-package install — MATLAB will
  prompt/link to it the first time if missing.
- The Grad-CAM feature-layer name `res5b_relu` is correct for MATLAB's
  standard `resnet18`, but if your MATLAB version names layers differently,
  `computeGradCAMHeatmap.m` automatically falls back to `gradCAM`'s built-in
  layer auto-selection — so it should still work, just double check the
  heatmap looks sensible.
- `insertShape` (lesion markers) needs Computer Vision Toolbox; wrapped in a
  try/catch so the app won't crash without it, but you'll want it for the
  visual markers in your demo.
- Lesion-detection morphology parameters (`strel('disk', 8)` etc.) were
  chosen for typical 224×224 fundus crops — if your images look very
  different in scale/zoom, tune these a bit against a few sample images.
- `assembleNetwork` for the demo (untrained) model assumes the layer graph
  from `buildDRModel.m` is fully connected/valid; if it errors, it usually
  means the ResNet-18 layer names (`fc1000`,
  `ClassificationLayer_predictions`) differ slightly in your MATLAB version —
  run `layerGraph(resnet18)` and check the last few layer names if so.

## Suggested talking points for the SIH presentation

- Multi-signal explainability: Grad-CAM (where the model looked) + lesion
  heuristics (what clinical features are present) + an independent
  statistics-based cross-check that can flag when these disagree.
- Designed for rural deployment: image quality gate catches bad captures
  early; classical lesion detection needs no extra GPU-hungry model.
- Every referable decision is a transparent rule, not a hidden threshold —
  important for clinician trust and regulatory review.
- Clear, honest demo/production labelling — the system never overstates its
  own confidence when it hasn't been validated.
