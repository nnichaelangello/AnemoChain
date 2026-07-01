from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class PatientCreate(BaseModel):
    nik: str
    name: str
    password: str

class PatientLogin(BaseModel):
    nik: str
    password: str


class ScreeningCreate(BaseModel):
    patient_id: str
    redness_index: float
    confidence_score: float
    anemia_status: str
    color_details: Optional[str] = None

class ScreeningResponse(BaseModel):
    id: int
    patient_id: str
    timestamp: datetime
    redness_index: float
    confidence_score: float
    anemia_status: str
    data_hash: str
    blockchain_tx_id: Optional[str] = None
    image_url: Optional[str] = None
    color_details: Optional[str] = None

    class Config:
        from_attributes = True
