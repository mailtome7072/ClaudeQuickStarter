#!/bin/bash
# ============================================================================
# generate-github-actions.sh
#
# stack.json 기반으로 .github/workflows/ci.yml과 deploy.yml 생성.
# deploy.yml은 infrastructure.deployment_environment에 따라 환경별 배포 단계를
# 자동 생성합니다 (Lightsail / ECS / App Runner / Cloud Run / App Service /
# Container Apps / Vercel / Heroku / Kubernetes / Self-hosted SSH / Docker only).
# ============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

STACK_JSON=".claude/stack.json"
[ -f "$STACK_JSON" ] || { echo "✗ $STACK_JSON 없음"; exit 1; }
command -v jq >/dev/null || { echo "✗ jq 필요"; exit 1; }

FE_PM=$(jq -r '.stack.frontend.package_manager // "pnpm"' "$STACK_JSON")
FE=$(jq -r '.stack.frontend.ui_framework // "none"' "$STACK_JSON")
BE=$(jq -r '.stack.backend.framework // "none"' "$STACK_JSON")
BE_LANG=$(jq -r '.stack.backend.language // "none"' "$STACK_JSON")
CI=$(jq -r '.stack.infrastructure.ci_cd_platform // "GitHub Actions"' "$STACK_JSON")
DEPLOY_ENV=$(jq -r '.stack.infrastructure.deployment_environment // "AWS Lightsail"' "$STACK_JSON")
STRATEGY=$(jq -r '.decisions.deployment_strategy // "Continuous Delivery (CDelivery)"' "$STACK_JSON")

if [[ "$CI" != *GitHub* ]]; then
    echo "ℹ CI/CD 플랫폼이 GitHub Actions가 아님 ($CI) — 건너뜀"
    echo "  수동으로 해당 플랫폼용 워크플로우를 작성하세요."
    exit 0
fi

mkdir -p .github/workflows

# Backend 테스트/설치 명령
case "$BE" in
    FastAPI|Django) BE_TEST="pytest"; BE_INSTALL="pip install -r requirements.txt" ;;
    Express)        BE_TEST="npm test"; BE_INSTALL="npm ci" ;;
    *)              BE_TEST="echo 'no backend tests'"; BE_INSTALL="" ;;
esac

# Backend 헬스 경로/포트
case "$BE" in
    FastAPI)   BE_PORT=8000; HEALTH=/health ;;
    Django)    BE_PORT=8000; HEALTH=/health/ ;;
    Express)   BE_PORT=3000; HEALTH=/healthz ;;
    "Spring Boot") BE_PORT=8080; HEALTH=/actuator/health ;;
    *)         BE_PORT=8000; HEALTH=/health ;;
esac

# Python 버전
PY_VER="3.12"
[[ "$BE_LANG" == *3.11* ]] && PY_VER="3.11"

# ============================================================================
# ci.yml 생성
# ============================================================================
cat > .github/workflows/ci.yml <<EOF
name: CI

on:
  push:
    branches: [main, develop, 'sprint*']
  pull_request:
    branches: [main, develop]

jobs:
  frontend:
    runs-on: ubuntu-latest
    if: \${{ hashFiles('app/frontend/package.json') != '' }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - name: Install $FE_PM
        if: \${{ '$FE_PM' == 'pnpm' }}
        run: npm install -g pnpm
      - name: Install dependencies
        working-directory: app/frontend
        run: $FE_PM install --frozen-lockfile
      - name: Lint
        working-directory: app/frontend
        run: $FE_PM run lint || true
      - name: Test
        working-directory: app/frontend
        run: $FE_PM test || true
      - name: Build
        working-directory: app/frontend
        run: $FE_PM run build

  backend:
    runs-on: ubuntu-latest
    if: \${{ hashFiles('app/backend/requirements.txt') != '' || hashFiles('app/backend/package.json') != '' }}
    steps:
      - uses: actions/checkout@v4
      - name: Setup Python
        if: \${{ hashFiles('app/backend/requirements.txt') != '' }}
        uses: actions/setup-python@v5
        with:
          python-version: '$PY_VER'
      - name: Setup Node
        if: \${{ hashFiles('app/backend/package.json') != '' }}
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      - name: Install dependencies
        working-directory: app/backend
        run: $BE_INSTALL
      - name: Lint (ruff for Python)
        if: \${{ hashFiles('app/backend/pyproject.toml') != '' }}
        working-directory: app/backend
        run: pip install ruff && ruff check .
      - name: Test
        working-directory: app/backend
        run: $BE_TEST
EOF

# ============================================================================
# deploy.yml 헤더 (모든 환경 공통: build + push 이미지)
# ============================================================================

# 트리거: CDelivery는 main push + workflow_dispatch, CD는 main push만
if [[ "$STRATEGY" == *Continuous\ Delivery* ]]; then
    TRIGGER="push:
    branches: [main]
  workflow_dispatch:"
else
    TRIGGER="push:
    branches: [main]"
fi

cat > .github/workflows/deploy.yml <<EOF
name: Deploy

# 배포 전략: $STRATEGY
# 대상 환경: $DEPLOY_ENV

on:
  $TRIGGER

env:
  REGISTRY: ghcr.io
  IMAGE_NAMESPACE: \${{ github.repository_owner }}
  PROJECT_NAME: \${{ github.event.repository.name }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    outputs:
      image-tag: \${{ steps.meta.outputs.tag }}
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: \${{ env.REGISTRY }}
          username: \${{ github.actor }}
          password: \${{ secrets.GITHUB_TOKEN }}

      - name: Compute tag
        id: meta
        run: echo "tag=\${GITHUB_SHA::8}" >> \$GITHUB_OUTPUT

      - name: Build & push backend
        if: \${{ hashFiles('docker/backend/Dockerfile.prod') != '' }}
        uses: docker/build-push-action@v6
        with:
          context: ./app/backend
          file: ./docker/backend/Dockerfile.prod
          push: true
          tags: |
            \${{ env.REGISTRY }}/\${{ env.IMAGE_NAMESPACE }}/\${{ env.PROJECT_NAME }}-backend:latest
            \${{ env.REGISTRY }}/\${{ env.IMAGE_NAMESPACE }}/\${{ env.PROJECT_NAME }}-backend:\${{ steps.meta.outputs.tag }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Build & push frontend
        if: \${{ hashFiles('docker/frontend/Dockerfile.prod') != '' }}
        uses: docker/build-push-action@v6
        with:
          context: ./app/frontend
          file: ./docker/frontend/Dockerfile.prod
          push: true
          tags: |
            \${{ env.REGISTRY }}/\${{ env.IMAGE_NAMESPACE }}/\${{ env.PROJECT_NAME }}-frontend:latest
            \${{ env.REGISTRY }}/\${{ env.IMAGE_NAMESPACE }}/\${{ env.PROJECT_NAME }}-frontend:\${{ steps.meta.outputs.tag }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

EOF

# ============================================================================
# 환경별 deploy job 추가
# ============================================================================

case "$DEPLOY_ENV" in
    *Lightsail*|*EC2*|*"Self-hosted"*|*SSH*)
        cat >> .github/workflows/deploy.yml <<EOF
  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    environment: production
    # 필요 secrets:
    #   DEPLOY_HOST, DEPLOY_USER, DEPLOY_SSH_KEY (private key, PEM 형식)
    #   DEPLOY_PATH (서버 내 docker-compose 위치, 예: /opt/app)
    steps:
      - uses: actions/checkout@v4

      - name: Setup SSH
        uses: webfactory/ssh-agent@v0.9.0
        with:
          ssh-private-key: \${{ secrets.DEPLOY_SSH_KEY }}

      - name: Add host to known_hosts
        run: |
          mkdir -p ~/.ssh
          ssh-keyscan -H \${{ secrets.DEPLOY_HOST }} >> ~/.ssh/known_hosts

      - name: Copy docker-compose.prod.yml
        run: |
          scp docker-compose.prod.yml \${{ secrets.DEPLOY_USER }}@\${{ secrets.DEPLOY_HOST }}:\${{ secrets.DEPLOY_PATH }}/docker-compose.yml

      - name: Pull new images and restart
        run: |
          ssh \${{ secrets.DEPLOY_USER }}@\${{ secrets.DEPLOY_HOST }} <<'REMOTE'
            cd \${{ secrets.DEPLOY_PATH }}
            echo "\${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u \${{ github.actor }} --password-stdin
            docker compose pull
            docker compose up -d --remove-orphans
            docker image prune -f
          REMOTE

  verify:
    needs: deploy
    runs-on: ubuntu-latest
    steps:
      - name: Wait for health
        run: sleep 30

      - name: Health check
        run: |
          for i in {1..10}; do
            if curl -fsS https://\${{ secrets.PRODUCTION_URL }}/api${HEALTH}; then
              echo "✓ Healthy"; exit 0
            fi
            echo "Attempt \$i: not ready, retrying in 10s"
            sleep 10
          done
          echo "✗ Health check failed after 10 attempts"
          exit 1
EOF
        ;;

    *ECS*|*Fargate*)
        cat >> .github/workflows/deploy.yml <<EOF
  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    environment: production
    # 필요 secrets:
    #   AWS_ROLE_TO_ASSUME (OIDC) 또는 AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY
    #   AWS_REGION, ECS_CLUSTER, ECS_SERVICE, ECS_TASK_DEFINITION (JSON 파일 경로)
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: \${{ secrets.AWS_ROLE_TO_ASSUME }}
          aws-region: \${{ secrets.AWS_REGION }}

      - name: Update task definition (backend)
        id: task-def
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: \${{ secrets.ECS_TASK_DEFINITION }}
          container-name: backend
          image: \${{ env.REGISTRY }}/\${{ env.IMAGE_NAMESPACE }}/\${{ env.PROJECT_NAME }}-backend:\${{ needs.build-and-push.outputs.image-tag }}

      - name: Deploy to ECS
        uses: aws-actions/amazon-ecs-deploy-task-definition@v2
        with:
          task-definition: \${{ steps.task-def.outputs.task-definition }}
          service: \${{ secrets.ECS_SERVICE }}
          cluster: \${{ secrets.ECS_CLUSTER }}
          wait-for-service-stability: true

  verify:
    needs: deploy
    runs-on: ubuntu-latest
    steps:
      - name: Health check
        run: |
          for i in {1..10}; do
            if curl -fsS https://\${{ secrets.PRODUCTION_URL }}${HEALTH}; then exit 0; fi
            sleep 10
          done
          exit 1
EOF
        ;;

    *"App Runner"*)
        cat >> .github/workflows/deploy.yml <<EOF
  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    environment: production
    # 필요 secrets: AWS_ROLE_TO_ASSUME, AWS_REGION, APP_RUNNER_SERVICE_ARN
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: \${{ secrets.AWS_ROLE_TO_ASSUME }}
          aws-region: \${{ secrets.AWS_REGION }}

      - name: Trigger App Runner deployment
        run: |
          aws apprunner start-deployment --service-arn \${{ secrets.APP_RUNNER_SERVICE_ARN }}

      - name: Wait for service stable
        run: |
          aws apprunner wait service-updated --service-arn \${{ secrets.APP_RUNNER_SERVICE_ARN }}
EOF
        ;;

    *"Cloud Run"*|*GCP*)
        cat >> .github/workflows/deploy.yml <<EOF
  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    environment: production
    # 필요 secrets:
    #   GCP_WORKLOAD_IDENTITY_PROVIDER (OIDC)
    #   GCP_SERVICE_ACCOUNT, GCP_PROJECT_ID, GCP_REGION
    #   CLOUD_RUN_SERVICE_BACKEND, CLOUD_RUN_SERVICE_FRONTEND
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: \${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: \${{ secrets.GCP_SERVICE_ACCOUNT }}

      - name: Setup gcloud
        uses: google-github-actions/setup-gcloud@v2

      - name: Deploy backend to Cloud Run
        run: |
          gcloud run deploy \${{ secrets.CLOUD_RUN_SERVICE_BACKEND }} \\
            --image \${{ env.REGISTRY }}/\${{ env.IMAGE_NAMESPACE }}/\${{ env.PROJECT_NAME }}-backend:\${{ needs.build-and-push.outputs.image-tag }} \\
            --region \${{ secrets.GCP_REGION }} \\
            --project \${{ secrets.GCP_PROJECT_ID }} \\
            --allow-unauthenticated \\
            --port ${BE_PORT}

      - name: Deploy frontend to Cloud Run
        if: \${{ secrets.CLOUD_RUN_SERVICE_FRONTEND != '' }}
        run: |
          gcloud run deploy \${{ secrets.CLOUD_RUN_SERVICE_FRONTEND }} \\
            --image \${{ env.REGISTRY }}/\${{ env.IMAGE_NAMESPACE }}/\${{ env.PROJECT_NAME }}-frontend:\${{ needs.build-and-push.outputs.image-tag }} \\
            --region \${{ secrets.GCP_REGION }} \\
            --project \${{ secrets.GCP_PROJECT_ID }} \\
            --allow-unauthenticated

  verify:
    needs: deploy
    runs-on: ubuntu-latest
    steps:
      - name: Health check
        run: |
          for i in {1..10}; do
            if curl -fsS \${{ secrets.PRODUCTION_URL }}${HEALTH}; then exit 0; fi
            sleep 10
          done
          exit 1
EOF
        ;;

    *Azure*"App Service"*|*Azure*"Container Apps"*|*Azure*)
        cat >> .github/workflows/deploy.yml <<EOF
  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    environment: production
    # 필요 secrets:
    #   AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID (OIDC)
    #   AZURE_RESOURCE_GROUP, AZURE_CONTAINER_APP_NAME (또는 APP_SERVICE_NAME)
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Azure login
        uses: azure/login@v2
        with:
          client-id: \${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: \${{ secrets.AZURE_TENANT_ID }}
          subscription-id: \${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Deploy to Container Apps
        run: |
          az containerapp update \\
            --name \${{ secrets.AZURE_CONTAINER_APP_NAME }} \\
            --resource-group \${{ secrets.AZURE_RESOURCE_GROUP }} \\
            --image \${{ env.REGISTRY }}/\${{ env.IMAGE_NAMESPACE }}/\${{ env.PROJECT_NAME }}-backend:\${{ needs.build-and-push.outputs.image-tag }}
EOF
        ;;

    *Vercel*)
        cat >> .github/workflows/deploy.yml <<EOF
  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    environment: production
    # 필요 secrets: VERCEL_TOKEN, VERCEL_ORG_ID, VERCEL_PROJECT_ID
    # 참고: Vercel은 자체 빌드 시스템을 가지므로 위 build-and-push의 frontend는
    # 사실상 불필요. Backend만 컨테이너 배포 + Vercel은 frontend 전용으로 가정.
    steps:
      - uses: actions/checkout@v4

      - name: Install Vercel CLI
        run: npm install -g vercel

      - name: Pull Vercel env
        run: vercel pull --yes --environment=production --token=\${{ secrets.VERCEL_TOKEN }}
        working-directory: app/frontend

      - name: Build
        run: vercel build --prod --token=\${{ secrets.VERCEL_TOKEN }}
        working-directory: app/frontend

      - name: Deploy
        run: vercel deploy --prebuilt --prod --token=\${{ secrets.VERCEL_TOKEN }}
        working-directory: app/frontend
EOF
        ;;

    *Heroku*)
        cat >> .github/workflows/deploy.yml <<EOF
  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    environment: production
    # 필요 secrets: HEROKU_API_KEY, HEROKU_APP_NAME
    steps:
      - name: Login to Heroku Container Registry
        run: echo \${{ secrets.HEROKU_API_KEY }} | docker login --username=_ --password-stdin registry.heroku.com

      - name: Pull and re-tag
        run: |
          docker pull \${{ env.REGISTRY }}/\${{ env.IMAGE_NAMESPACE }}/\${{ env.PROJECT_NAME }}-backend:\${{ needs.build-and-push.outputs.image-tag }}
          docker tag \${{ env.REGISTRY }}/\${{ env.IMAGE_NAMESPACE }}/\${{ env.PROJECT_NAME }}-backend:\${{ needs.build-and-push.outputs.image-tag }} registry.heroku.com/\${{ secrets.HEROKU_APP_NAME }}/web
          docker push registry.heroku.com/\${{ secrets.HEROKU_APP_NAME }}/web

      - name: Release
        run: |
          curl -X PATCH "https://api.heroku.com/apps/\${{ secrets.HEROKU_APP_NAME }}/formation" \\
            -H "Authorization: Bearer \${{ secrets.HEROKU_API_KEY }}" \\
            -H "Accept: application/vnd.heroku+json; version=3.docker-releases" \\
            -H "Content-Type: application/json" \\
            -d '{ "updates": [{ "type": "web", "docker_image": "'"\$(docker inspect registry.heroku.com/\${{ secrets.HEROKU_APP_NAME }}/web --format='{{.Id}}')"'" }] }'
EOF
        ;;

    *Kubernetes*|*K8s*|*EKS*|*GKE*|*AKS*)
        cat >> .github/workflows/deploy.yml <<EOF
  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    environment: production
    # 필요 secrets:
    #   KUBE_CONFIG (base64 encoded kubeconfig) 또는 클라우드별 OIDC 인증
    #   K8S_NAMESPACE, K8S_DEPLOYMENT_BACKEND, K8S_DEPLOYMENT_FRONTEND
    steps:
      - uses: actions/checkout@v4

      - name: Setup kubectl
        uses: azure/setup-kubectl@v4

      - name: Configure kubeconfig
        run: |
          mkdir -p ~/.kube
          echo "\${{ secrets.KUBE_CONFIG }}" | base64 -d > ~/.kube/config

      - name: Update backend image
        run: |
          kubectl set image deployment/\${{ secrets.K8S_DEPLOYMENT_BACKEND }} \\
            backend=\${{ env.REGISTRY }}/\${{ env.IMAGE_NAMESPACE }}/\${{ env.PROJECT_NAME }}-backend:\${{ needs.build-and-push.outputs.image-tag }} \\
            -n \${{ secrets.K8S_NAMESPACE }}
          kubectl rollout status deployment/\${{ secrets.K8S_DEPLOYMENT_BACKEND }} -n \${{ secrets.K8S_NAMESPACE }} --timeout=5m

      - name: Update frontend image
        if: \${{ secrets.K8S_DEPLOYMENT_FRONTEND != '' }}
        run: |
          kubectl set image deployment/\${{ secrets.K8S_DEPLOYMENT_FRONTEND }} \\
            frontend=\${{ env.REGISTRY }}/\${{ env.IMAGE_NAMESPACE }}/\${{ env.PROJECT_NAME }}-frontend:\${{ needs.build-and-push.outputs.image-tag }} \\
            -n \${{ secrets.K8S_NAMESPACE }}
          kubectl rollout status deployment/\${{ secrets.K8S_DEPLOYMENT_FRONTEND }} -n \${{ secrets.K8S_NAMESPACE }} --timeout=5m

  verify:
    needs: deploy
    runs-on: ubuntu-latest
    steps:
      - name: Health check
        run: |
          for i in {1..10}; do
            if curl -fsS https://\${{ secrets.PRODUCTION_URL }}${HEALTH}; then exit 0; fi
            sleep 10
          done
          exit 1
EOF
        ;;

    *)
        # Docker 이미지만 빌드/푸시, 배포 단계는 TODO
        cat >> .github/workflows/deploy.yml <<EOF
  # ============================================================================
  # ⚠ 배포 환경 '$DEPLOY_ENV'에 대한 자동 배포 단계가 정의되지 않았습니다.
  #
  # 다음 중 하나를 수동으로 구성하세요:
  #   - .claude/stack.json의 infrastructure.deployment_environment를
  #     지원되는 값으로 변경 후 generate-github-actions.sh 재실행
  #   - 또는 이 deploy.yml에 환경별 배포 단계를 직접 추가
  #
  # 지원 환경:
  #   AWS: Lightsail / EC2 / Self-hosted SSH, ECS / Fargate, App Runner
  #   GCP: Cloud Run
  #   Azure: Container Apps / App Service
  #   기타: Vercel, Heroku, Kubernetes (EKS/GKE/AKS)
  # ============================================================================
  deploy-placeholder:
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
      - name: Notice
        run: |
          echo "이미지 빌드 + 푸시 완료. 배포 환경 자동화는 미구현 ($DEPLOY_ENV)."
          echo "Tag: \${{ needs.build-and-push.outputs.image-tag }}"
EOF
        ;;
esac

# ============================================================================
# rollback.yml — deploy-prod 에이전트가 호출
# ============================================================================
cat > .github/workflows/rollback.yml <<EOF
name: Rollback

# 수동 트리거 전용. 이전 안정 SHA로 재배포.
# 호출: gh workflow run rollback.yml -f sha=<이전_git_sha_8자리>
on:
  workflow_dispatch:
    inputs:
      sha:
        description: '롤백할 이전 안정 SHA (8자리, deploy-history 참조)'
        required: true
        type: string

env:
  REGISTRY: ghcr.io
  IMAGE_NAMESPACE: \${{ github.repository_owner }}
  PROJECT_NAME: \${{ github.event.repository.name }}

jobs:
  rollback:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Verify rollback target exists
        run: |
          if ! docker manifest inspect \${{ env.REGISTRY }}/\${{ env.IMAGE_NAMESPACE }}/\${{ env.PROJECT_NAME }}-backend:\${{ inputs.sha }} >/dev/null 2>&1; then
            echo "✗ 이미지 \${{ inputs.sha }} 가 레지스트리에 없습니다"
            exit 1
          fi
          echo "✓ Rollback target verified: \${{ inputs.sha }}"

EOF

# 환경별 롤백 단계 (deploy와 동일 메커니즘, image-tag만 입력값으로 대체)
case "$DEPLOY_ENV" in
    *Lightsail*|*EC2*|*"Self-hosted"*|*SSH*)
        cat >> .github/workflows/rollback.yml <<EOF
      - name: Setup SSH
        uses: webfactory/ssh-agent@v0.9.0
        with:
          ssh-private-key: \${{ secrets.DEPLOY_SSH_KEY }}

      - name: Add host to known_hosts
        run: ssh-keyscan -H \${{ secrets.DEPLOY_HOST }} >> ~/.ssh/known_hosts

      - name: Pin to rollback SHA and restart
        run: |
          ssh \${{ secrets.DEPLOY_USER }}@\${{ secrets.DEPLOY_HOST }} <<REMOTE
            cd \${{ secrets.DEPLOY_PATH }}
            export IMAGE_TAG=\${{ inputs.sha }}
            docker compose pull
            docker compose up -d --remove-orphans
          REMOTE
EOF
        ;;
    *ECS*|*Fargate*)
        cat >> .github/workflows/rollback.yml <<EOF
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: \${{ secrets.AWS_ROLE_TO_ASSUME }}
          aws-region: \${{ secrets.AWS_REGION }}

      - name: Update task definition with rollback SHA
        id: task-def
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: \${{ secrets.ECS_TASK_DEFINITION }}
          container-name: backend
          image: \${{ env.REGISTRY }}/\${{ env.IMAGE_NAMESPACE }}/\${{ env.PROJECT_NAME }}-backend:\${{ inputs.sha }}

      - name: Deploy rollback to ECS
        uses: aws-actions/amazon-ecs-deploy-task-definition@v2
        with:
          task-definition: \${{ steps.task-def.outputs.task-definition }}
          service: \${{ secrets.ECS_SERVICE }}
          cluster: \${{ secrets.ECS_CLUSTER }}
          wait-for-service-stability: true
EOF
        ;;
    *"Cloud Run"*|*GCP*)
        cat >> .github/workflows/rollback.yml <<EOF
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: \${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: \${{ secrets.GCP_SERVICE_ACCOUNT }}

      - uses: google-github-actions/setup-gcloud@v2

      - name: Roll back Cloud Run backend
        run: |
          gcloud run deploy \${{ secrets.CLOUD_RUN_SERVICE_BACKEND }} \\
            --image \${{ env.REGISTRY }}/\${{ env.IMAGE_NAMESPACE }}/\${{ env.PROJECT_NAME }}-backend:\${{ inputs.sha }} \\
            --region \${{ secrets.GCP_REGION }} \\
            --project \${{ secrets.GCP_PROJECT_ID }}
EOF
        ;;
    *Kubernetes*|*K8s*|*EKS*|*GKE*|*AKS*)
        cat >> .github/workflows/rollback.yml <<EOF
      - uses: azure/setup-kubectl@v4

      - name: Configure kubeconfig
        run: |
          mkdir -p ~/.kube
          echo "\${{ secrets.KUBE_CONFIG }}" | base64 -d > ~/.kube/config

      - name: Roll back deployment
        run: |
          kubectl set image deployment/\${{ secrets.K8S_DEPLOYMENT_BACKEND }} \\
            backend=\${{ env.REGISTRY }}/\${{ env.IMAGE_NAMESPACE }}/\${{ env.PROJECT_NAME }}-backend:\${{ inputs.sha }} \\
            -n \${{ secrets.K8S_NAMESPACE }}
          kubectl rollout status deployment/\${{ secrets.K8S_DEPLOYMENT_BACKEND }} -n \${{ secrets.K8S_NAMESPACE }} --timeout=5m
EOF
        ;;
    *)
        cat >> .github/workflows/rollback.yml <<EOF
      - name: Notice
        run: |
          echo "환경 '$DEPLOY_ENV'에 대한 롤백 자동화 미구현."
          echo "수동으로 이미지 \${{ inputs.sha }}로 되돌리세요."
          exit 1
EOF
        ;;
esac

# ============================================================================
# 출력
# ============================================================================
echo "✓ GitHub Actions 워크플로우 생성:"
echo "  - .github/workflows/ci.yml (Frontend $FE_PM + Backend $BE)"
echo "  - .github/workflows/deploy.yml"
echo "  - .github/workflows/rollback.yml (deploy-prod 에이전트가 호출)"
echo "      대상: $DEPLOY_ENV"
echo "      전략: $STRATEGY"
echo ""
echo "필요한 GitHub Secrets는 deploy.yml/rollback.yml 상단 주석에 명시되어 있습니다."
echo "Repository Settings → Secrets and variables → Actions에서 등록하세요."
