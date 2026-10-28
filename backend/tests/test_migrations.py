"""The Alembic migration must build the same tables the models declare."""
import os
import tempfile
from pathlib import Path

import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, inspect

from app.db import Base

BACKEND_DIR = Path(__file__).resolve().parents[1]


@pytest.mark.skipif(not os.environ["DATABASE_URL"].startswith("sqlite"), reason="runs against a scratch SQLite file")
def test_upgrade_head_matches_models():
    db_path = Path(tempfile.mkdtemp(prefix="aisport-migr-")) / "migr.db"
    config = Config(str(BACKEND_DIR / "alembic.ini"))
    config.set_main_option("sqlalchemy.url", "sqlite+aiosqlite:///" + db_path.as_posix())

    command.upgrade(config, "head")

    engine = create_engine("sqlite:///" + db_path.as_posix())
    tables = set(inspect(engine).get_table_names()) - {"alembic_version"}
    engine.dispose()
    assert tables == set(Base.metadata.tables)

    command.downgrade(config, "base")
