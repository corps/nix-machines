"""Migration

Revision ID: add_triggers
Revises:
Create Date: 2024-04-14 05:57:51.156738

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

from wakimae.db import (on_insert_file_update_sequence_trigger,
                        on_update_file_update_sequence_trigger)

# revision identifiers, used by Alembic.
revision: str = "add_triggers"
down_revision: Union[str, None] = "d1838805711a"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = "d1838805711a"


def upgrade() -> None:
    op.execute(on_insert_file_update_sequence_trigger.create())
    op.execute(on_update_file_update_sequence_trigger.create())


def downgrade() -> None:
    op.execute(on_insert_file_update_sequence_trigger.delete())
    op.execute(on_update_file_update_sequence_trigger.delete())
