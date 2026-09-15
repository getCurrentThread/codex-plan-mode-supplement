"""Text helpers shared across the service."""

EMAIL_LOCAL_RE = r'^[a-z]+$'


def normalize_email(value):
    """Canonical form used for storing and comparing email addresses."""
    return value.strip().casefold()
