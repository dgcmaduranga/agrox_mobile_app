from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import json

# ✅ IMPORT services
from services.weather_service import get_weather
from services.ai_service import predict   # 🔥 NEW

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

# ✅ WEATHER ROUTE
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
    with open("data/diseases.json") as f:
        return json.load(f)

# 🔥 ==============================
# 🔥 AI DETECTION ROUTE (NEW)
# 🔥 ==============================

@app.post("/detect")
async def detect(
    file: UploadFile = File(...),
    crop: str = Form(...)
):
    try:
        # ✅ Open image
        image = Image.open(file.file)

        # ✅ Run AI model
        disease, confidence = predict(image, crop)

        return {
            "status": "success",
            "disease": disease,
            "confidence": confidence
        }

    except Exception as e:
        return {
            "status": "error",
            "message": str(e)
        }