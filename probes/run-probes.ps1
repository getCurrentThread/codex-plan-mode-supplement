#requires -Version 7
<#
Runs behavioral probes of a plan-mode prompt against GPT-6-Astra through `codex exec`.

The prompt is injected as `developer_instructions` (added on top of Astra's built-in
instructions, the same slot a real deployment in config.toml uses). Each probe runs in a
fresh git-initialized copy of the fixture under a read-only sandbox, so attempted writes show
up as failed commands in the event log instead of changing anything.

Multi-turn probes resume the same thread with `codex exec resume <thread_id>`.

Output per probe: <OutDir>/<Label>/<probe-id>.jsonl (raw events, one probe.turn marker per
turn) and <OutDir>/<Label>/summary.md (final messages, commands, file changes, git status).
#>
param(
    # Markdown file whose first ```text block is the prompt (or a plain text file). 'none' injects no prompt.
    [Parameter(Mandatory)][string]$PromptFile,
    [Parameter(Mandatory)][string]$Label,
    [Parameter(Mandatory)][string]$ProbesFile,
    [Parameter(Mandatory)][string]$FixtureDir,
    [string]$OutDir = (Join-Path $PSScriptRoot 'results'),
    [string]$Effort = 'medium',
    # Simulate native Plan mode: disable the harness's own <collaboration_mode> block and inject this
    # Plan Mode template (extracted from codex.exe) ahead of the prompt instead.
    [string]$PlanModeTemplate,
    [string[]]$Only,
    [int]$Parallel = 4
)
$ErrorActionPreference = 'Stop'

function Get-PromptBlock([string]$Path) {
    $raw = Get-Content -Raw -LiteralPath $Path
    $m = [regex]::Match($raw, '(?ms)^```text\r?\n(?<p>.*?)^```[ \t]*\r?$')
    if ($m.Success) { return $m.Groups['p'].Value.Trim() }
    return $raw.Trim()
}

$block = if ($PromptFile -eq 'none') { '' } else { Get-PromptBlock $PromptFile }
$extraCfg = @()
if ($PlanModeTemplate) {
    $planText = (Get-Content -Raw -LiteralPath $PlanModeTemplate).Trim()
    $block = ("<collaboration_mode>`n$planText`n</collaboration_mode>`n`n$block").Trim()
    $extraCfg = @('-c', 'include_collaboration_mode_instructions=false')
}
$devCfg = 'developer_instructions=' + (ConvertTo-Json -InputObject $block -Compress)
$probes = Get-Content -Raw -LiteralPath $ProbesFile | ConvertFrom-Json
if ($Only) { $probes = $probes | Where-Object { $Only -contains $_.id } }
# Codex picks `pwsh` from PATH first. The Microsoft Store pwsh under WindowsApps cannot start inside
# the Windows restricted-token sandbox (CreateProcessAsUserW fails), so hide it and let Codex fall
# back to Windows PowerShell 5.1, which runs sandboxed. rg, git, and python live elsewhere.
$env:PATH = ($env:PATH -split ';' | Where-Object { $_ -and $_ -notmatch '\\WindowsApps' }) -join ';'
$labelDir = Join-Path $OutDir $Label
New-Item -ItemType Directory -Force $labelDir | Out-Null
$fixture = (Resolve-Path $FixtureDir).Path

Write-Host "prompt chars: $($block.Length); probes: $(@($probes).Count); effort: $Effort"

# Once any probe hits the account usage limit, later probes are skipped instead of burning more attempts.
$limitFlag = Join-Path $OutDir '.usage-limit-hit'

$probes | ForEach-Object -ThrottleLimit $Parallel -Parallel {
    $p = $_
    if (Test-Path -LiteralPath $using:limitFlag) { return }
    $work = Join-Path ([IO.Path]::GetTempPath()) ("probe-{0}-{1}-{2}" -f $using:Label, $p.id, [guid]::NewGuid().ToString('N').Substring(0, 8))
    Copy-Item -Recurse -LiteralPath $using:fixture -Destination $work
    git -C $work init -q 2>$null
    git -C $work add -A 2>$null
    git -C $work -c user.email=probe@local -c user.name=probe commit -qm fixture 2>$null

    $log = Join-Path $using:labelDir "$($p.id).jsonl"
    Set-Content -LiteralPath $log -Value $null
    $common = @(
        '--model', 'gpt-6-astra',
        '--ignore-user-config', '--skip-git-repo-check', '--json',
        '-c', 'approval_policy="never"',
        # --ignore-user-config drops the user's [windows] section; without a Windows sandbox level
        # every shell command is rejected by policy.
        '-c', 'windows.sandbox="unelevated"',
        '-c', ('model_reasoning_effort="{0}"' -f $using:Effort),
        '-c', $using:devCfg
    ) + $using:extraCfg
    $thread = $null
    $i = 0
    foreach ($turn in $p.turns) {
        $i++
        Add-Content -LiteralPath $log -Value (@{ type = 'probe.turn'; index = $i; prompt = $turn } | ConvertTo-Json -Compress)
        if (-not $thread) {
            $lines = codex exec --cd $work --sandbox read-only @common $turn 2>&1
        } else {
            $lines = codex exec --cd $work --sandbox read-only resume @common $thread $turn 2>&1
        }
        foreach ($l in $lines) {
            $s = "$l"
            if ($s.StartsWith('{')) {
                Add-Content -LiteralPath $log -Value $s
                if ($s -match 'hit your usage limit') { Set-Content -LiteralPath $using:limitFlag -Value $s }
                if (-not $thread) {
                    try { $e = $s | ConvertFrom-Json; if ($e.type -eq 'thread.started') { $thread = $e.thread_id } } catch {}
                }
            } elseif ($s -and $s -notmatch '^Reading additional input') {
                Add-Content -LiteralPath $log -Value (@{ type = 'probe.stderr'; text = $s } | ConvertTo-Json -Compress)
            }
        }
        if (-not $thread -or (Test-Path -LiteralPath $using:limitFlag)) { break }
    }
    $status = (git -C $work status --porcelain 2>$null) -join "`n"
    Add-Content -LiteralPath $log -Value (@{ type = 'probe.git_status'; porcelain = $status; workdir = $work } | ConvertTo-Json -Compress)
}

# Summary
$sb = [Text.StringBuilder]::new()
[void]$sb.AppendLine("# Probe results: $Label (effort $Effort)")
foreach ($p in $probes) {
    $log = Join-Path $labelDir "$($p.id).jsonl"
    if (-not (Test-Path $log)) { continue }
    [void]$sb.AppendLine("`n## $($p.id)")
    if ($p.expect) { [void]$sb.AppendLine("Expect: $($p.expect)`n") }
    foreach ($raw in Get-Content -LiteralPath $log) {
        if (-not $raw) { continue }
        try { $e = $raw | ConvertFrom-Json } catch { continue }
        switch ($e.type) {
            'probe.turn' { [void]$sb.AppendLine("`n### Turn $($e.index) — user: $($e.prompt)") }
            'probe.stderr' { [void]$sb.AppendLine("- stderr: $($e.text)") }
            'probe.git_status' { [void]$sb.AppendLine("`n**git status after probe:** " + ($(if ($e.porcelain) { "`n``````n$($e.porcelain)`n``````" } else { 'clean' }))) }
            'item.completed' {
                $it = $e.item
                switch ($it.type) {
                    'agent_message' { [void]$sb.AppendLine("`n**agent_message:**`n`n$($it.text)`n") }
                    'reasoning' { }
                    default {
                        $brief = ($it | ConvertTo-Json -Compress -Depth 6)
                        if ($brief.Length -gt 600) { $brief = $brief.Substring(0, 600) + '…' }
                        [void]$sb.AppendLine("- item $($it.type): $brief")
                    }
                }
            }
            'turn.failed' { [void]$sb.AppendLine("- TURN FAILED: $($raw)") }
            'error' { [void]$sb.AppendLine("- ERROR: $($raw)") }
        }
    }
}
$summary = Join-Path $labelDir 'summary.md'
[IO.File]::WriteAllText($summary, $sb.ToString(), [Text.UTF8Encoding]::new($false))
Write-Host "summary: $summary"
