# PulseNet 🩸

> **AI FOR GOOD 2.0 Hackathon** — Blood Warriors Foundation  
> **Team:** The Brainiacs  
> **AI-Enabled Care Coordination & Access for Thalassemia Patients**

PulseNet is an intelligent care coordination platform designed to bridge the gap between Thalassemia patients and blood donors. By leveraging Machine Learning (XGBoost) and Generative AI (Amazon Bedrock), it optimizes donor mapping, reduces patient stress, and empowers care coordinators with predictive insights.

**Three flows, one platform:**
- 🩸 **Donor** — Pod assignment, transfusion history, availability confirmation, re-engagement nudges
- 🏥 **Patient** — Transfusion calendar, pod health visibility, emergency request trigger
- 🛡️ **Admin / Coordinator** — Full pod control centre, ML-ranked donor matching, emergency board, centre stress forecasting, cycle readiness heatmaps

---

## Real-World Dataset

Trained and seeded on **real Blood Warriors donor data** (1.6MB, 10,000+ donor records) — `Dataset.csv` in repo root. This is actual operational data from the Blood Warriors Foundation, covering blood group distribution, eligibility status, call-to-donation ratios, bridge assignments, and transfusion schedules across Hyderabad centres.

---

## 🚀 Live Demo & Deployment Links

The application is fully deployed and live on AWS App Runner. 

- **Frontend Application (Donor & Admin Dashboards):** `https://64xvp3psvb.us-east-1.awsapprunner.com`
- **Backend API Docs (FastAPI Swagger):** `https://32twtm5enf.us-east-1.awsapprunner.com`

### 🔑 Test Credentials for Judges

We have pre-synced various user personas via AWS Cognito. Use the following credentials to explore the different dashboards:

**Admin / Care Coordinator Dashboard:**
*This persona has full access to AI insights, donor management, and WhatsApp/SNS notification triggers.*
- **Email:** `admin@test.com`
- **Password:** `Admin123!`

**Donor Dashboard:**
*These personas demonstrate real donor profiles synced directly from the RDS database.*
- **Email:** `965f27@pulsenet.ai` *(Donor ID: 2706)*
- **Email:** `107992@pulsenet.ai` *(Donor ID: 3615)*
- **Email:** `86188d@pulsenet.ai` *(Donor ID: 2304)*
- **Email:** `0e2c80@pulsenet.ai` *(Donor ID: 2344)*
- **Email:** `206ce1@pulsenet.ai` *(Donor ID: 2363)*
- **Email:** `782ef4@pulsenet.ai` *(Donor ID: 2557)*
- **Password (for all donors):** `Demo123!`

---

## ✨ Key Features

- **🧠 AI-Driven Donor Ranking:** Uses SageMaker & XGBoost to rank eligible donors based on historical behavior, distance, and reliability.
- **🤖 Generative Insights:** Integrates Amazon Bedrock (Claude 4.5 Haiku) to analyze donor drop-off rates and generate actionable administrative insights.
- **🗺️ Interactive Heatmaps:** Visualizes donor density and patient stress zones (e.g., Hyderabad region) using custom mapping interfaces.
- **🔐 Secure Authentication:** Seamless login flow powered by AWS Cognito, with strict Role-Based Access Control (RBAC).
- **📱 Automated Notifications:** Hooks into AWS SNS and Twilio for automated WhatsApp/SMS reminders.
- **🧠 ML Models**
PulseNet uses two ML models: one predicts donor activity, and the other predicts donation eligibility.  
These predictions power the ML-ranked donor lists and eligibility filtering in the coordinator dashboard.

---

## 🏗️ Architecture

```text
┌─────────────────────────────────────────────────────┐
│                    AWS Cloud                        │
│                                                     │
│  ┌──────────────┐    ┌──────────────────────────┐   │
│  │  App Runner  │    │  App Runner              │   │
│  │  (Frontend)  │───▶│  (FastAPI Backend)       │   │
│  │  React+Vite  │    │  Port 8000               │   │
│  └──────────────┘    └────────────┬─────────────┘   │
│                                   │                 │
│  ┌────────────┐  ┌─────────────┐  │  ┌───────────┐  │
│  │ SageMaker  │  │  AWS RDS    │◀─┘  │  Bedrock  │  │
│  │ XGBoost    │  │ PostgreSQL  │     │  Claude   │  │
│  │  Endpoint  │  └─────────────┘     │  Haiku   │  │
│  └────────────┘                      └───────────┘  │
│                                                     │
│  ┌────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │   Cognito  │  │  SNS / SES  │  │  CloudWatch │   │
│  │    Auth    │  │  Notifs     │  │   Logging   │   │
│  └────────────┘  └─────────────┘  └─────────────┘   │
└─────────────────────────────────────────────────────┘
```

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | React 18 + Vite + TypeScript + Tailwind CSS |
| **Backend** | FastAPI + Python 3.11 (async) |
| **ORM** | SQLAlchemy 2.0 (async) + Pydantic v2 |
| **Database** | AWS RDS (PostgreSQL 15) |
| **ML Matching** | XGBoost + SageMaker Endpoint |
| **AI Insights** | Amazon Bedrock (Claude Haiku) |
| **Auth** | AWS Cognito |
| **Notifications** | AWS SNS + SES + Twilio WhatsApp |
| **Deploy** | AWS App Runner + ECR |
| **Monitoring** | AWS CloudWatch |

---

## 💻 Local Development Setup

### Prerequisites
- Docker Desktop
- Node.js 20+
- Python 3.11+
- AWS CLI (configured)

### 1. Environment Configuration
```bash
git clone https://github.com/rishitsura/PulseNet.git
cd PulseNet
cp .env.example .env
# Edit .env with your AWS RDS DATABASE_URL and AWS credentials
```

### 2. Run with Docker Compose
The easiest way to get the entire stack running locally:
```bash
docker compose up --build
```
- **Frontend:** http://localhost:5173
- **Backend API:** http://localhost:8000
- **Swagger Docs:** http://localhost:8000/api/docs

### 3. Run Services Individually

**Backend:**
```bash
cd backend
python -m venv venv
source venv/bin/activate  # (or venv\Scripts\activate on Windows)
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

**Frontend:**
```bash
cd frontend
npm install
npm run dev
```

---

## 🔌 Core API Endpoints

### Authentication & Users
- `POST /api/auth/login` - Authenticate via Cognito & generate JWT
- `GET /api/donor/{id}` - Fetch donor profile (RBAC protected)

### Admin & Care Coordination
- `GET /api/admin/bridge/mock` - ML-ranked donor list via XGBoost
- `GET /api/admin/ai-insights` - Generate admin insights via Amazon Bedrock
- `POST /api/admin/notify/{donor_id}/whatsapp` - Trigger Twilio WhatsApp reminders

### Background Utilities
- `backend/sync_cognito.py` - Script used to dynamically bulk-migrate existing RDS users directly into AWS Cognito User Pools.

---
*Built with ❤️ for the AI FOR GOOD 2.0 Hackathon.*
