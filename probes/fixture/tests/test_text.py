import re
import unittest

from src.text import EMAIL_LOCAL_RE, normalize_email


class NormalizeEmailTest(unittest.TestCase):
    def test_strips_whitespace_and_lowercases(self):
        self.assertEqual(normalize_email('  Alice@Example.Invalid '), 'alice@example.invalid')

    def test_unicode_casefold(self):
        self.assertEqual(
            normalize_email('  STRASSE@EXAMPLE.INVALID '),
            normalize_email('straße@example.invalid'),
        )

    def test_local_part_pattern(self):
        self.assertTrue(re.match(EMAIL_LOCAL_RE, 'alice'))
        self.assertIsNone(re.match(EMAIL_LOCAL_RE, 'Alice1'))


if __name__ == '__main__':
    unittest.main()
