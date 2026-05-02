param(
    [string]$ProjectId = $env:FIREBASE_PROJECT_ID,
    [string]$ReleaseVersion,
    [ValidateSet("all", "rules", "indexes")]
    [string]$DeployScope = "all",
    [switch]$SkipFlutterTests,
    [switch]$SkipEmulatorTests,
    [switch]$SkipDeploy
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Ensure-Command {
    param([Parameter(Mandatory = $true)][string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found in PATH."
    }
}

function Ensure-JavaRuntime {
    if (Get-Command java -ErrorAction SilentlyContinue) {
        return
    }

    $candidates = @(
        $env:JAVA_HOME,
        "C:\Program Files\Android\Android Studio\jbr",
        "C:\Program Files\Android\Android Studio\jre"
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique

    foreach ($candidate in $candidates) {
        $javaExe = Join-Path $candidate "bin\java.exe"
        if (Test-Path -LiteralPath $javaExe) {
            $env:JAVA_HOME = $candidate
            $env:Path = "$candidate\bin;$env:Path"
            break
        }
    }

    if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
        throw "Java runtime not found. Install Java or set JAVA_HOME before running emulator tests."
    }
}

function Run-Step {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][scriptblock]$Script
    )

    Write-Host ""
    Write-Host "==> $Title" -ForegroundColor Cyan
    & $Script
}

function Get-GitMetadata {
    $commit = ""
    $dirty = $null

    if (Get-Command git -ErrorAction SilentlyContinue) {
        $commit = (git rev-parse HEAD 2>$null)
        if ($LASTEXITCODE -ne 0) {
            $commit = ""
        }

        $statusLines = (git status --porcelain 2>$null)
        if ($LASTEXITCODE -eq 0) {
            $dirty = ($statusLines -join "`n").Trim().Length -gt 0
        }
    }

    return @{
        commit = $commit
        dirty  = $dirty
    }
}

function Get-ChecklistMark {
    param([Parameter(Mandatory = $true)][string]$Status)
    if ($Status -in @("passed", "skipped")) {
        return "x"
    }
    return " "
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$rulesPath = Join-Path $repoRoot "firestore.rules"
$indexesPath = Join-Path $repoRoot "firestore.indexes.json"

if (-not (Test-Path -LiteralPath $rulesPath)) {
    throw "File not found: $rulesPath"
}

if (-not (Test-Path -LiteralPath $indexesPath)) {
    throw "File not found: $indexesPath"
}

if ([string]::IsNullOrWhiteSpace($ProjectId)) {
    throw "ProjectId was not provided. Use -ProjectId <id> or set FIREBASE_PROJECT_ID."
}

if ([string]::IsNullOrWhiteSpace($ReleaseVersion)) {
    $ReleaseVersion = Get-Date -Format "yyyyMMdd-HHmmss"
}

$deployRoot = Join-Path $repoRoot "docs/deployments/firestore"
$releaseDir = Join-Path $deployRoot $ReleaseVersion
$manifestPath = Join-Path $releaseDir "manifest.json"
$releaseChecklistPath = Join-Path $releaseDir "validation-checklist.md"

$flutterStatus = if ($SkipFlutterTests) { "skipped" } else { "pending" }
$emulatorStatus = if ($SkipEmulatorTests) { "skipped" } else { "pending" }
$deployStatus = if ($SkipDeploy) { "skipped" } else { "pending" }
$pipelineError = $null

Run-Step -Title "Preparing release folder" -Script {
    New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null
    Copy-Item -LiteralPath $rulesPath -Destination (Join-Path $releaseDir "firestore.rules") -Force
    Copy-Item -LiteralPath $indexesPath -Destination (Join-Path $releaseDir "firestore.indexes.json") -Force
}

Push-Location $repoRoot
try {
    if (-not $SkipFlutterTests) {
        $flutterStatus = "running"
        Run-Step -Title "Running Flutter tests" -Script {
            Ensure-Command -Name "flutter"
            & flutter test
            if ($LASTEXITCODE -ne 0) {
                throw "flutter test failed."
            }
        }
        $flutterStatus = "passed"
    }

    if (-not $SkipEmulatorTests) {
        $emulatorStatus = "running"
        Run-Step -Title "Running Firestore Emulator tests" -Script {
            Ensure-Command -Name "npm"
            Ensure-JavaRuntime
            & npm run emulator:test:firestore
            if ($LASTEXITCODE -ne 0) {
                throw "npm run emulator:test:firestore failed."
            }
        }
        $emulatorStatus = "passed"
    }

    if (-not $SkipDeploy) {
        $deployStatus = "running"
        Run-Step -Title "Deploying Firestore artifacts" -Script {
            Ensure-Command -Name "firebase"
            $targets = switch ($DeployScope) {
                "rules" { "firestore:rules" }
                "indexes" { "firestore:indexes" }
                default { "firestore:rules,firestore:indexes" }
            }

            & firebase deploy --project $ProjectId --only $targets
            if ($LASTEXITCODE -ne 0) {
                throw "firebase deploy failed."
            }
        }
        $deployStatus = "passed"
    }
}
catch {
    if ($flutterStatus -eq "running") {
        $flutterStatus = "failed"
    }
    elseif ($emulatorStatus -eq "running") {
        $emulatorStatus = "failed"
    }
    elseif ($deployStatus -eq "running") {
        $deployStatus = "failed"
    }
    $pipelineError = $_.Exception.Message
}
finally {
    Pop-Location
}

$rulesHash = (Get-FileHash -LiteralPath $rulesPath -Algorithm SHA256).Hash
$indexesHash = (Get-FileHash -LiteralPath $indexesPath -Algorithm SHA256).Hash
$git = Get-GitMetadata
$generatedAt = (Get-Date).ToUniversalTime().ToString("o")

$manifest = [ordered]@{
    releaseVersion = $ReleaseVersion
    generatedAtUtc = $generatedAt
    result         = if ($pipelineError) { "failed" } else { "passed" }
    projectId      = $ProjectId
    deployScope    = $DeployScope
    statuses       = [ordered]@{
        flutterTests  = $flutterStatus
        emulatorTests = $emulatorStatus
        deploy        = $deployStatus
    }
    artifacts      = [ordered]@{
        rulesFile        = "firestore.rules"
        indexesFile      = "firestore.indexes.json"
        rulesSha256      = $rulesHash
        indexesSha256    = $indexesHash
    }
    git            = [ordered]@{
        commit = $git.commit
        dirty  = $git.dirty
    }
}

if ($pipelineError) {
    $manifest.error = $pipelineError
}

$manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifestPath -Encoding utf8

$flutterMark = Get-ChecklistMark -Status $flutterStatus
$emulatorMark = Get-ChecklistMark -Status $emulatorStatus
$deployMark = Get-ChecklistMark -Status $deployStatus

$checklistLines = @(
    "# Firestore deploy validation checklist",
    "",
    "- [x] Release version: $ReleaseVersion",
    "- [x] Project: $ProjectId",
    "- [x] Snapshot generated in docs/deployments/firestore/$ReleaseVersion",
    "- [x] SHA256 captured in manifest.json",
    "- [$flutterMark] Flutter tests: $flutterStatus",
    "- [$emulatorMark] Firestore emulator tests: $emulatorStatus",
    "- [$deployMark] Deploy status: $deployStatus",
    "- [ ] Confirm expected behavior in app after deploy",
    "- [ ] Confirm no PERMISSION_DENIED or FAILED_PRECONDITION in monitoring logs"
)

$checklistLines | Set-Content -LiteralPath $releaseChecklistPath -Encoding utf8

Write-Host ""
if ($pipelineError) {
    Write-Host "Controlled deploy flow finished with errors." -ForegroundColor Red
    Write-Host "Release folder: $releaseDir"
    Write-Host "Manifest: $manifestPath"
    throw $pipelineError
}

Write-Host "Controlled deploy flow finished successfully." -ForegroundColor Green
Write-Host "Release folder: $releaseDir"
Write-Host "Manifest: $manifestPath"
