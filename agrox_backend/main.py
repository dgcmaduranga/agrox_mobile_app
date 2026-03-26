from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import requests
import json

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

# ✅ WEATHER ROUTE (MICROSERVICE CALL)
@app.get("/weather")
def weather(lat: float, lon: float):
    res = requests.get(f"http://127.0.0.1:8001/weather?lat={lat}&lon={lon}")
    return res.json()

# ✅ DISEASES ROUTE (NEW 🔥)
@app.get("/diseases")
def get_diseases():
    with open("data/diseases.json") as f:
        return json.load(f)


@app.get("/risk")
def get_risk():
    """Return the full diseases JSON as the risk payload.

    This simple endpoint mirrors the local `data/diseases.json` file
    so the Flutter client can fetch disease/risk data from the backend.
    """
    with open("data/diseases.json") as f:
        return json.load(f)