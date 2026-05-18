# ============================================================================
# SETUP.ps1 — ClaudeQuickStarter Windows 부트스트랩 오케스트레이터
#
# /setup-project Phase C에서 호출. PowerShell 7+ 권장.
# 네이티브 PowerShell로 가능한 부분(.env 생성, 변수 치환)은 직접 수행,
# 복잡한 스택 합성(docker-compose, Dockerfile 등)은 WSL/Git Bash로 위임.
#
# 사용법: pwsh ./SETUP.ps1
# 권장: pwsh (PowerShell 7+). Windows PowerShell 5.1도 동작은 함.
# ============================================================================
[CmdletBinding()]
param([switch]$SkipDocker)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

function Write-Step($n, $total, $msg) { Write-Host "`n[$n/$total] $msg" -ForegroundColor Yellow }
function Write-Ok($msg)   { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  ⚠ $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "  ✗ $msg" -ForegroundColor Red }

# ============================================================================
# 1. 선행 조건
# ============================================================================
Write-Host "=== ClaudeQuickStarter Setup (Windows) ===" -ForegroundColor Cyan

if (-not (Test-Path '.claude/stack.json')) {
    Write-Err '.claude/stack.json 없음. /analyze-stack을 먼저 실행하세요.'
    exit 1
}

$stack = Get-Content '.claude/stack.json' -Raw | ConvertFrom-Json
if ($stack.status -ne 'confirmed') {
    Write-Err ".claude/stack.json status가 '$($stack.status)' (confirmed 아님)"
    exit 1
}

Write-Step 1 9 '필수 도구 확인'

function Find-Bash {
    $candidates = @(
        'C:\Program Files\Git\bin\bash.exe',
        'C:\Program Files\Git\usr\bin\bash.exe',
        'C:\Windows\System32\bash.exe'  # WSL bash
    )
    foreach ($p in $candidates) { if (Test-Path $p) { return $p } }
    $cmd = Get-Command bash -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

$bash = Find-Bash
if ($bash) {
    Write-Ok "bash: $bash"
} else {
    Write-Warn 'bash 없음. 일부 단계는 건너뜁니다. Git Bash 또는 WSL 설치 권장.'
}

$docker = Get-Command docker -ErrorAction SilentlyContinue
if ($docker) { Write-Ok "docker: $($docker.Source)" } else { Write-Warn 'docker 없음 (Docker Desktop 권장)' }

# ============================================================================
# 2. 스택 출력
# ============================================================================
Write-Step 2 9 '확정 스택'
$fe = $stack.stack.frontend.ui_framework
$be = $stack.stack.backend.framework
$db = $stack.stack.database.primary_database
$cache = $stack.stack.database.cache
Write-Host "  Frontend: $fe`n  Backend: $be`n  DB: $db`n  Cache: $cache"

# ============================================================================
# 3. .env 생성 (네이티브)
# ============================================================================
Write-Step 3 9 '.env 생성 (강한 시크릿 자동)'

function New-Secret {
    $bytes = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    return ($bytes | ForEach-Object { $_.ToString('x2') }) -join ''
}

if (Test-Path '.env') {
    Copy-Item '.env' ".env.backup.$(Get-Date -UFormat %s)"
    Write-Host '  ℹ 기존 .env 백업'
}

$envContent = Get-Content '.env.example' -Raw
# __GENERATED_BY_SETUP__ 각 occurrence를 다른 시크릿으로 치환
while ($envContent -match '__GENERATED_BY_SETUP__') {
    $secret = New-Secret
    $envContent = [regex]::Replace($envContent, '__GENERATED_BY_SETUP__', $secret, 1)
}

# DB 섹션 활성화/비활성화
switch -Regex ($db) {
    '^PostgreSQL' { }  # 기본 활성
    '^MySQL' {
        $envContent = $envContent -replace '(?m)^(POSTGRES_|DATABASE_URL=postgresql)', '# $1'
        $envContent = $envContent -replace '(?m)^# (MYSQL_|DATABASE_URL=mysql)', '$1'
    }
    '^MongoDB' {
        $envContent = $envContent -replace '(?m)^(POSTGRES_|DATABASE_URL=postgresql)', '# $1'
        $envContent = $envContent -replace '(?m)^# (MONGO_|DATABASE_URL=mongodb)', '$1'
    }
}

# Auth 섹션
$auth = $stack.stack.backend.authentication
switch -Regex ($auth) {
    'JWT' { }  # 기본 활성
    'Session' {
        $envContent = $envContent -replace '(?m)^(JWT_)', '# $1'
        $envContent = $envContent -replace '(?m)^# (SESSION_)', '$1'
    }
    'OAuth' {
        $envContent = $envContent -replace '(?m)^(JWT_)', '# $1'
        $envContent = $envContent -replace '(?m)^# (OAUTH_)', '$1'
    }
}

Set-Content -Path '.env' -Value $envContent -NoNewline -Encoding utf8
Write-Ok '.env 생성 완료 (RandomNumberGenerator로 강한 시크릿)'

# ============================================================================
# 4-6. docker-compose / Dockerfile / GitHub Actions 생성 (bash 위임)
# ============================================================================
function Invoke-BashModule($scriptName) {
    if (-not $bash) {
        Write-Warn "$scriptName 건너뜀 (bash 없음)"
        return
    }
    & $bash -c "cd '$($PSScriptRoot -replace '\\', '/')' && bash scripts/setup-modules/$scriptName"
    if ($LASTEXITCODE -ne 0) { Write-Err "$scriptName 실패 (exit $LASTEXITCODE)" }
}

Write-Step 4 9 'docker-compose 생성'
Invoke-BashModule 'generate-docker-compose.sh'

Write-Step 5 9 'Dockerfile 생성'
Invoke-BashModule 'generate-dockerfiles.sh'

Write-Step 6 9 'GitHub Actions 생성'
Invoke-BashModule 'generate-github-actions.sh'

# ============================================================================
# 7-8. Frontend / Backend 스캐폴드
# ============================================================================
Write-Step 7 9 "Frontend 스캐폴드: $fe"
switch -Regex ($fe) {
    '^React'   { Invoke-BashModule 'setup-frontend-react-vite.sh' }
    '^Vue'     { Invoke-BashModule 'setup-frontend-vue.sh' }
    '^Next\.js' { Invoke-BashModule 'setup-frontend-nextjs.sh' }
    'none'     { Write-Host '  (Frontend 없음)' }
    default    { Write-Warn "'$fe' 모듈 없음 — 수동 스캐폴드 필요" }
}

Write-Step 8 9 "Backend 스캐폴드: $be"
switch ($be) {
    'FastAPI' { Invoke-BashModule 'setup-backend-fastapi.sh' }
    'Django'  { Invoke-BashModule 'setup-backend-django.sh' }
    'Express' { Invoke-BashModule 'setup-backend-express.sh' }
    'none'    { Write-Host '  (Backend 없음)' }
    default   { Write-Warn "'$be' 모듈 없음 — 수동 스캐폴드 필요" }
}

# Backend 가상환경 + 의존성 (Python 계열만 PowerShell 네이티브로)
if (($be -eq 'FastAPI' -or $be -eq 'Django') -and (Test-Path 'app/backend/requirements.txt')) {
    Push-Location app/backend
    if (-not (Test-Path '.venv')) {
        python -m venv .venv
    }
    & .venv\Scripts\python.exe -m pip install --upgrade pip setuptools wheel | Out-Null
    & .venv\Scripts\python.exe -m pip install -r requirements.txt
    Pop-Location
    Write-Ok 'Python 의존성 설치 완료'
}

# Frontend 의존성
if (Test-Path 'app/frontend/package.json') {
    $pm = $stack.stack.frontend.package_manager
    Push-Location app/frontend
    switch ($pm) {
        'pnpm' { if (Get-Command pnpm -ErrorAction SilentlyContinue) { pnpm install } else { npm install } }
        'yarn' { if (Get-Command yarn -ErrorAction SilentlyContinue) { yarn install } else { npm install } }
        default { npm install }
    }
    Pop-Location
    Write-Ok "Frontend 의존성 설치 완료 ($pm)"
}

# ============================================================================
# 9. Docker 시작 테스트
# ============================================================================
Write-Step 9 9 'Docker 시작 테스트'
if ($SkipDocker) {
    Write-Host '  (--SkipDocker 지정 — 건너뜀)'
} elseif ($docker -and (Test-Path 'docker-compose.yml')) {
    docker compose up -d 2>$null
    Start-Sleep -Seconds 3
    docker compose ps
    Write-Host '  로컬 종료: docker compose down'
} else {
    Write-Warn 'docker 또는 docker-compose.yml 없음 — 건너뜀'
}

# ============================================================================
# 완료
# ============================================================================
Write-Host "`n=== SETUP 완료 ===" -ForegroundColor Green
Write-Host @"

다음 단계:
  1. git status로 생성된 파일 확인
  2. .env 검토 (시크릿 자동 생성됨, .gitignored)
  3. git add . && git commit -m "Bootstrap: stack confirmed and scaffolded"
  4. Claude Code: "PRD 기반 ROADMAP 생성해줘."
  5. Claude Code: "sprint 1 계획 세워줘."
  6. Claude Code: /sprint-dev 1
"@
