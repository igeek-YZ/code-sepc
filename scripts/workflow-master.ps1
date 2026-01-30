param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('init', 'check', 'confirm', 'status', 'help')]
  [string]$Command,

  [Parameter(Mandatory = $true)]
  [string]$RequirementId,

  [string]$Stage,
  [string]$GlobalsJson
)

$ErrorActionPreference = 'Stop'
$script:ScriptVersion = '2.0.0'

function Write-Banner {
  Write-Host "=============================================" -ForegroundColor Cyan
  Write-Host "  Workflow Master Guard v$script:ScriptVersion" -ForegroundColor Cyan
  Write-Host "=============================================" -ForegroundColor Cyan
  Write-Host ""
}

function Write-Help {
  Write-Banner
  Write-Host "Usage:" -ForegroundColor Yellow
  Write-Host "  .\scripts\workflow-master.ps1 <command> -RequirementId <id> [-Stage <stage>]" -ForegroundColor White
  Write-Host ""
  Write-Host "Commands:" -ForegroundColor Yellow
  Write-Host "  init      Initialize a new workflow state file for a requirement"
  Write-Host "  check     Verify if all prerequisites are met for entering a stage (dynamic)"
  Write-Host "  confirm   Mark a stage as confirmed after user approval"
  Write-Host "  status    Show current workflow status and progress"
  Write-Host "  help      Show this help message"
  Write-Host ""
  Write-Host "Stages (for check/confirm):" -ForegroundColor Yellow
  Write-Host "  requirement   PRD stage"
  Write-Host "  design        Design stage (Console + Mini Program)"
  Write-Host "  api           API specification stage"
  Write-Host "  plans         Implementation plans stage"
  Write-Host "  code          Code generation stage (check only)"
  Write-Host "  implementation  All implementation artifacts (confirm only)"
  Write-Host ""
  Write-Host "Examples:" -ForegroundColor Yellow
  Write-Host "  # Initialize a new requirement"
  Write-Host "  .\scripts\workflow-master.ps1 init -RequirementId 'P001'"
  Write-Host ""
  Write-Host "  # Check if ready to enter Design stage (dynamic check)"
  Write-Host "  .\scripts\workflow-master.ps1 check -RequirementId 'P001' -Stage design"
  Write-Host ""
  Write-Host "  # Confirm Requirement stage is approved"
  Write-Host "  .\scripts\workflow-master.ps1 confirm -RequirementId 'P001' -Stage requirement"
  Write-Host ""
  Write-Host "  # Show current workflow status"
  Write-Host "  .\scripts\workflow-master.ps1 status -RequirementId 'P001'"
}

function Resolve-RepoRoot {
  $here = Split-Path -Parent $PSCommandPath
  return (Resolve-Path (Join-Path $here '..')).Path
}

function Get-DocsRoot([string]$repoRoot) {
  return (Join-Path $repoRoot 'docs')
}

function Get-WorkflowDir([string]$docsRoot) {
  return (Join-Path $docsRoot '0-workflow')
}

function Get-WorkflowStatePath([string]$workflowDir, [string]$requirementId) {
  return (Join-Path $workflowDir ("workflow-{0}.json" -f $requirementId))
}

function Fail([string]$msg) {
  Write-Error $msg
  exit 1
}

function Ensure-UniqueRequirementId([string]$docsRoot, [string]$requirementId) {
  $pattern = "*$requirementId*.md"
  $hits = Get-ChildItem -Path $docsRoot -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue
  if ($hits -and $hits.Count -gt 0) {
    $files = ($hits | Select-Object -ExpandProperty FullName) -join "`n"
    Fail ("Requirement ID [{0}] is already used in:`n{1}" -f $requirementId, $files)
  }
}

function Get-StageArtifacts([string]$requirementId) {
  return @{
    requirement = @{
      files = @("docs/1-requirements/requirement-$requirementId.md")
      dependsOn = @()
    }
    design = @{
      files = @(
        "docs/2-design/design-console-$requirementId.md"
        "docs/2-design/design-miniprogram-$requirementId.md"
      )
      dependsOn = @('requirement')
    }
    api = @{
      files = @("docs/3-api/api-$requirementId.md")
      dependsOn = @('requirement', 'design')
    }
    plans = @{
      files = @(
        "docs/4-plans/backend-plan-$requirementId.md"
        "docs/4-plans/frontend-plan-$requirementId.md"
      )
      dependsOn = @('requirement', 'design', 'api')
    }
    code = @{
      files = @(
        "docs/code/code-$requirementId.md"
        "docs/5-tests/tests-$requirementId.md"
      )
      dependsOn = @('plans')
    }
  }
}

function Test-StageArtifacts([string]$repoRoot, [string]$requirementId, [string]$stage) {
  $artifacts = Get-StageArtifacts $requirementId
  $stageInfo = $artifacts.$stage

  if (-not $stageInfo) {
    Fail "Unknown stage: $stage"
  }

  $missingFiles = @()
  foreach ($file in $stageInfo.files) {
    $fullPath = Join-Path $repoRoot $file
    if (-not (Test-Path $fullPath)) {
      $missingFiles += $file
    }
  }

  return @{
    Files = $stageInfo.files
    MissingFiles = $missingFiles
    DependsOn = $stageInfo.dependsOn
  }
}

function New-WorkflowState([string]$docsRoot, [string]$requirementId, [hashtable]$globals) {
  $state = [ordered]@{
    requirementId = $requirementId
    globals       = $globals
    artifacts     = [ordered]@{
      requirement = [ordered]@{
        file      = "docs/1-requirements/requirement-$requirementId.md"
        confirmed = $false
      }
      design = [ordered]@{
        consoleFile    = "docs/2-design/design-console-$requirementId.md"
        miniprogramFile = "docs/2-design/design-miniprogram-$requirementId.md"
        confirmed      = $false
      }
      api = [ordered]@{
        file      = "docs/3-api/api-$requirementId.md"
        confirmed = $false
      }
      plans = [ordered]@{
        backendFile  = "docs/4-plans/backend-plan-$requirementId.md"
        frontendFile = "docs/4-plans/frontend-plan-$requirementId.md"
        confirmed    = $false
      }
      implementation = [ordered]@{
        codeLogFile = "docs/code/code-$requirementId.md"
        testsFile   = "docs/5-tests/tests-$requirementId.md"
        completed   = $false
      }
    }
  }
  return $state
}

function Write-WorkflowState([string]$path, [object]$state) {
  $json = $state | ConvertTo-Json -Depth 10
  $dir = Split-Path -Parent $path
  if (!(Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
  }
  Set-Content -Path $path -Value $json -Encoding UTF8
}

function Read-WorkflowState([string]$path) {
  if (!(Test-Path $path)) {
    return $null
  }
  try {
    return (Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json)
  } catch {
    return $null
  }
}

function Get-ConfirmationStatus([string]$repoRoot, [string]$requirementId) {
  $workflowDir = Join-Path (Join-Path $repoRoot 'docs') '0-workflow'
  $statePath = Join-Path $workflowDir ("workflow-{0}.json" -f $requirementId)
  $state = Read-WorkflowState $statePath

  if ($null -eq $state) {
    return @{
      requirement = $false
      design = $false
      api = $false
      plans = $false
    }
  }

  return @{
    requirement = ($state.artifacts.requirement.confirmed -eq $true)
    design = ($state.artifacts.design.confirmed -eq $true)
    api = ($state.artifacts.api.confirmed -eq $true)
    plans = ($state.artifacts.plans.confirmed -eq $true)
  }
}

function Show-Status([string]$repoRoot, [string]$requirementId) {
  Write-Host ""
  Write-Host "Requirement ID: " -NoNewline -ForegroundColor Yellow
  Write-Host $requirementId
  Write-Host ""

  $artifacts = Get-StageArtifacts $requirementId
  $status = Get-ConfirmationStatus $repoRoot $requirementId

  foreach ($key in $artifacts.Keys) {
    $isConfirmed = $status.$key
    $stageName = $key.Substring(0, 1).ToUpper() + $key.Substring(1)
    $stageStatus = if ($isConfirmed) { "Confirmed" } else { "Pending" }
    $color = if ($isConfirmed) { 'Green' } else { 'Red' }

    Write-Host ("  {0,-15}" -f $stageName) -NoNewline -ForegroundColor White
    Write-Host "[$stageStatus]" -ForegroundColor $color
  }

  Write-Host ""
  Write-Host "Artifacts:" -ForegroundColor Yellow
  foreach ($key in $artifacts.Keys) {
    $stageInfo = $artifacts.$key
    Write-Host "  $key :"
    foreach ($file in $stageInfo.files) {
      $fullPath = Join-Path $repoRoot $file
      $exists = (Test-Path $fullPath)
      $icon = if ($exists) { "[√]" } else { "[ ]" }
      $fileColor = if ($exists) { 'Green' } else { 'Red' }
      Write-Host "    $icon " -NoNewline -ForegroundColor Gray
      Write-Host $file -ForegroundColor $fileColor
    }
  }
}

function Get-PreConfirmationStatus([string]$repoRoot, [string]$requirementId, [string]$stage) {
  $artifacts = Get-StageArtifacts $requirementId
  $stageInfo = $artifacts.$stage

  if ($null -eq $stageInfo) {
    return $null
  }

  $status = Get-ConfirmationStatus $repoRoot $requirementId
  $missingPrereqs = @()

  foreach ($prereq in $stageInfo.dependsOn) {
    if (-not $status.$prereq) {
      $missingPrereqs += $prereq
    }
  }

  return @{
    MissingPrerequisites = $missingPrereqs
    AllPrerequisitesMet = ($missingPrereqs.Count -eq 0)
  }
}

function Get-DependentArtifacts([string]$repoRoot, [string]$requirementId, [string]$stage) {
  $artifacts = Get-StageArtifacts $requirementId
  $allFiles = @()

  foreach ($key in $artifacts.Keys) {
    if ($key -eq $stage) { continue }
    $stageInfo = $artifacts.$key
    foreach ($file in $stageInfo.files) {
      $fullPath = Join-Path $repoRoot $file
      if (Test-Path $fullPath) {
        $allFiles += $file
      }
    }
  }

  return $allFiles
}

# Main Entry Point
if ($Command -eq 'help') {
  Write-Help
  exit 0
}

$repoRoot = Resolve-RepoRoot
$docsRoot = Get-DocsRoot $repoRoot
$workflowDir = Get-WorkflowDir $docsRoot
$statePath = Get-WorkflowStatePath $workflowDir $RequirementId

if ($Command -eq 'init') {
  Ensure-UniqueRequirementId $docsRoot $RequirementId
  $globals = @{}
  if ($GlobalsJson) {
    try {
      $globals = $GlobalsJson | ConvertFrom-Json -AsHashtable
    } catch {
      Fail "Failed to parse -GlobalsJson: $_"
    }
  }
  $state = New-WorkflowState $docsRoot $RequirementId $globals
  Write-WorkflowState $statePath $state
  Write-Banner
  Write-Host ("Workflow state created: {0}" -f $statePath) -ForegroundColor Green
  Write-Host ""
  Write-Host "Next steps:" -ForegroundColor Yellow
  Write-Host "  1. Generate PRD: docs/1-requirements/requirement-$RequirementId.md"
  Write-Host "  2. User confirms via chat ('已确认')"
  Write-Host "  3. Run: confirm -RequirementId '$RequirementId' -Stage requirement"
  exit 0
}

if ($Command -eq 'status') {
  Write-Banner
  Show-Status $repoRoot $RequirementId
  exit 0
}

if ($Command -eq 'check') {
  if (-not $Stage) { Fail 'check requires -Stage (requirement/design/api/plans/code).' }

  $validStages = @('requirement', 'design', 'api', 'plans', 'code')
  if ($Stage -notin $validStages) {
    Fail ("Unknown stage '{0}'. Allowed: {1}" -f $Stage, ($validStages -join ', '))
  }

  Write-Host "Checking stage: $Stage" -ForegroundColor Cyan
  Write-Host "Requirement ID: $RequirementId" -ForegroundColor White
  Write-Host ""

  $artifacts = Get-StageArtifacts $RequirementId
  $stageInfo = $artifacts.$Stage

  Write-Host "Expected artifacts for $Stage stage:" -ForegroundColor Yellow
  foreach ($file in $stageInfo.files) {
    Write-Host "  - $file"
  }
  Write-Host ""

  $testResult = Test-StageArtifacts $repoRoot $RequirementId $Stage

  if ($testResult.MissingFiles.Count -gt 0) {
    Write-Host "Missing files:" -ForegroundColor Red
    foreach ($file in $testResult.MissingFiles) {
      Write-Host "  ✗ $file"
    }
    Write-Host ""
  } else {
    Write-Host "All required files exist." -ForegroundColor Green
  }

  Write-Host "Checking prerequisites for $Stage stage..." -ForegroundColor Yellow
  $prereqResult = Get-PreConfirmationStatus $repoRoot $RequirementId $Stage

  if ($prereqResult.MissingPrerequisites.Count -gt 0) {
    Write-Host "Missing confirmations for prerequisites:" -ForegroundColor Red
    foreach ($prereq in $prereqResult.MissingPrerequisites) {
      Write-Host "  ✗ $prereq stage not confirmed"
    }
    Write-Host ""
  } else {
    Write-Host "All prerequisites are confirmed." -ForegroundColor Green
  }

  Write-Host ""
  if ($testResult.MissingFiles.Count -eq 0 -and $prereqResult.AllPrerequisitesMet) {
    Write-Host "Check PASSED: Ready to enter $Stage stage." -ForegroundColor Green
    exit 0
  } else {
    Write-Host "Check FAILED: Cannot enter $Stage stage." -ForegroundColor Red
    Write-Host ""
    Write-Host "To fix:" -ForegroundColor Yellow
    if ($testResult.MissingFiles.Count -gt 0) {
      Write-Host "  - Generate the missing files above"
    }
    if ($prereqResult.MissingPrerequisites.Count -gt 0) {
      Write-Host "  - Confirm the prerequisite stages: $($prereqResult.MissingPrerequisites -join ', ')"
    }
    exit 1
  }
}

if ($Command -eq 'confirm') {
  if (-not $Stage) { Fail 'confirm requires -Stage (requirement/design/api/plans/implementation).' }

  $validStages = @('requirement', 'design', 'api', 'plans', 'implementation')
  if ($Stage -notin $validStages) {
    Fail ("Unknown stage '{0}'. Allowed: {1}" -f $Stage, ($validStages -join ', '))
  }

  $state = Read-WorkflowState $statePath
  if ($null -eq $state) {
    Write-Host "Workflow state not found. Creating new state..." -ForegroundColor Yellow
    $state = New-WorkflowState $docsRoot $RequirementId @{}
  }

  if ($Stage -eq 'requirement') {
    $state.artifacts.requirement.confirmed = $true
    Write-Host "Requirement stage confirmed." -ForegroundColor Green
  }
  elseif ($Stage -eq 'design') {
    if ($state.artifacts.requirement.confirmed -ne $true) {
      Fail 'Cannot confirm Design: Requirement stage must be confirmed first.'
    }
    $state.artifacts.design.confirmed = $true
    Write-Host "Design stage confirmed." -ForegroundColor Green
  }
  elseif ($Stage -eq 'api') {
    if ($state.artifacts.requirement.confirmed -ne $true) {
      Fail 'Cannot confirm API: Requirement stage must be confirmed first.'
    }
    if ($state.artifacts.design.confirmed -ne $true) {
      Fail 'Cannot confirm API: Design stage must be confirmed first.'
    }
    $state.artifacts.api.confirmed = $true
    Write-Host "API stage confirmed." -ForegroundColor Green
  }
  elseif ($Stage -eq 'plans') {
    if ($state.artifacts.requirement.confirmed -ne $true) {
      Fail 'Cannot confirm Plans: Requirement stage must be confirmed first.'
    }
    if ($state.artifacts.design.confirmed -ne $true) {
      Fail 'Cannot confirm Plans: Design stage must be confirmed first.'
    }
    if ($state.artifacts.api.confirmed -ne $true) {
      Fail 'Cannot confirm Plans: API stage must be confirmed first.'
    }
    $state.artifacts.plans.confirmed = $true
    Write-Host "Plans stage confirmed." -ForegroundColor Green
  }
  elseif ($Stage -eq 'implementation') {
    if ($state.artifacts.plans.confirmed -ne $true) {
      Fail 'Cannot confirm Implementation: Plans stage must be confirmed first.'
    }
    $state.artifacts.implementation.completed = $true
    Write-Host "Implementation completed confirmed." -ForegroundColor Green
  }

  Write-WorkflowState $statePath $state
  exit 0
}

Fail 'Unknown command.'
