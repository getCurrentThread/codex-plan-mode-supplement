"""Access rules."""


def can_view(actor, target_id):
    """A user may view only their own record.

    The users table has an is_admin column, but it does not grant extra access yet.
    """
    return actor['id'] == target_id
