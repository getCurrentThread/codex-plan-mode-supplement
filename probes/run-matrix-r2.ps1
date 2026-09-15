#requires -Version 7
# Probe round 2: v5-rc2 in simulated Plan Mode and in Default mode, then the v4 baseline.
# Runs in priority order so that, if the usage limit hits again, the most discriminating probes are done.
# native-control is not rerun: round 1 (results/native-control) is the baseline.
param([string]$OutDir = (Join-Path $PSScriptRoot 'results-r2'))
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$runner = Join-Path $root 'run-probes.ps1'
$common = @{
    ProbesFile = Join-Path $root 'probes.json'
    FixtureDir = Join-Path $root 'fixture'
    OutDir     = $OutDir
    Parallel   = 4
}
$planTemplate = Join-Path $root 'native-plan-mode.txt'
$rc2 = Join-Path (Split-Path $root) 'prompt\plan-mode-supplement.txt'
$v4 = Join-Path (Split-Path $root) 'docs\v4-original-prompt.md'

$runs = @(
    @{ Label = 'rc2-plan'; PromptFile = $rc2; Effort = 'xhigh'; PlanModeTemplate = $planTemplate
        Only = @('P12-partial-approval-drops-safety', 'P03-praise-after-plan', 'P13-side-effect-check-script', 'P14-new-module-design',
            'P10-undecided-policy', 'P08-admin-authz', 'P04-go-go-after-plan', 'P02-nullable-column') },
    @{ Label = 'rc2-default'; PromptFile = $rc2; Effort = 'medium'; Only = @('L01-default-edit-request', 'P01-regex-question', 'P11-typo') },
    @{ Label = 'rc2-plan-b'; PromptFile = $rc2; Effort = 'xhigh'; PlanModeTemplate = $planTemplate
        Only = @('P01-regex-question', 'P05-override-prod-delete', 'P06-missing-file', 'P07-injection-agents-reuse', 'P09-contradiction', 'P11-typo') },
    @{ Label = 'v4-default'; PromptFile = $v4; Effort = 'medium'
        Only = @('P01-regex-question', 'P03-praise-after-plan', 'P04-go-go-after-plan', 'P05-override-prod-delete', 'P07-injection-agents-reuse', 'P11-typo', 'P12-partial-approval-drops-safety') }
)

New-Item -ItemType Directory -Force $OutDir | Out-Null
Remove-Item -LiteralPath (Join-Path $OutDir '.usage-limit-hit') -ErrorAction SilentlyContinue
foreach ($r in $runs) {
    if (Test-Path -LiteralPath (Join-Path $OutDir '.usage-limit-hit')) { Write-Host "=== usage limit hit; skipping $($r.Label) and later runs"; break }
    $start = Get-Date
    Write-Host "=== $($r.Label) started $start"
    & $runner @common @r
    Write-Host "=== $($r.Label) finished in $([int]((Get-Date) - $start).TotalMinutes) min"
}
& (Join-Path $root 'extract-signals.ps1') -ResultsDir $OutDir -OutFile (Join-Path $OutDir 'signals.md')
