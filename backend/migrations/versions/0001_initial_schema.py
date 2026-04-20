"""Initial schema: users, roles, directories, assets, audit

Revision ID: 0001
Revises:
Create Date: 2024-01-01 00:00:00.000000
"""
from typing import Sequence, Union
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
from alembic import op

revision: str = "0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # --- roles ---
    op.create_table(
        "roles",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(50), nullable=False),
        sa.Column("display_name", sa.String(100), nullable=False),
        sa.Column("permissions", sa.Text(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("name"),
    )

    # --- users ---
    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("username", sa.String(100), nullable=False),
        sa.Column("email", sa.String(255), nullable=True),
        sa.Column("full_name", sa.String(255), nullable=False),
        sa.Column("hashed_password", sa.String(255), nullable=False),
        sa.Column("pin_hash", sa.String(255), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column("last_login_at", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("username"),
        sa.UniqueConstraint("email"),
    )
    op.create_index("ix_users_username", "users", ["username"])

    # --- user_roles ---
    op.create_table(
        "user_roles",
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("role_id", sa.Integer(), nullable=False),
        sa.Column("assigned_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["role_id"], ["roles.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("user_id", "role_id"),
    )

    # --- zones ---
    op.create_table(
        "zones",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("code", sa.String(50), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("code"),
    )

    # --- rooms ---
    op.create_table(
        "rooms",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("zone_id", sa.Integer(), nullable=True),
        sa.Column("code", sa.String(50), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("floor", sa.Integer(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["zone_id"], ["zones.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("code"),
    )

    # --- departments ---
    op.create_table(
        "departments",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("code", sa.String(50), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("parent_id", sa.Integer(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["parent_id"], ["departments.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("code"),
    )

    # --- asset_categories ---
    op.create_table(
        "asset_categories",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("code", sa.String(50), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("asset_type", sa.String(10), nullable=False),
        sa.Column("parent_id", sa.Integer(), nullable=True),
        sa.Column("account_code", sa.String(50), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["parent_id"], ["asset_categories.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("code"),
    )

    # --- assets ---
    op.create_table(
        "assets",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("inventory_number", sa.String(100), nullable=False),
        sa.Column("barcode", sa.String(200), nullable=True),
        sa.Column("name", sa.String(500), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("category_id", sa.Integer(), nullable=True),
        sa.Column("department_id", sa.Integer(), nullable=True),
        sa.Column("room_id", sa.Integer(), nullable=True),
        sa.Column("initial_cost", sa.Numeric(14, 2), nullable=True),
        sa.Column("residual_value", sa.Numeric(14, 2), nullable=True),
        sa.Column("commissioning_date", sa.Date(), nullable=True),
        sa.Column("useful_life_months", sa.Integer(), nullable=True),
        sa.Column("status", sa.String(50), nullable=False, server_default="active"),
        sa.Column("inventory_status", sa.String(50), nullable=False, server_default="not_scanned"),
        sa.Column("one_c_id", sa.String(100), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column("last_scanned_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(["category_id"], ["asset_categories.id"]),
        sa.ForeignKeyConstraint(["department_id"], ["departments.id"]),
        sa.ForeignKeyConstraint(["room_id"], ["rooms.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("inventory_number"),
    )
    op.create_index("ix_assets_inventory_number", "assets", ["inventory_number"])
    op.create_index("ix_assets_barcode", "assets", ["barcode"])
    op.create_index("ix_assets_one_c_id", "assets", ["one_c_id"])

    # --- asset_photos ---
    op.create_table(
        "asset_photos",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("asset_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("s3_key", sa.String(500), nullable=False),
        sa.Column("original_filename", sa.String(255), nullable=True),
        sa.Column("is_primary", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("uploaded_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["asset_id"], ["assets.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )

    # --- audit_logs ---
    op.create_table(
        "audit_logs",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("action", sa.String(100), nullable=False),
        sa.Column("entity_type", sa.String(100), nullable=True),
        sa.Column("entity_id", sa.String(100), nullable=True),
        sa.Column("old_values", postgresql.JSONB(), nullable=True),
        sa.Column("new_values", postgresql.JSONB(), nullable=True),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("user_agent", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_audit_logs_action", "audit_logs", ["action"])
    op.create_index("ix_audit_logs_created_at", "audit_logs", ["created_at"])

    # --- sync_queue ---
    op.create_table(
        "sync_queue",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("device_id", sa.String(100), nullable=False),
        sa.Column("operation", sa.String(50), nullable=False),
        sa.Column("entity_type", sa.String(100), nullable=False),
        sa.Column("entity_id", sa.String(100), nullable=False),
        sa.Column("payload", postgresql.JSONB(), nullable=True),
        sa.Column("status", sa.String(50), nullable=False, server_default="pending"),
        sa.Column("retry_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column("processed_at", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_sync_queue_device_id", "sync_queue", ["device_id"])
    op.create_index("ix_sync_queue_status", "sync_queue", ["status"])

    # --- Seed default roles ---
    op.execute("""
        INSERT INTO roles (name, display_name) VALUES
        ('admin', 'Администратор'),
        ('supervisor', 'Супервайзер'),
        ('inventorizator', 'Инвентаризатор'),
        ('accountant', 'Бухгалтер'),
        ('observer', 'Наблюдатель')
    """)


def downgrade() -> None:
    op.drop_table("sync_queue")
    op.drop_table("audit_logs")
    op.drop_table("asset_photos")
    op.drop_table("assets")
    op.drop_table("asset_categories")
    op.drop_table("departments")
    op.drop_table("rooms")
    op.drop_table("zones")
    op.drop_table("user_roles")
    op.drop_table("users")
    op.drop_table("roles")
