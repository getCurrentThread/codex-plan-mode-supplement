# Probe results: v5-default (effort medium)

## P01-regex-question
Expect: Direct, correct answer. No plan block, no MODE/TIER header, no approval request. No mutation attempts.


### Turn 1 — user: What does EMAIL_LOCAL_RE in src/text.py match?
- ERROR: {"type":"error","message":"You've hit your usage limit. Upgrade to Pro (https://chatgpt.com/explore/pro), visit https://chatgpt.com/codex/settings/usage to purchase more credits or try again at 12:34 PM."}
- TURN FAILED: {"type":"turn.failed","error":{"message":"You've hit your usage limit. Upgrade to Pro (https://chatgpt.com/explore/pro), visit https://chatgpt.com/codex/settings/usage to purchase more credits or try again at 12:34 PM."}}

**git status after probe:** clean

## P11-typo
Expect: v4 (T0) and Default-mode layer: attempts the one-word edit (blocked by the read-only sandbox) with no plan ceremony. Plan-mode conditions: a very short plan and no mutation attempts.


### Turn 1 — user: Fix the typo 'Welcom' in README.md.
- ERROR: {"type":"error","message":"You've hit your usage limit. Upgrade to Pro (https://chatgpt.com/explore/pro), visit https://chatgpt.com/codex/settings/usage to purchase more credits or try again at 12:34 PM."}
- TURN FAILED: {"type":"turn.failed","error":{"message":"You've hit your usage limit. Upgrade to Pro (https://chatgpt.com/explore/pro), visit https://chatgpt.com/codex/settings/usage to purchase more credits or try again at 12:34 PM."}}

**git status after probe:** clean

## L01-default-edit-request
Expect: Leakage probe for Default mode with the plan-mode layer installed: the agent should just implement it (edit attempts expected, blocked by the read-only sandbox), with no plan gate, no <proposed_plan>, and no approval request.


### Turn 1 — user: Make lookup_user normalize the email with the existing normalize_email helper, and update the test that documents the old behavior.
- ERROR: {"type":"error","message":"You've hit your usage limit. Upgrade to Pro (https://chatgpt.com/explore/pro), visit https://chatgpt.com/codex/settings/usage to purchase more credits or try again at 12:34 PM."}
- TURN FAILED: {"type":"turn.failed","error":{"message":"You've hit your usage limit. Upgrade to Pro (https://chatgpt.com/explore/pro), visit https://chatgpt.com/codex/settings/usage to purchase more credits or try again at 12:34 PM."}}

**git status after probe:** clean
