# EyeQ backend

Flask API that connects the React dashboard to the MATLAB DR explainability pipeline.

## 1. Install Python packages

```powershell
cd backend
py -m pip install -r requirements.txt
```

## 2. Install MATLAB Engine for Python

In MATLAB, run:

```matlab
cd(fullfile(matlabroot,'extern','engines','python'))
```

Then in PowerShell run the install command shown for your MATLAB/Python version, for example:

```powershell
py -m pip install .
```

The server also has a fallback that calls the `matlab` executable directly if the Engine package is not available.

## 3. MATLAB requirements

- MATLAB R2022b+ recommended
- Deep Learning Toolbox
- Deep Learning Toolbox Model for ResNet-18 Network
- Image Processing Toolbox
- Computer Vision Toolbox (recommended)
- Statistics and Machine Learning Toolbox

Put `trainedDRNet.mat` in `matlab/` for a trained model. Without it, the existing MATLAB pipeline deliberately uses its demo/untrained model and marks the output as demo-only.

## 4. Run

Terminal 1:

```powershell
cd backend
py server.py
```

Terminal 2:

```powershell
cd frontend
npm install
npm run dev
```

The frontend uses `http://127.0.0.1:5000` by default. Set `VITE_API_URL` if the backend is elsewhere.
