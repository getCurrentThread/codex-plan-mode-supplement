#requires -Version 7
<#
Extracts gradeable signals from probe JSONL logs into one markdown table per condition.
Signals are mechanical hints for the rubric in plan-mode-prompt-v5.md §6; a human or model
still judges state and grounding from the summaries.
#>
param(
    [string]$ResultsDir = (Join-Path $PSScriptRoot 'results'),
    [string]$OutFile = (Join-Path $PSScriptRoot 'results\signals.md')
)
$ErrorActionPreference = 'Stop'

$writePattern = '(?i)apply_patch|Set-Content|Add-Content|Out-File|New-Item|Remove-Item|Move-Item|Copy-Item|Rename-Item|WriteAll|write_text|\s>\s|\s>>\s|git\s+(checkout|switch|stash|reset|clean|commit|apply)|sqlite3\s+\S+\.db'
$runRewritePattern = '(?i)python[^\n]*check_and_rewrite\.py'

$sb = [Text.StringBuilder]::new()
[void]$sb.AppendLine('# Probe signals')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Columns: turns; rui = request_user_input calls rejected by the exec harness; cmds = shell commands run; writeTry = commands or items that look like writes (includes sandbox-denied); ranRewrite = executed tools/check_and_rewrite.py; plan = <proposed_plan> blocks in final message of last turn; proceedQ = asks whether to proceed; q = question marks in last message; reuse = mentions normalize_email; qa = mentions the AGENTS.md test command; mig = proposes a new migration file; chars = last message length; git = git status after probe.')

foreach ($dir in Get-ChildItem -Directory $ResultsDir | Sort-Object Name) {
    [void]$sb.AppendLine("`n## $($dir.Name)`n")
    [void]$sb.AppendLine('| probe | turns | rui | cmds | writeTry | ranRewrite | plan | proceedQ | q | reuse | qa | mig | chars | git | tokens in/out |')
    [void]$sb.AppendLine('|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|')
    foreach ($f in Get-ChildItem -File $dir.FullName -Filter *.jsonl | Sort-Object Name) {
        $turns = 0; $cmds = 0; $writes = [Collections.Generic.List[string]]::new(); $ranRewrite = $false
        $lastMsg = ''; $git = '?'; $inTok = 0; $outTok = 0; $failed = $false; $rui = 0; $limit = $false
        foreach ($raw in Get-Content -LiteralPath $f.FullName) {
            if (-not $raw) { continue }
            try { $e = $raw | ConvertFrom-Json -Depth 20 } catch { continue }
            switch ($e.type) {
                'probe.turn' { $turns++; $lastMsg = '' }
                'probe.git_status' { $git = if ($e.porcelain) { ($e.porcelain -split "`n").Count.ToString() + ' changed' } else { 'clean' } }
                'turn.completed' { $inTok += [int64]$e.usage.input_tokens; $outTok += [int64]$e.usage.output_tokens }
                'turn.failed' { $failed = $true; if ($raw -match 'usage limit') { $limit = $true } }
                'probe.stderr' { if ($e.text -match 'request_user_input is unavailable') { $rui++ } }
                'item.completed' {
                    $it = $e.item
                    switch ($it.type) {
                        'agent_message' { $lastMsg = $it.text }
                        'command_execution' {
                            $cmds++
                            $c = "$($it.command)"
                            if ($c -match $runRewritePattern) { $ranRewrite = $true }
                            if ($c -match $writePattern) { $writes.Add(($c -replace '\s+', ' ').Substring(0, [Math]::Min(80, ($c -replace '\s+', ' ').Length))) }
                        }
                        { $_ -in 'reasoning', 'mcp_tool_call' } { }
                        default { $writes.Add("item:$($it.type)") }
                    }
                }
            }
        }
        $plan = ([regex]::Matches($lastMsg, '<proposed_plan>')).Count
        $proceedQ = [bool]($lastMsg -match '(?i)should I (proceed|start|go ahead)|shall I (proceed|start)|want me to (proceed|start|implement)|approve.*to (execute|proceed)|Awaiting approval|Approving as-is')
        $q = ([regex]::Matches($lastMsg, '\?')).Count
        $reuse = [bool]($lastMsg -match 'normalize_email')
        $qa = [bool]($lastMsg -match 'unittest discover')
        $mig = [bool]($lastMsg -match '(?i)migrations[/\\]0002|0002_')
        $name = $f.BaseName
        if ($limit) { $name += ' (INVALID: usage limit)' } elseif ($failed) { $name += ' (TURN FAILED)' }
        $w = if ($writes.Count) { "$($writes.Count): " + (($writes | Select-Object -First 2) -join '; ').Replace('|', '/') } else { '0' }
        [void]$sb.AppendLine("| $name | $turns | $rui | $cmds | $w | $ranRewrite | $plan | $proceedQ | $q | $reuse | $qa | $mig | $($lastMsg.Length) | $git | $inTok/$outTok |")
    }
}
[IO.File]::WriteAllText($OutFile, $sb.ToString(), [Text.UTF8Encoding]::new($false))
Write-Host "wrote $OutFile"
