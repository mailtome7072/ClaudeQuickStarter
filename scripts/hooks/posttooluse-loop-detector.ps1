# ============================================================================
# posttooluse-loop-detector.ps1 (Windows 변형)
# bash 버전과 동일 정책.
# ============================================================================
$ErrorActionPreference = 'Stop'
$projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
$countsFile = Join-Path $projectRoot '.claude/tmp/edit-counts.json'
$threshold = 3

# 임시 디렉터리 보장
$tmpDir = Split-Path $countsFile -Parent
if (-not (Test-Path $tmpDir)) { New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null }

# 입력 파싱
try {
    $input = [Console]::In.ReadToEnd() | ConvertFrom-Json
} catch {
    exit 0  # 입력 파싱 실패 시 무시
}

$filePath = $input.tool_input.file_path
if (-not $filePath) { $filePath = $input.tool_input.path }
if (-not $filePath) { exit 0 }

# 정규화
$relPath = $filePath -replace [regex]::Escape($projectRoot + [IO.Path]::DirectorySeparatorChar), ''
$relPath = $relPath -replace '\\', '/'
$relPath = $relPath -replace '^\./', ''

# 카운터 로드 (없으면 빈 객체)
if (Test-Path $countsFile) {
    $counts = Get-Content $countsFile -Raw | ConvertFrom-Json -AsHashtable
    if (-not $counts) { $counts = @{} }
} else {
    $counts = @{}
}

# 증가
if ($counts.ContainsKey($relPath)) {
    $counts[$relPath] = [int]$counts[$relPath] + 1
} else {
    $counts[$relPath] = 1
}
$newCount = $counts[$relPath]

# 저장
$counts | ConvertTo-Json | Set-Content $countsFile -Encoding utf8

# 임계치 도달 시 경고
if ($newCount -ge $threshold) {
    [Console]::Error.WriteLine(@"

⚠ Loop Detection: $relPath 이 세션에서 $($newCount)회 수정됨 (임계치 $threshold)

다음을 자체 점검하세요 (docs/harness-engineering/README.md 원칙 3):
  1. 내 접근 방식이 잘못된 것은 아닌가?
  2. 근본 원인이 다른 곳에 있는 것은 아닌가?
  3. 테스트가 내 의도를 실제로 검증하는가?

계속 진행이 필요하다면 사용자에게 이유를 명시하고 동의를 받으세요.
카운터 리셋: Remove-Item $countsFile
"@)
}

exit 0
