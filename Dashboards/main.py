from fastapi import FastAPI, Request
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse
import os
from dotenv import load_dotenv

app = FastAPI(title="Web Dashboards")
# Ensure the path resolves correctly to the templates folder
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
templates = Jinja2Templates(directory=os.path.join(BASE_DIR, "templates"))

load_dotenv(os.path.join(BASE_DIR, "..", ".env"))

BACKEND_URL = os.getenv("BACKEND_API_URL", "http://localhost:8000")
BLOCKCHAIN_URL = os.getenv("BLOCKCHAIN_NODE_URL", "http://localhost:8001")

@app.get("/hospital", response_class=HTMLResponse)
async def hospital_dashboard(request: Request):
    return templates.TemplateResponse("hospital.html", {"request": request, "backend_url": BACKEND_URL, "blockchain_url": BLOCKCHAIN_URL})

@app.get("/explorer", response_class=HTMLResponse)
async def explorer_dashboard(request: Request):
    return templates.TemplateResponse("explorer.html", {"request": request, "blockchain_url": BLOCKCHAIN_URL})
