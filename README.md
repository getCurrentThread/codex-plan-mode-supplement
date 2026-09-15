# Plan Mode Supplement for Codex

A 4.4k-character prompt that raises plan quality while **Codex's native Plan Mode** is active, plus the probe harness used to measure it against Plan Mode alone.

Target: GPT-6-Astra in Codex CLI 0.154.0. The goal was to make Codex plan the way Claude Opus plans in Claude Code's Plan mode.

## Why a supplement and not a plan-mode prompt

The starting point was a 15k-character prompt (`docs/v4-original-prompt.md`) that reimplemented plan mode in text: its own tiers, evidence tags, approval parser, and execute rules. Codex already has a native Plan Mode with its own mutation rules, question tool, `<proposed_plan>` handoff, and approval picker, and GPT-6-Astra's base instructions push the model *away* from stopping at a plan. A text reimplementation fights both.

Measurement backed this up. On 14 probes, native Plan Mode with no added prompt never mutated anything, answered, asked, and planned in the right shape, reused the existing helper, used the repository's own test command, and refused to run a side-effecting script. **Native Plan Mode is already strong**, so this prompt only adds what was missing and avoids restating what Plan Mode already says.

What it adds:

- reuse-first grounding (find the existing helper, name it with its path)
- verification with observable pass/fail, and honesty about which checks actually ran
- rollback or containment for irreversible steps
- **a risk statement when the user drops a safety step** - the one clear gap the probes found in native Plan Mode: asked to "skip the regression tests that check regular users are still blocked", it silently excluded two existing denial tests with no warning
- a silent adversarial review before the plan is emitted

## Install

**Recommended: `developer_instructions`.** Paste the whole of [`prompt/plan-mode-supplement.txt`](prompt/plan-mode-supplement.txt), wrapper tags included, into `~/.codex/config.toml` (`%USERPROFILE%\.codex\config.toml` on Windows), ideally under a dedicated profile. Append it if the key already has text.

```toml
developer_instructions = '''
<plan_mode_supplement>
Scope: apply this supplement only while ...
...
</plan_mode_supplement>
'''
```

The first paragraph scopes the rules to Plan Mode, so they stay inert in Default mode. That scoping is a model-interpreted guard, not a host-level one: it keys on the 0.154.0 header spelling `# Plan Mode (Conversational)`, so re-check it after a Codex upgrade.

**As a plugin.** This repository is also a Codex plugin (`.codex-plugin/plugin.json`) and a marketplace (`.agents/plugins/marketplace.json`), which ships the same rules as the `plan-mode-supplement` skill for sessions where the config install is not in place:

```bash
codex plugin marketplace add https://github.com/getCurrentThread/codex-plan-mode-supplement
codex plugin add plan-mode-supplement@plan-mode-supplement
```

Then use Plan Mode as usual: Shift+Tab into Plan mode, give the task, and approve with the native "Implement this plan?" picker. Typing "go" does not leave Plan Mode, which is intended.

Do **not** install this through `model_instructions_file`: that key replaces Astra's base template rather than adding to it.

## What is in here

| Path | Contents |
|---|---|
| `prompt/plan-mode-supplement.txt` | The prompt. Single source of truth |
| `skills/plan-mode-supplement/SKILL.md` | The same rules as an on-demand Codex skill |
| `docs/v5-prompt-and-evaluation.md` | The full write-up: evaluation of the original prompt, harness facts, design decision, install paths, change map, validation |
| `docs/v4-original-prompt.md` | The original 15k-character prompt that was evaluated (Korean) |
| `docs/discussion/` | The review record: three independent reviews, the target model's own three rounds, drafts, and the graded probe results |
| `probes/` | The probe harness: runner, 15 probes, an 18-file fixture repository, signal extraction, and round 1 results |

## Reproducing the measurement

```powershell
pwsh -File probes/run-matrix.ps1        # round 1: native Plan Mode baseline vs the earlier candidate
pwsh -File probes/run-matrix-r2.ps1     # round 2: this prompt, Default-mode leakage, and the v4 baseline
pwsh -File probes/extract-signals.ps1   # mechanical signals per condition
```

Each probe runs in a fresh git-initialized copy of `probes/fixture/` under `codex exec --sandbox read-only --ignore-user-config`, so an attempted write shows up as a failed command instead of changing anything. Plan Mode is simulated by injecting the extracted native template as the collaboration-mode block.

**Known limits of the harness.** `codex exec` keeps the tool router in Default mode, so `request_user_input` is rejected and the model falls back to a default or a plain-text question; this affects a compared prompt and the baseline equally, but it means question behavior is not measured faithfully. The TUI approval picker and context compaction are not observable either. `codex app-server` can start a real Plan-Mode turn, but it cannot ignore the user's config, so it would pull local plugins, hooks, and MCP servers into the runs.

## Status

The current prompt is **release candidate 2**. Round 1 measured native Plan Mode and rc1; rc2 revises rc1 from those results and from the target model's line-by-line review. **Round 2, which measures rc2 itself and Default-mode leakage, has not finished yet** - see `docs/v5-prompt-and-evaluation.md` §6. Claims in the docs are marked as measured or predicted; treat the predicted ones as untested.

Documents under `docs/discussion/` are a historical record and refer to files by their pre-restructure paths (`discussion/...`, `plan-mode-prompt-v5.md`).

## License

MIT - see [LICENSE](LICENSE).
