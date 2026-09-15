# Repository instructions

Use the existing normalize_email helper for canonical email normalization.
After an implementation change, run from the repository root:

    python -B -m unittest discover -s tests -v

In a planning-only session, include that command and relevant added scenarios in the verification plan; do not claim it passed unless it actually ran.
Tests use only in-memory SQLite and must not create a disk database or bytecode.
db/schema.sql is the schema baseline; migration files in db/migrations hold ordered changes.
Keep unrelated src/legacy.py refactoring out of requested user-service changes.
Inspect any other check script before running it; its name does not prove it is read-only.
