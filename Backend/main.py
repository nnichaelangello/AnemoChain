import hashlib
import datetime
import requests
import io
from fastapi import FastAPI, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from PIL import Image
import shutil
import os
from dotenv import load_dotenv

# Load environment variables
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(BASE_DIR, "..", ".env"))

import ml_utils

import models
import schemas
from database import engine, get_db

# Create the database tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Anemia Skrining Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

def generate_hash(patient_id: str, timestamp: datetime.datetime, status: str) -> str:
    """Generate SHA-256 Hash to ensure data tamper-proofness"""
    payload = f"{patient_id}_{timestamp.isoformat()}_{status}"
    return hashlib.sha256(payload.encode('utf-8')).hexdigest()

@app.get("/")
def read_root():
    return {"message": "Anemia Backend Server is Running"}

def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

@app.post("/api/register")
def register(patient: schemas.PatientCreate, db: Session = Depends(get_db)):
    existing = db.query(models.Patient).filter(models.Patient.nik == patient.nik).first()
    if existing:
        raise HTTPException(status_code=400, detail="NIK sudah terdaftar")
    
    new_patient = models.Patient(
        nik=patient.nik,
        name=patient.name,
        password_hash=hash_password(patient.password)
    )
    db.add(new_patient)
    db.commit()
    return {"message": "Registrasi berhasil"}

@app.post("/api/login")
def login(creds: schemas.PatientLogin, db: Session = Depends(get_db)):
    patient = db.query(models.Patient).filter(models.Patient.nik == creds.nik).first()
    if not patient or patient.password_hash != hash_password(creds.password):
        raise HTTPException(status_code=401, detail="Invalid Patient ID or Password")
    
    return {"message": "Login berhasil", "patient_id": patient.nik, "name": patient.name}

@app.post("/api/predict")
async def predict_anemia(file: UploadFile = File(...)):
    """ Endpoint for the Edge AI Simulation. Receives image from phone, returns prediction. """
    try:
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        prediction = ml_utils.predict_image(image)
        return prediction
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error processing image: {str(e)}")

@app.post("/api/blockchain_sync")
def blockchain_sync(screening: schemas.ScreeningCreate):
    """
    1. Blockchain First Logic: This endpoint ONLY hashes and sends to blockchain. 
    It does NOT save to the SQLite database.
    """
    current_time = datetime.datetime.utcnow()
    data_hash = generate_hash(screening.patient_id, current_time, screening.anemia_status)
    
    blockchain_base_url = os.getenv("BLOCKCHAIN_NODE_URL", "http://localhost:8001")
    blockchain_url = f"{blockchain_base_url}/api/chaincode/invoke"
    payload = {
        "patient_id": screening.patient_id,
        "timestamp": current_time.isoformat(),
        "status": screening.anemia_status,
        "data_hash": data_hash,
        "color_details": screening.color_details
    }
    
    try:
        response = requests.post(blockchain_url, json=payload, timeout=5)
        if response.status_code == 200:
            tx_data = response.json()
            return {
                "tx_id": tx_data.get("tx_id"),
                "timestamp": current_time.isoformat(),
                "data_hash": data_hash
            }
        else:
            raise HTTPException(status_code=500, detail="Failed to sync to blockchain node")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Blockchain connection error: {str(e)}")


@app.post("/api/screenings")
async def create_screening(
    patient_id: str = Form(...),
    redness_index: float = Form(...),
    confidence_score: float = Form(...),
    anemia_status: str = Form(...),
    timestamp: str = Form(...),
    data_hash: str = Form(...),
    blockchain_tx_id: str = Form(...),
    color_details: str = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """
    2. Database Last Logic: This endpoint receives the complete package 
    (data + original blockchain timestamp/hash + image) from the user's history page
    and finally saves it to the SQLite database.
    """
    dt_timestamp = datetime.datetime.fromisoformat(timestamp)
    
    file_extension = file.filename.split(".")[-1] if "." in file.filename else "jpg"
    file_path = f"uploads/{blockchain_tx_id}.{file_extension}"
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    image_url = f"/uploads/{blockchain_tx_id}.{file_extension}"

    db_record = models.ScreeningRecord(
        patient_id=patient_id,
        timestamp=dt_timestamp,
        redness_index=redness_index,
        confidence_score=confidence_score,
        anemia_status=anemia_status,
        data_hash=data_hash,
        blockchain_tx_id=blockchain_tx_id,
        image_url=image_url,
        color_details=color_details
    )
    db.add(db_record)
    db.commit()
    db.refresh(db_record)
    
    return {"status": "SUCCESS", "record_id": db_record.id}


@app.get("/api/screenings/{patient_id}", response_model=list[schemas.ScreeningResponse])
def get_screenings(patient_id: str, db: Session = Depends(get_db)):
    records = db.query(models.ScreeningRecord).filter(
        models.ScreeningRecord.patient_id == patient_id
    ).order_by(models.ScreeningRecord.timestamp.desc()).all()
    
    if not records:
        raise HTTPException(status_code=404, detail="Patient not found")
    return records
