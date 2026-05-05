# Political Bias Detector

A full-stack MLOps system that classifies news articles as Left, Center, or Right using fine-tuned BERT and DistilBERT models. Includes a React frontend, FastAPI backend, and a cloud training pipeline on AWS ECS Fargate.

## Project Structure

```
MSML605_Final/
├── dataset.py          # PyTorch dataset class
├── preprocess.py       # Text cleaning, label encoding, train/val/test split
├── train.py            # Fine-tuning script (BERT / DistilBERT)
├── validate.py         # Validation set evaluation
├── test.py             # Test set evaluation
├── run_pipeline.sh     # Orchestrates the full pipeline locally or on ECS
├── Dockerfile.train    # Container image for ECS training runs
├── requirements.txt    # Training pipeline dependencies
├── requirements-api.txt
├── api/                # FastAPI backend
│   ├── main.py
│   ├── routers/        # predict, jobs, compare
│   ├── services/       # inference, pipeline, compare logic
│   ├── schemas/
│   └── core/config.py
└── frontend/           # React + Vite + Tailwind frontend
    └── src/
```

---

## Running the Frontend Locally

The backend is already hosted on EC2. You only need to run the frontend.

### Prerequisites

- Node.js 18+
- npm

### Steps

```bash
cd frontend
npm install
npm run dev
```

The app will be available at `http://localhost:5173`.

### Environment

The `frontend/.env.local` file points to the EC2 backend:

```
VITE_API_URL=http://52.53.204.230:8000
```

No changes needed unless the backend URL changes.

---

## Frontend Features

| Tab | What it does |
|---|---|
| **Classify** | Paste article text → get Left / Center / Right prediction with confidence scores |
| **Compare** | Run full test set evaluation on BERT and DistilBERT in parallel and compare per-class metrics |
| **Train** | Trigger a pipeline job (full, preprocess only, or evaluate only) and watch logs stream live |

---

## Pipeline Modes (`run_pipeline.sh`)

The training pipeline supports three modes controlled by environment variables:

| Mode | Env vars | What runs |
|---|---|---|
| Full pipeline | `MODEL=bert` | preprocess → train → validate → test |
| Preprocess only | `PREPROCESS_ONLY=true` | preprocess → upload splits to S3 → stop |
| Evaluate only | `SKIP_TRAIN=true` | pull model from S3 → validate → test |


---

## API Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/predict` | Classify article text; returns label, confidence, per-class probabilities |
| `POST` | `/compare/run` | Run test set evaluation on two models in parallel; returns side-by-side metrics |
| `POST` | `/jobs/run` | Trigger a pipeline job (full / preprocess_only / skip_train) |
| `GET` | `/jobs/{job_id}` | Poll job status and stream logs |
| `GET` | `/health` | Health check |

---

## AWS Infrastructure

| Service | Purpose |
|---|---|
| S3 | Stores dataset, preprocessed splits, and trained model artifacts under `saved_models/` |
| ECR | Hosts the `Dockerfile.train` container image |
| ECS Fargate | Runs isolated, serverless training tasks |
| CloudWatch | Captures container logs; polled by the API to stream progress to the frontend |
| IAM | Execution role for ECS (image pull, log write); task role for S3 access |

---

## Experiment Tracking

ClearML is used to register training runs and log evaluation metrics (accuracy, precision, recall, F1) from `validate.py` and `test.py`. Configure credentials via environment variables or AWS Secrets Manager before running on ECS.
