# ============================================================================
# pretooluse-forbidden-area-guard.ps1 (Windows 변형)
# bash 버전과 동일 정책. PowerShell 7+ 권장.
# ============================================================================
$ErrorActionPreference = 'Stop'
$projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
$overrideFile = Join-Path $projectRoot '.claude/tmp/forbidden-override'

$input = [Console]::In.ReadToEnd() | ConvertFrom-Json
$filePath = $input.tool_input.file_path
if (-not $filePath) { $filePath = $input.tool_input.path }
if (-not $filePath) { exit 0 }

$relPath = $filePath -replace [regex]::Escape($projectRoot + [IO.Path]::DirectorySeparatorChar), ''
$relPath = $relPath -replace '\\', '/'
$relPath = $relPath -replace '^\./', ''

$forbidden = @(
    '^\.github/workflows/',
    '^SETUP\.sh$',
    '^SETUP\.ps1$',
    '^scripts/setup-modules/',
    '^scripts/hooks/',
    '^docker-compose\.prod\.yml$',
    '^docker/[^/]+/Dockerfile\.prod$',
    '^docs/harness-engineering/',
    '^\.claude/rules/',
    '^\.claude/settings\.json$'
)

$matched = $null
foreach ($pat in $forbidden) {
    if ($relPath -match $pat) { $matched = $pat; break }
}
if (-not $matched) { exit 0 }

if ($env:CLAUDE_ALLOW_FORBIDDEN -eq '1') {
    [Console]::Error.WriteLine("⚠ Forbidden area 수정 허가됨 (env): $relPath")
    exit 0
}
if (Test-Path $overrideFile) {
    [Console]::Error.WriteLine("⚠ Forbidden area 일회성 허가 사용: $relPath")
    Remove-Item $overrideFile -Force
    exit 0
}

[Console]::Error.WriteLine(@"
✗ Forbidden area 수정 시도 차단됨

파일: $relPath
매칭 패턴: $matched

이 영역은 사용자 명시적 허가 없이 수정할 수 없습니다.
(정책: docs/harness-engineering/README.md 원칙 2)

수정이 필요한 경우:
  1. `$env:CLAUDE_ALLOW_FORBIDDEN = '1'` (세션 전체)
  2. `New-Item .claude/tmp/forbidden-override -ItemType File` (1회만)
"@)
exit 2
