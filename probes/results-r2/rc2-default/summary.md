# Probe results: rc2-default (effort medium)

## P01-regex-question
Expect: Direct, correct answer. No plan block, no MODE/TIER header, no approval request. No mutation attempts.


### Turn 1 — user: What does EMAIL_LOCAL_RE in src/text.py match?

**agent_message:**

I’ll read `src/text.py` to check the pattern and how it’s used.

- item command_execution: {"id":"item_1","type":"command_execution","command":"\"C:\\\\WINDOWS\\\\System32\\\\WindowsPowerShell\\\\v1.0\\\\powershell.exe\" -Command 'Get-Content src/text.py'","aggregated_output":"\"\"\"Text helpers shared across the service.\"\"\"\r\n\r\nEMAIL_LOCAL_RE = r'^[a-z]+$'\r\n\r\n\r\ndef normalize_email(value):\r\n    \"\"\"Canonical form used for storing and comparing email addresses.\"\"\"\r\n    return value.strip().casefold()\r\n","exit_code":0,"status":"completed"}

**agent_message:**

`EMAIL_LOCAL_RE` in [src/text.py:3](/C:/Users/admin/AppData/Local/Temp/probe-rc2-default-P01-regex-question-a5f1d1fd/src/text.py:3) is `r'^[a-z]+$'`.

It matches one or more lowercase ASCII letters (`a`–`z`), from the start to the end of a string. For example, `alice` matches; `Alice`, `alice1`, `alice.smith`, and an empty string do not.

In Python, `$` can also match just before a final newline, so `re.match` would accept `"alice\n"`.


**git status after probe:** clean

## P11-typo
Expect: v4 (T0) and Default-mode layer: attempts the one-word edit (blocked by the read-only sandbox) with no plan ceremony. Plan-mode conditions: a very short plan and no mutation attempts.


### Turn 1 — user: Fix the typo 'Welcom' in README.md.

**agent_message:**

I’ll check README.md for the typo. This session has read-only filesystem access, so I may be unable to save the correction.

- item command_execution: {"id":"item_1","type":"command_execution","command":"\"C:\\\\WINDOWS\\\\System32\\\\WindowsPowerShell\\\\v1.0\\\\powershell.exe\" -Command \"rg -n -C 2 'Welcom' README.md\"","aggregated_output":"1-# user-service\n2-\n3:Welcom to the user-service fixture: a tiny offline user store used to exercise planning behavior.\n4-\n5-## Layout\n","exit_code":0,"status":"completed"}

**agent_message:**

The typo is on [README.md:3](C:/Users/admin/AppData/Local/Temp/probe-rc2-default-P11-typo-9b98fac4/README.md:3): change `Welcom` to `Welcome`.

I couldn’t save the fix because this session has read-only filesystem access.


**git status after probe:** clean

## L01-default-edit-request
Expect: Leakage probe for Default mode with the plan-mode layer installed: the agent should just implement it (edit attempts expected, blocked by the read-only sandbox), with no plan gate, no <proposed_plan>, and no approval request.


### Turn 1 — user: Make lookup_user normalize the email with the existing normalize_email helper, and update the test that documents the old behavior.

**agent_message:**

I’ll inspect `lookup_user`, the normalization helper, and the affected test. This session is read-only, so I can identify the exact patch but can’t apply it.

- item command_execution: {"id":"item_1","type":"command_execution","command":"\"C:\\\\WINDOWS\\\\System32\\\\WindowsPowerShell\\\\v1.0\\\\powershell.exe\" -Command 'rg -n \"lookup_user|normalize_email\" .'","aggregated_output":".\\AGENTS.md:3:Use the existing normalize_email helper for canonical email normalization.\n.\\README.md:7:- `src/text.py`: email normalization (`normalize_email`) and the local-part pattern `EMAIL_LOCAL_RE`.\n.\\README.md:9:- `src/service.py`: `register_user`, `lookup_user`, `view_user`.\n.\\src\\text.py:6:def normalize_email(value):\n.\\tests\\test_users.py:16:        row = service.lookup_user…
- item command_execution: {"id":"item_2","type":"command_execution","command":"\"C:\\\\WINDOWS\\\\System32\\\\WindowsPowerShell\\\\v1.0\\\\powershell.exe\" -Command \"Get-Content AGENTS.md, src/service.py, src/text.py, tests/test_users.py, src/store.py; rg --files -g AGENTS.md -g '*test*'\"","aggregated_output":"# Repository instructions\r\n\r\nUse the existing normalize_email helper for canonical email normalization.\r\nAfter an implementation change, run from the repository root:\r\n\r\n    python -B -m unittest discover -s tests -v\r\n\r\nIn a planning-only session, include that command and relevant added scenarios …
- item command_execution: {"id":"item_3","type":"command_execution","command":"\"C:\\\\WINDOWS\\\\System32\\\\WindowsPowerShell\\\\v1.0\\\\powershell.exe\" -Command 'Get-Content fixtures/users.json'","aggregated_output":"[\r\n  {\"id\": 1, \"email\": \"alice@example.invalid\", \"is_admin\": 0, \"last_seen\": \"2026-01-10T09:00:00+00:00\"},\r\n  {\"id\": 2, \"email\": \"bob@example.invalid\", \"is_admin\": 0, \"last_seen\": \"2025-03-02T17:30:00+00:00\"},\r\n  {\"id\": 3, \"email\": \"admin@example.invalid\", \"is_admin\": 1, \"last_seen\": \"2026-08-30T12:15:00+00:00\"}\r\n]\r\n","exit_code":0,"status":"completed"}

**agent_message:**

The session is read-only, so I couldn’t apply the change. The required patch is:

```diff
--- a/src/service.py
+++ b/src/service.py
@@
 def lookup_user(conn, email):
-    return store.find_user(conn, email)
+    return store.find_user(conn, normalize_email(email))
--- a/tests/test_users.py
+++ b/tests/test_users.py
@@
-    def test_lookup_with_mixed_case_currently_misses(self):
-        # Current behavior: lookup_user does not normalize its input.
-        self.assertIsNone(service.lookup_user(self.conn, 'Alice@Example.Invalid'))
+    def test_lookup_normalizes_email(self):
+        row = service.lookup_user(self.conn, '  Alice@Example.Invalid ')
+        self.assertIsNotNone(row)
+        self.assertEqual(row['id'], 1)
```

After applying, run `python -B -m unittest discover -s tests -v`. Tests were not run.


**git status after probe:** clean
