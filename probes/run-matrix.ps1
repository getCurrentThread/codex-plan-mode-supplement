#requires -Version 7
# Runs the four probe conditions described in plan-mode-prompt-v5.md §6, one after another.
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$runner = Join-Path $root 'run-probes.ps1'
$common = @{
    ProbesFile = Join-Path $root 'probes.json'
    FixtureDir = Join-Path $root 'fixture'
    Parallel   = 4
}
$planTemplate = Join-Path $root 'native-plan-mode.txt'
$v5 = Join-Path (Split-Path $root) 'docs\discussion\v5-rc1.md'
$v4 = Join-Path (Split-Path $root) 'docs\v4-original-prompt.md'
$planProbes = 'P01-regex-question', 'P02-nullable-column', 'P03-praise-after-plan', 'P04-go-go-after-plan',
    'P05-override-prod-delete', 'P06-missing-file', 'P07-injection-agents-reuse', 'P08-admin-authz',
    'P09-contradiction', 'P10-undecided-policy', 'P11-typo', 'P12-partial-approval-drops-safety',
    'P13-side-effect-check-script', 'P14-new-module-design'

$runs = @(
    @{ Label = 'native-control'; PromptFile = 'none'; Effort = 'xhigh'; PlanModeTemplate = $planTemplate; Only = $planProbes },
    @{ Label = 'v5-plan'; PromptFile = $v5; Effort = 'xhigh'; PlanModeTemplate = $planTemplate; Only = $planProbes },
    @{ Label = 'v5-default'; PromptFile = $v5; Effort = 'medium'; Only = @('L01-default-edit-request', 'P01-regex-question', 'P11-typo') },
    @{ Label = 'v4-default'; PromptFile = $v4; Effort = 'medium'; Only = @('P01-regex-question', 'P03-praise-after-plan', 'P04-go-go-after-plan', 'P05-override-prod-delete', 'P07-injection-agents-reuse', 'P11-typo', 'P12-partial-approval-drops-safety') }
)

foreach ($r in $runs) {
    $start = Get-Date
    Write-Host "=== $($r.Label) started $start"
    & $runner @common @r
    Write-Host "=== $($r.Label) finished in $([int]((Get-Date) - $start).TotalMinutes) min"
}
