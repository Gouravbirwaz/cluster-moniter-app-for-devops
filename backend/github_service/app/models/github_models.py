from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime
from ..database import Base

class Repository(Base):
    __tablename__ = "repositories"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, unique=True, index=True) # owner/repo
    owner = Column(String)
    name = Column(String)
    token_secret_name = Column(String)
    description = Column(String, nullable=True)
    stars = Column(Integer, default=0)
    forks = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "full_name": self.full_name,
            "owner": self.owner,
            "name": self.name,
            "description": self.description,
            "stars": self.stars,
            "forks": self.forks,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }
