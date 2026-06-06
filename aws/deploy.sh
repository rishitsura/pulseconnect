#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# PulseNet — AWS Deployment Script
# Usage: ./aws/deploy.sh [dev|staging|prod]
# Prerequisites: aws CLI, docker, git
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

ENV=${1:-dev}
AWS_REGION=${AWS_REGION:-us-east-1}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_BASE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
GIT_SHA=$(git rev-parse --short HEAD)

BACKEND_IMAGE="${ECR_BASE}/pulsenet-backend:${GIT_SHA}"
FRONTEND_IMAGE="${ECR_BASE}/pulsenet-frontend:${GIT_SHA}"

echo "🚀 Deploying PulseNet [${ENV}] — commit ${GIT_SHA}"
echo "   AWS Account: ${AWS_ACCOUNT_ID} | Region: ${AWS_REGION}"

# ── Step 1: Login & Ensure ECR Repositories Exist ────────────────────────────
echo ""
echo "🔐 Logging in to ECR…"
aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "${ECR_BASE}"

echo "📦 Ensuring ECR repositories exist…"
aws ecr describe-repositories --repository-names pulsenet-backend --region "$AWS_REGION" >/dev/null 2>&1 || \
  aws ecr create-repository --repository-name pulsenet-backend --region "$AWS_REGION" >/dev/null

aws ecr describe-repositories --repository-names pulsenet-frontend --region "$AWS_REGION" >/dev/null 2>&1 || \
  aws ecr create-repository --repository-name pulsenet-frontend --region "$AWS_REGION" >/dev/null

# ── Step 2: Build + push backend ─────────────────────────────────────────────
echo ""
echo "🏗️  Building backend image…"
docker build -t "$BACKEND_IMAGE" ./backend
docker push "$BACKEND_IMAGE"
echo "   ✅ Backend pushed: $BACKEND_IMAGE"

# ── Step 3: Build + push frontend ────────────────────────────────────────────
echo ""
echo "🏗️  Building frontend image…"
docker build \
  --build-arg VITE_API_URL="https://$(aws apprunner list-services \
    --query "ServiceSummaryList[?ServiceName=='pulsenet-backend'].ServiceUrl" \
    --output text 2>/dev/null || echo 'localhost:8000')" \
  -t "$FRONTEND_IMAGE" ./frontend
docker push "$FRONTEND_IMAGE"
echo "   ✅ Frontend pushed: $FRONTEND_IMAGE"

# ── Step 4: Deploy CloudFormation stack ──────────────────────────────────────
echo ""
echo "☁️  Deploying CloudFormation (SAM)…"

# Retrieve DATABASE_URL and SECRET_KEY from AWS Secrets Manager (preferred)
# Fallback: read from local .env (not recommended for production)
DB_URL=${DATABASE_URL:-$(aws secretsmanager get-secret-value \
  --secret-id pulsenet/database_url --query SecretString --output text 2>/dev/null || echo '')}
SECRET=${SECRET_KEY:-$(aws secretsmanager get-secret-value \
  --secret-id pulsenet/secret_key --query SecretString --output text 2>/dev/null || echo 'change_me')}


OVERRIDES="Environment=${ENV} DatabaseUrl=${DB_URL} SecretKey=${SECRET} BackendImageUri=${BACKEND_IMAGE} FrontendImageUri=${FRONTEND_IMAGE} DemoMode=${DEMO_MODE:-false}"

[ -n "${COGNITO_USER_POOL_ID:-}" ] && OVERRIDES="$OVERRIDES CognitoUserPoolId=${COGNITO_USER_POOL_ID}"
[ -n "${COGNITO_CLIENT_ID:-}" ] && OVERRIDES="$OVERRIDES CognitoClientId=${COGNITO_CLIENT_ID}"
[ -n "${COGNITO_CLIENT_SECRET:-}" ] && OVERRIDES="$OVERRIDES CognitoClientSecret=${COGNITO_CLIENT_SECRET}"
[ -n "${COGNITO_REGION:-}" ] && OVERRIDES="$OVERRIDES CognitoRegion=${COGNITO_REGION}"
[ -n "${SNS_TOPIC_ARN:-}" ] && OVERRIDES="$OVERRIDES SnsTopicArn=${SNS_TOPIC_ARN}"
[ -n "${SES_SENDER_EMAIL:-}" ] && OVERRIDES="$OVERRIDES SesSenderEmail=${SES_SENDER_EMAIL}"
[ -n "${TWILIO_ACCOUNT_SID:-}" ] && OVERRIDES="$OVERRIDES TwilioAccountSid=${TWILIO_ACCOUNT_SID}"
[ -n "${TWILIO_AUTH_TOKEN:-}" ] && OVERRIDES="$OVERRIDES TwilioAuthToken=${TWILIO_AUTH_TOKEN}"
[ -n "${TWILIO_WHATSAPP_FROM:-}" ] && OVERRIDES="$OVERRIDES TwilioWhatsappFrom=${TWILIO_WHATSAPP_FROM}"
[ -n "${BEDROCK_MODEL_ID:-}" ] && OVERRIDES="$OVERRIDES BedrockModelId=${BEDROCK_MODEL_ID}"

sam deploy \
  --template-file aws/template.yaml \
  --stack-name "pulsenet-${ENV}" \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --region "$AWS_REGION" \
  --parameter-overrides $OVERRIDES \
  --no-fail-on-empty-changeset

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📡 Endpoints:"
aws cloudformation describe-stacks \
  --stack-name "pulsenet-${ENV}" \
  --query "Stacks[0].Outputs[?OutputKey=='BackendURL' || OutputKey=='FrontendURL'].[OutputKey,OutputValue]" \
  --output table
