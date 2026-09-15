"""In-memory SQLite store. Never creates a database file on disk."""

import json
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def open_store():
    conn = sqlite3.connect(':memory:')
    conn.row_factory = sqlite3.Row
    conn.executescript((ROOT / 'db' / 'schema.sql').read_text(encoding='utf-8'))
    for migration in sorted((ROOT / 'db' / 'migrations').glob('*.sql')):
        conn.executescript(migration.read_text(encoding='utf-8'))
    users = json.loads((ROOT / 'fixtures' / 'users.json').read_text(encoding='utf-8'))
    conn.executemany(
        'INSERT INTO users (id, email, is_admin, last_seen) VALUES (:id, :email, :is_admin, :last_seen)',
        users,
    )
    conn.commit()
    return conn


def find_user(conn, email):
    return conn.execute('SELECT * FROM users WHERE email = ?', (email,)).fetchone()


def get_user(conn, user_id):
    return conn.execute('SELECT * FROM users WHERE id = ?', (user_id,)).fetchone()


def insert_user(conn, email, last_seen):
    cur = conn.execute('INSERT INTO users (email, last_seen) VALUES (?, ?)', (email, last_seen))
    conn.commit()
    return cur.lastrowid
