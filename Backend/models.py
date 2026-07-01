from sqlalchemy import Column, Integer, String, Float, DateTime
from database import Base
import datetime

class Patient(Base):
    __tablename__ = "patients"

    nik = Column(String, primary_key=True, index=True)
    name = Column(String)
    password_hash = Column(String)


class ScreeningRecord(Base):
    __tablename__ = "screening_records"

    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(String, index=True)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    
    # Clinical Features
    redness_index = Column(Float)
    confidence_score = Column(Float)
    anemia_status = Column(String) # "Anemia" or "Non-Anemia"
    image_url = Column(String, nullable=True)
    color_details = Column(String, nullable=True) # JSON string of color metrics
    
    # Cryptographic Data
    data_hash = Column(String, unique=True, index=True) # Generated SHA-256 hash
    blockchain_tx_id = Column(String, nullable=True)    # Saved after blockchain confirms
