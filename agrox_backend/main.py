from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import json

from services.weather_service import get_weather
from services.ai_service import predict

app = FastAPI()

# =========================
# CORS
# =========================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =========================
# HOME
# =========================
@app.get("/")
def home():
    return {"message": "Backend running (H5 models)"}

# =========================
# WEATHER (UNCHANGED ✅)
# =========================
@app.get("/weather")
def weather(lat: float, lon: float):
    return get_weather(lat, lon)

# =========================
# DISEASES (UNCHANGED ✅)
# =========================
@app.get("/diseases")
def get_diseases():
    with open("data/diseases.json") as f:
        return json.load(f)

# =========================
# RISK (UNCHANGED ✅)
# =========================
@app.get("/risk")
def get_risk():
    with open("data/diseases.json") as f:
        return json.load(f)

# =========================
# LOAD DETECTION JSON
# =========================
def load_detection():
    with open("data/detection.json") as f:
        return json.load(f)

# =========================
# NORMALIZE
# =========================
def normalize(text):
    return text.lower().replace(" ", "_")

# =========================
# DETECT (FINAL 🔥🔥🔥)
# =========================
@app.post("/detect")
async def detect(
    file: UploadFile = File(...),
    crop: str = Form(...)
):
    try:
        # =========================
        # IMAGE LOAD
        # =========================
        image = Image.open(file.file).convert("RGB")

        # =========================
        # AI PREDICTION
        # =========================
        disease, confidence = predict(image, crop)

        print("PREDICTED:", disease, "| CONF:", confidence)

        # =========================
        # ❌ BLOCK UNKNOWN / LOW CONFIDENCE
        # =========================
        if disease == "unknown" or confidence < 0.75:
            return {
                "status": "error",
                "message": "Invalid image for selected crop"
            }

        # =========================
        # LOAD DATA
        # =========================
        detection_data = load_detection()

        disease_key = normalize(disease)
        crop_key = normalize(crop)

        # =========================
        # FIND MATCH
        # =========================
        data = None
        for d in detection_data:
            if normalize(d["id"]) == disease_key and normalize(d["crop"]) == crop_key:
                data = d
                break

        # =========================
        # ❌ NO MATCH
        # =========================
        if not data:
            return {
                "status": "error",
                "message": "Invalid image for selected crop"
            }

        # =========================
        # RISK LOGIC
        # =========================
        if confidence >= 0.7:
            risk = "High"
            treatment = data.get("highRiskTreatments", [])
        else:
            risk = "Low"
            treatment = data.get("lowRiskTreatments", [])

        # =========================
        # SUCCESS RESPONSE
        # =========================
        return {
            "status": "success",
            "disease": data["name"],
            "accuracy": round(confidence * 100, 2),
            "risk": risk,
            "description": data.get("description", ""),
            "treatment": treatment
        }

    except Exception as e:
        print("ERROR:", str(e))
        return {
            "status": "error",
            "message": str(e)
        }