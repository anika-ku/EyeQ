import os, json, uuid, shutil, tempfile, subprocess, sys
from pathlib import Path
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS

ROOT = Path(__file__).resolve().parent.parent
MATLAB_DIR = ROOT / 'matlab'
UPLOAD_DIR = ROOT / 'uploads'
RESULT_DIR = ROOT / 'results'
UPLOAD_DIR.mkdir(exist_ok=True)
RESULT_DIR.mkdir(exist_ok=True)

app = Flask(__name__)
CORS(app)


def matlab_quote(s: str) -> str:
    return "'" + str(s).replace("'", "''") + "'"


# Keep a single MATLAB Engine alive for the whole Flask process. Starting MATLAB is
# expensive; reusing the engine is the largest latency improvement for local use.
_ENGINE = None
_ENGINE_ERROR = None

def get_matlab_engine():
    global _ENGINE, _ENGINE_ERROR
    if _ENGINE is not None:
        return _ENGINE
    try:
        import matlab.engine  # type: ignore
        _ENGINE = matlab.engine.start_matlab()
        _ENGINE.addpath(str(MATLAB_DIR), nargout=0)
        return _ENGINE
    except Exception as e:
        _ENGINE_ERROR = e
        return None


def run_matlab(image_path: Path, result_dir: Path, fast: bool = False):
    result_dir.mkdir(parents=True, exist_ok=True)
    eng = get_matlab_engine()
    if eng is not None:
        fn = eng.apiAnalyzeImageFast if fast else eng.apiAnalyzeImage
        out = fn(str(image_path), str(result_dir), nargout=1)
        if isinstance(out, str):
            return json.loads(out)
        return out

    # MATLAB Engine is unavailable. For bulk mode we still launch MATLAB only
    # once for the whole batch (see run_matlab_batch_fallback).
    matlab_exe = os.environ.get('MATLAB_EXECUTABLE') or os.environ.get('MATLAB_BIN') or 'matlab'
    fn_name = 'apiAnalyzeImageFast' if fast else 'apiAnalyzeImage'
    cmd = [matlab_exe, '-batch',
           f"addpath({matlab_quote(MATLAB_DIR)}); {fn_name}({matlab_quote(image_path)},{matlab_quote(result_dir)});"]
    try:
        subprocess.run(cmd, check=True, capture_output=True, text=True, timeout=300)
    except FileNotFoundError:
        detail = f' MATLAB Engine error: {_ENGINE_ERROR}' if _ENGINE_ERROR else ''
        raise RuntimeError('MATLAB Engine for Python is not installed and MATLAB executable was not found.' + detail)
    except subprocess.CalledProcessError as e:
        raise RuntimeError((e.stderr or e.stdout or 'MATLAB failed').strip())
    result_file = result_dir / 'result.json'
    if not result_file.exists():
        raise RuntimeError('MATLAB completed without producing result.json')
    return json.loads(result_file.read_text(encoding='utf-8'))


def run_matlab_batch_fallback(items):
    """Run all fast bulk images in one MATLAB process when Engine isn't available."""
    manifest_path = UPLOAD_DIR / f'bulk-{uuid.uuid4().hex}.json'
    manifest = {'items': [{'imagePath': str(p), 'outputDir': str(d)} for p, d in items]}
    manifest_path.write_text(json.dumps(manifest), encoding='utf-8')
    matlab_exe = os.environ.get('MATLAB_EXECUTABLE') or os.environ.get('MATLAB_BIN') or 'matlab'
    cmd = [matlab_exe, '-batch',
           f"addpath({matlab_quote(MATLAB_DIR)}); apiAnalyzeBatchFast({matlab_quote(manifest_path)});"]
    try:
        subprocess.run(cmd, check=True, capture_output=True, text=True, timeout=max(300, 60 * len(items)))
    except FileNotFoundError:
        raise RuntimeError('MATLAB executable was not found. Install MATLAB Engine for Python or set MATLAB_EXECUTABLE.')
    except subprocess.CalledProcessError as e:
        raise RuntimeError((e.stderr or e.stdout or 'MATLAB bulk analysis failed').strip())
    finally:
        try: manifest_path.unlink()
        except OSError: pass

    results = []
    for image_path, result_dir in items:
        result_file = result_dir / 'result.json'
        if result_file.exists():
            results.append(json.loads(result_file.read_text(encoding='utf-8')))
        else:
            results.append({'error': 'MATLAB completed without producing result.json', 'analysisMode': 'fast'})
    return results

def publicize(result, job_id):
    def url(name):
        return f'/api/results/{job_id}/{name}'
    if result.get('gradCamFile'):
        result['gradCamUrl'] = url(result['gradCamFile'])
    if result.get('lesionOverlayFile'):
        result['lesionOverlayUrl'] = url(result['lesionOverlayFile'])
    result['jobId'] = job_id
    return result


@app.get('/api/health')
def health():
    return jsonify({'ok': True, 'matlabDir': str(MATLAB_DIR)})


@app.post('/api/analyze')
def analyze():
    if 'image' not in request.files:
        return jsonify({'error': 'image is required'}), 400
    f = request.files['image']
    if not f.filename:
        return jsonify({'error': 'empty filename'}), 400
    ext = Path(f.filename).suffix.lower()
    if ext not in {'.jpg', '.jpeg', '.png', '.tif', '.tiff', '.bmp'}:
        return jsonify({'error': 'unsupported image type'}), 400
    job_id = uuid.uuid4().hex
    job_dir = RESULT_DIR / job_id
    job_dir.mkdir(parents=True, exist_ok=True)
    image_path = UPLOAD_DIR / f'{job_id}{ext}'
    f.save(image_path)
    try:
        result = run_matlab(image_path, job_dir)
        return jsonify(publicize(result, job_id))
    except Exception as e:
        return jsonify({'error': str(e), 'jobId': job_id}), 500
    finally:
        try: image_path.unlink()
        except OSError: pass


@app.post('/api/bulk-analyze')
def bulk_analyze():
    files = request.files.getlist('images')
    if not files:
        return jsonify({'error': 'images are required'}), 400

    prepared = []
    results = [None] * len(files)
    allowed = {'.jpg', '.jpeg', '.png', '.tif', '.tiff', '.bmp'}

    for idx, f in enumerate(files):
        ext = Path(f.filename or '').suffix.lower()
        if ext not in allowed:
            results[idx] = {'filename': f.filename, 'error': 'unsupported image type'}
            continue
        job_id = uuid.uuid4().hex
        job_dir = RESULT_DIR / job_id
        job_dir.mkdir(parents=True, exist_ok=True)
        image_path = UPLOAD_DIR / f'{job_id}{ext}'
        f.save(image_path)
        prepared.append((idx, f.filename, image_path, job_dir, job_id))

    # Fast mode deliberately skips Grad-CAM and lesion overlays. Those are
    # generated later for individual/flagged cases through /api/analyze.
    engine = get_matlab_engine()
    try:
        if engine is not None:
            for idx, filename, image_path, job_dir, job_id in prepared:
                try:
                    raw = engine.apiAnalyzeImageFast(str(image_path), str(job_dir), nargout=1)
                    result = json.loads(raw) if isinstance(raw, str) else raw
                    result['filename'] = filename
                    results[idx] = publicize(result, job_id)
                except Exception as e:
                    results[idx] = {'filename': filename, 'error': str(e), 'jobId': job_id}
        else:
            batch_items = [(p, d) for _, _, p, d, _ in prepared]
            batch_results = run_matlab_batch_fallback(batch_items)
            for item, raw in zip(prepared, batch_results):
                idx, filename, image_path, job_dir, job_id = item
                raw['filename'] = filename
                results[idx] = publicize(raw, job_id)
    finally:
        for _, _, image_path, _, _ in prepared:
            try: image_path.unlink()
            except OSError: pass

    return jsonify({'results': results, 'analysisMode': 'fast-bulk'})


@app.get('/api/results/<job_id>/<filename>')
def result_file(job_id, filename):
    return send_from_directory(RESULT_DIR / job_id, filename)


@app.get('/api/treatment')
def treatment():
    level = request.args.get('level', '0')
    try: level = max(0, min(4, int(level)))
    except ValueError: level = 0
    # Illustrative clinician-guided ranges, kept editable in costConfig.m.
    cfg = {
        0: {'severity': 'No DR', 'followUp': 'Routine diabetic eye screening', 'costINR': '₹500–₹1,500', 'note': 'Illustrative range; local pricing varies.'},
        1: {'severity': 'Mild NPDR', 'followUp': 'Ophthalmology follow-up as clinically appropriate', 'costINR': '₹800–₹2,000', 'note': 'Illustrative range; not a prescription.'},
        2: {'severity': 'Moderate NPDR', 'followUp': 'Ophthalmology review recommended', 'costINR': '₹1,000–₹3,000', 'note': 'Illustrative range; clinician decides care.'},
        3: {'severity': 'Severe NPDR', 'followUp': 'Prompt ophthalmology assessment', 'costINR': '₹1,500–₹5,000+', 'note': 'Illustrative range; clinician decides care.'},
        4: {'severity': 'Proliferative DR', 'followUp': 'Prompt specialist assessment', 'costINR': '₹5,000–₹30,000+', 'note': 'Illustrative range; treatment depends on findings.'},
    }
    return jsonify(cfg[level])


@app.post('/api/simulation/optimize')
def simulation_optimize():
    payload = request.get_json(silent=True) or {}
    try:
        target = float(payload.get('targetCoveragePercent', 90))
    except (TypeError, ValueError):
        return jsonify({'error': 'Invalid targetCoveragePercent'}), 400
    payload['targetCoveragePercent'] = target
    try:
        return jsonify(run_matlab_optimization(payload))
    except Exception as e:
        return jsonify({'error': str(e)}), 500


def run_matlab_optimization(params):
    eng = get_matlab_engine()
    encoded = json.dumps(params)
    if eng is not None:
        raw = eng.optimizeRetinaXResources(encoded, nargout=1)
        return json.loads(raw) if isinstance(raw, str) else raw
    matlab_exe = os.environ.get('MATLAB_EXECUTABLE') or os.environ.get('MATLAB_BIN') or 'matlab'
    request_path = UPLOAD_DIR / f'optimization-{uuid.uuid4().hex}.json'
    result_path = RESULT_DIR / f'optimization-{uuid.uuid4().hex}.json'
    request_path.write_text(encoded, encoding='utf-8')
    command = f"addpath({matlab_quote(MATLAB_DIR)}); r=optimizeRetinaXResources(fileread({matlab_quote(request_path)})); fid=fopen({matlab_quote(result_path)},'w'); fwrite(fid,r,'char'); fclose(fid);"
    try:
        subprocess.run([matlab_exe, '-batch', command], check=True, capture_output=True, text=True, timeout=300)
        if not result_path.exists(): raise RuntimeError('MATLAB completed without producing optimization results.')
        return json.loads(result_path.read_text(encoding='utf-8'))
    except FileNotFoundError:
        raise RuntimeError('MATLAB executable was not found. Set MATLAB_BIN or MATLAB_EXECUTABLE.')
    except subprocess.CalledProcessError as e:
        raise RuntimeError((e.stderr or e.stdout or 'MATLAB optimization failed').strip())
    finally:
        for f in (request_path, result_path):
            try: f.unlink()
            except OSError: pass

@app.post('/api/simulation')
def simulation():
    """Run the rural telemedicine capacity simulation and companion Simulink model."""
    payload = request.get_json(silent=True) or {}
    allowed = {
        'patientsPerYear': int, 'workingDaysPerYear': int, 'operatingHoursPerDay': float,
        'numCameras': int, 'imagesPerCameraPerHour': float, 'bandwidthMbps': float,
        'imageSizeMB': float, 'aiWorkers': int, 'aiImagesPerHour': float,
        'reviewers': int, 'reviewsPerHour': float, 'referableRatePercent': float,
    }
    params = {}
    for key, caster in allowed.items():
        if key in payload:
            try: params[key] = caster(payload[key])
            except (TypeError, ValueError): return jsonify({'error': f'Invalid value for {key}'}), 400
    try:
        raw = run_matlab_simulation(params)
        return jsonify(raw)
    except Exception as e:
        return jsonify({'error': str(e)}), 500


def run_matlab_simulation(params):
    """Use MATLAB Engine when available, otherwise call MATLAB -batch once."""
    eng = get_matlab_engine()
    if eng is not None:
        import json as _json
        raw = eng.runRetinaXSimulation(_json.dumps(params), nargout=1)
        return json.loads(raw) if isinstance(raw, str) else raw

    matlab_exe = os.environ.get('MATLAB_EXECUTABLE') or os.environ.get('MATLAB_BIN') or 'matlab'
    request_path = UPLOAD_DIR / f'simulation-{uuid.uuid4().hex}.json'
    result_path = RESULT_DIR / f'simulation-{uuid.uuid4().hex}.json'
    request_path.write_text(json.dumps(params), encoding='utf-8')
    matlab_dir = matlab_quote(MATLAB_DIR)
    req = matlab_quote(request_path)
    out = matlab_quote(result_path)
    command = f"addpath({matlab_dir}); r=runRetinaXSimulation(fileread({req})); fid=fopen({out},'w'); fwrite(fid,r,'char'); fclose(fid);"
    try:
        subprocess.run([matlab_exe, '-batch', command], check=True, capture_output=True, text=True, timeout=300)
        if not result_path.exists(): raise RuntimeError('MATLAB completed without producing simulation results.')
        return json.loads(result_path.read_text(encoding='utf-8'))
    except FileNotFoundError:
        raise RuntimeError('MATLAB executable was not found. Set MATLAB_BIN or MATLAB_EXECUTABLE.')
    except subprocess.CalledProcessError as e:
        raise RuntimeError((e.stderr or e.stdout or 'MATLAB simulation failed').strip())
    finally:
        for f in (request_path, result_path):
            try: f.unlink()
            except OSError: pass

@app.get('/api/dashboard')
def dashboard():
    # All dashboard history comes from actual completed result files. No synthetic
    # month-by-month numbers are created.
    rows = []
    for p in RESULT_DIR.glob('*/result.json'):
        try:
            data = json.loads(p.read_text(encoding='utf-8'))
            data['_completedAt'] = p.stat().st_mtime
            rows.append(data)
        except Exception:
            pass
    rows.sort(key=lambda x: x['_completedAt'])
    levels = [r.get('drLevel') for r in rows if isinstance(r.get('drLevel'), int)]
    from datetime import datetime
    buckets = {}
    for r in rows:
        dt = datetime.fromtimestamp(r['_completedAt'])
        key = dt.strftime('%Y-%m')
        buckets.setdefault(key, 0)
        buckets[key] += 1
    trend = [{'month': key, 'screenings': buckets[key]} for key in sorted(buckets.keys())[-10:]]
    stats = {
        'totalScreenings': len(rows),
        'positiveCases': sum(1 for x in levels if x >= 1),
        'referableCases': sum(1 for x in levels if x >= 2),
        'trend': trend,
        'hasHistoricalData': bool(trend),
        'recentActivity': [
            {'title': f"{r.get('label','Screening')} completed", 'time': datetime.fromtimestamp(r['_completedAt']).strftime('%d %b %Y, %H:%M')}
            for r in rows[-6:][::-1]
        ],
    }
    return jsonify(stats)


if __name__ == '__main__':
    app.run(host='127.0.0.1', port=int(os.environ.get('PORT', '5000')), debug=False, use_reloader=False)
