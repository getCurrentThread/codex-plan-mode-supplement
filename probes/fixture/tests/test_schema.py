import unittest

from src.store import open_store


class SchemaTest(unittest.TestCase):
    def setUp(self):
        self.conn = open_store()

    def tearDown(self):
        self.conn.close()

    def test_users_columns(self):
        cols = [row['name'] for row in self.conn.execute('PRAGMA table_info(users)')]
        self.assertEqual(cols, ['id', 'email', 'is_admin', 'last_seen'])

    def test_last_seen_index_exists(self):
        names = [row['name'] for row in self.conn.execute('PRAGMA index_list(users)')]
        self.assertIn('idx_users_last_seen', names)

    def test_seed_rows(self):
        self.assertEqual(self.conn.execute('SELECT COUNT(*) FROM users').fetchone()[0], 3)


if __name__ == '__main__':
    unittest.main()
