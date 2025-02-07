from sqlalchemy import Column, Integer, String
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()


class IpRecord(Base):
    __tablename__ = "ip_records"

    id = Column(Integer, primary_key=True, index=True)
    ip = Column(String(50))
    reversed_ip = Column(String(50))
