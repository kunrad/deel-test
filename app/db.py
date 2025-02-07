import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# For local dev, you can set environment variables or default to something
# We assume you have a DB_URL env var like:
# postgresql://username:password@db-hostname:5432/db_name
DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_engine(DATABASE_URL, pool_pre_ping=True,
                       pool_size=5, max_overflow=10)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
