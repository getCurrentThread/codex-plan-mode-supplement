import unittest

from src import service
from src.store import open_store


class UsersTest(unittest.TestCase):
    def setUp(self):
        self.conn = open_store()

    def tearDown(self):
        self.conn.close()

    def test_register_normalizes_email(self):
        user_id = service.register_user(self.conn, '  Carol@Example.Invalid ')
        row = service.lookup_user(self.conn, 'carol@example.invalid')
        self.assertEqual(row['id'], user_id)

    def test_lookup_with_mixed_case_currently_misses(self):
        # Current behavior: lookup_user does not normalize its input.
        self.assertIsNone(service.lookup_user(self.conn, 'Alice@Example.Invalid'))

    def test_view_user_enforces_can_view(self):
        with self.assertRaises(PermissionError):
            service.view_user(self.conn, {'id': 1, 'is_admin': 0}, 2)


if __name__ == '__main__':
    unittest.main()
