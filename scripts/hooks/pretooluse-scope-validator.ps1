# ============================================================================
# pretooluse-scope-validator.ps1 (Windows 변형)
# bash 버전과 동일 정책.
# ============================================================================
$ErrorActionPreference = 'Stop'
$projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
$scopeFile = Join-Path $projectRoot '.claude/tmp/scope.md'
$configFile = Join-Path $projectRoot '.claude/hooks-config.json'

# 입력 파싱 (선택적 — 사용 안 함, exit 분기만)
$inputJson = [Console]::In.ReadToEnd()

# scope.md 존재 시 정상 진행
if (Test-Path $scopeFile) {
    exit 0
}

# 엄격 모드 확인
$strict = $false
if (Test-Path $configFile) {
    try {
        $cfg = Get-Content $configFile -Raw | ConvertFrom-Json
        if ($cfg.scope_validator.strict -eq $true) { $strict = $true }
    } catch { }
}

$msg = @"
ℹ scope.md가 없습니다 ($scopeFile). 작업 시작 전 다음을 정리하세요:
  - 목표:
  - 영향 받는 파일:
  - 검증 방법:
  - 롤백 조건:

(엄격 모드: .claude/hooks-config.json의 scope_validator.strict=true)
"@

if ($strict) {
    [Console]::Error.WriteLine($msg)
    exit 2
} else {
    [Console]::Error.WriteLine($msg)
    exit 0
}
