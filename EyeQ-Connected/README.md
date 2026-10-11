# EyeQ RETINAX

**Explainable AI prototype for diabetic retinopathy (DR) screening**,
built around a React frontend, Flask API, and MATLAB image-analysis
pipeline. The project also includes a rural telemedicine capacity
simulation and an optional Simulink digital-twin workflow.

> **Important:** This is a research/hackathon prototype, not a
> clinically validated medical device. Do not use its outputs to
> diagnose patients or make treatment decisions. Unless a properly
> trained and validated model is installed, predictions may be
> demo-only.

## Overview

EyeQ RETINAX demonstrates an end-to-end workflow for reviewing retinal
fundus images:

1.  A user uploads an image through the web interface.
2.  The Flask backend passes the image to the MATLAB pipeline.
3.  MATLAB assesses image quality and preprocesses the image.
4.  The model predicts one of five diabetic-retinopathy severity levels.
5.  The pipeline can produce a Grad-CAM visualization, heuristic lesion
    evidence, a risk summary, and a screening report.
6.  Results are returned to the frontend for review.

The repository also includes bulk screening and a **Rural Telemedicine
Simulation** page for exploring hypothetical service capacity, resource
utilization, bottlenecks, and queue delays.

## Features

-   Fundus image upload and screening workflow
-   Image-quality assessment and preprocessing
-   Five-level DR classification pipeline
-   Grad-CAM heatmap/overlay for model explainability
-   Heuristic lesion-evidence analysis
-   Screening result and report generation
-   Bulk-screening interface
-   Dashboard based on recorded result files
-   Rural telemedicine capacity simulation
-   Optional Simulink model generation and simulation, when the required
    MATLAB/Simulink license is available
-   Resource-optimization experiment for a configurable coverage target

## Technology stack

  Component                           Technology
  ----------------------------------- ---------------------------------------------------
  Frontend                            React, Vite, React Router, Tailwind CSS, Recharts
  Backend                             Python, Flask, Flask-CORS
  Image analysis and model pipeline   MATLAB
  Model architecture                  ResNet-18 transfer-learning pipeline
  Explainability                      Grad-CAM plus heuristic image-processing evidence
  Simulation                          MATLAB; Simulink where licensed

## Repository structure

``` text
EyeQ-Connected/
├── frontend/          # React/Vite web application
├── backend/           # Flask API connecting the UI to MATLAB
├── matlab/            # Image processing, DR model, reports and simulation scripts
├── results/           # Runtime screening results (may be generated locally)
├── uploads/           # Uploaded images (runtime data; do not commit private data)
└── README.md
```

Important MATLAB files include:

-   `DRExplainabilityApp.m` --- standalone MATLAB app
-   `apiAnalyzeImage.m` and `apiAnalyzeImageFast.m` --- image-analysis
    adapters
-   `preprocessFundusImage.m` --- fundus image preprocessing
-   `assessImageQuality.m` --- image-quality checks
-   `predictDR.m` --- prediction wrapper
-   `computeGradCAMHeatmap.m` --- Grad-CAM visualization
-   `detectLesions.m` --- heuristic lesion-evidence analysis
-   `generateScreeningReport.m` --- report generation
-   `runRetinaXSimulation.m` --- telemedicine capacity simulation
-   `generateRetinaXSimulink.m` --- Simulink model generation
-   `optimizeRetinaXResources.m` --- resource-configuration exploration

## Requirements

Install the following before running the full connected application:

-   Git
-   Node.js and npm
-   Python 3.10+ recommended (use a version compatible with your MATLAB
    release and MATLAB Engine, if using it)
-   MATLAB R2022b or later recommended
-   MATLAB toolboxes/support packages as needed:
    -   Deep Learning Toolbox
    -   ResNet-18 network support package
    -   Image Processing Toolbox
    -   Statistics and Machine Learning Toolbox
    -   Computer Vision Toolbox recommended for additional lesion
        markers
-   Simulink, if you want to run the Simulink digital-twin workflow

Exact compatibility depends on your installed MATLAB, Python, and
toolbox versions.

## Setup and run

Run the commands from the repository root (`EyeQ-Connected/`).

### 1. Start the backend

Open a terminal:

``` powershell
cd backend
py -m pip install -r requirements.txt
py server.py
```

The Flask API is expected to run at:

``` text
http://127.0.0.1:5000
```

#### MATLAB connection

The backend uses MATLAB for the analysis pipeline. If MATLAB Engine for
Python is required in your environment, open MATLAB and run:

``` matlab
cd(fullfile(matlabroot,'extern','engines','python'))
```

Then use the installation command appropriate for your MATLAB/Python
version in a terminal, for example:

``` powershell
py -m pip install .
```

The backend also contains a fallback that invokes the MATLAB executable
directly, but MATLAB still needs to be installed and accessible.

### 2. Configure and start the frontend

In a second terminal:

``` powershell
cd frontend
npm install
```

Copy the example environment file to `.env` if you need to change the
API address:

``` powershell
Copy-Item .env.example .env
```

Default setting:

``` env
VITE_API_URL=http://127.0.0.1:5000
```

Start the development server:

``` powershell
npm run dev
```

Open the local URL printed by Vite in your terminal.

To create a production build:

``` powershell
npm run build
```

### 3. Run the standalone MATLAB app (optional)

To use the MATLAB-only interface, open MATLAB, set its Current Folder to
`matlab/`, and run:

``` matlab
DRExplainabilityApp
```

Use the app to select a retinal fundus image and run the screening
pipeline.

### 4. Run the simulation

With the backend and frontend running, open the application's
**Simulation** page. The page sends configurable assumptions to the
backend, which runs the MATLAB simulation. Simulink model
generation/simulation requires a compatible Simulink installation and
license.

## Model and data notes

-   The MATLAB folder may include `trainedDRNet.mat`. Keep it in the
    location expected by the MATLAB scripts.
-   If a valid trained model is not available, the pipeline may use a
    demo/untrained classification head. In that case, predicted DR
    grades are **not meaningful clinical predictions**.
-   The repository's scripts and sample CSV files are not, by
    themselves, evidence of clinical validation.
-   To train a real model, obtain a dataset you are permitted to use,
    review its licence and data-use terms, organize images and labels in
    the format expected by `trainDRModel.m`, and follow the instructions
    in `matlab/README.md`.
-   Evaluate any trained model on held-out data and report suitable
    metrics, class-wise performance, calibration, and limitations before
    making research claims.

## Privacy and safe use

-   Do not commit identifiable patient images, patient reports, medical
    records, credentials, or private datasets.
-   Review all files before publishing the repository, especially PDFs,
    uploaded images, generated reports, `.env` files, and runtime
    folders.
-   Use synthetic or appropriately de-identified sample data for
    demonstrations.
-   The output is intended for prototyping and research only, not
    diagnosis or treatment.

## Troubleshooting

-   **Frontend cannot reach the API:** Confirm the Flask server is
    running and `VITE_API_URL` points to the correct address. Restart
    Vite after changing `.env`.
-   **MATLAB is not found:** Check that MATLAB is installed and the
    executable is available to the backend, or configure MATLAB Engine
    for Python.
-   **`resnet18` is unavailable:** Install the ResNet-18 support package
    through MATLAB Add-On Explorer.
-   **Toolbox function errors:** Confirm the required MATLAB toolboxes
    are licensed and installed.
-   **Simulink simulation does not run:** Confirm Simulink is
    installed/licensed and review the MATLAB command-window error.
-   **Predictions are marked demo-only:** Verify that a valid, trained
    `trainedDRNet.mat` exists where the pipeline expects it. Do not
    treat demo outputs as medical findings.

For component-specific instructions, see `backend/README.md`,
`frontend/README.md`, and `matlab/README.md`.

## Project status

This is a prototype intended for development, demonstration, and further
validation. Test the complete workflow in your own environment before
presenting it as runnable, and clearly distinguish simulated results
from real screening outcomes.

## License

No license is specified in this repository yet. Add a `LICENSE` file
before granting others permission to reuse or redistribute the project.
