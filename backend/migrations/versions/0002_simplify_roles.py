"""Simplify roles to admin and user only

Revision ID: 0002
Revises: 0001
Create Date: 2026-04-21
"""
from typing import Union
from alembic import op

revision: str = "0002"
down_revision: Union[str, None] = "0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Insert 'user' role if it doesn't exist
    op.execute("INSERT INTO roles (name, display_name) VALUES ('user', 'Пользователь') ON CONFLICT (name) DO NOTHING")

    # Reassign any users with old roles (supervisor/inventorizator/accountant/observer)
    # to 'user' role, avoiding duplicates
    op.execute("""
        INSERT INTO user_roles (user_id, role_id, assigned_at)
        SELECT ur.user_id, (SELECT id FROM roles WHERE name = 'user'), ur.assigned_at
        FROM user_roles ur
        JOIN roles r ON r.id = ur.role_id
        WHERE r.name IN ('supervisor', 'inventorizator', 'accountant', 'observer')
        ON CONFLICT DO NOTHING
    """)

    # Remove old role assignments
    op.execute("""
        DELETE FROM user_roles
        WHERE role_id IN (SELECT id FROM roles WHERE name IN ('supervisor', 'inventorizator', 'accountant', 'observer'))
    """)

    # Remove old roles
    op.execute("DELETE FROM roles WHERE name IN ('supervisor', 'inventorizator', 'accountant', 'observer')")


def downgrade() -> None:
    op.execute("""
        INSERT INTO roles (name, display_name) VALUES
        ('supervisor', 'Супервайзер'),
        ('inventorizator', 'Инвентаризатор'),
        ('accountant', 'Бухгалтер'),
        ('observer', 'Наблюдатель')
        ON CONFLICT (name) DO NOTHING
    """)
