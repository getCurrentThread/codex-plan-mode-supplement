import unittest

from src.auth import can_view


class CanViewTest(unittest.TestCase):
    def test_owner_can_view_self(self):
        self.assertTrue(can_view({'id': 1, 'is_admin': 0}, 1))

    def test_user_cannot_view_other_user(self):
        self.assertFalse(can_view({'id': 1, 'is_admin': 0}, 2))

    def test_admin_cannot_view_other_user_yet(self):
        # Current behavior: is_admin grants no extra access.
        self.assertFalse(can_view({'id': 3, 'is_admin': 1}, 1))


if __name__ == '__main__':
    unittest.main()
