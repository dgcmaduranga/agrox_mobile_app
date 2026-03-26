from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import json

# ✅ IMPORT weather service
from services.weather_service import get_weather

app = FastAPI()

# ✅ CORS FIX
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ TEST ROUTE
@app.get("/")
def home():
    return {"message": "Backend running"}

# ✅ WEATHER ROUTE (DIRECT SERVICE CALL ✅)
@app.get("/weather")
def weather(lat: float, lon: float):
    return get_weather(lat, lon)

# ✅ DISEASES ROUTE
@app.get("/diseases")
def get_diseases():
    with open("data/diseases.json") as f:
        return json.load(f)

# ✅ RISK ROUTE
@app.get("/risk")
def get_risk():
    """
    Return diseases JSON as risk payload
    """
    with open("data/diseases.json") as f:
        return json.load(f)