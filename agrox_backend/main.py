from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import requests

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