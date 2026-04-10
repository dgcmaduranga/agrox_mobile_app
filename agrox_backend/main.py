from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import json

from services.weather_service import get_weather
from services.ai_service import predict

# 🆕 CHATBOT IMPORT
from services.chatbot_service import ask_chatbot
from pydantic import BaseModel

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
        image = Image.open(file.file).convert("RGB")

        disease, confidence = predict(image, crop)

        print("PREDICTED:", disease, "| CONF:", confidence)

        # ❌ REMOVE HARD 0.75 CHECK
        if disease == "unknown":
            return {
                "status": "error",
                "message": "Invalid image for selected crop"
            }

        detection_data = load_detection()

        disease_key = normalize(disease)
        crop_key = normalize(crop)

        data = None
        for d in detection_data:
            if (
                normalize(d.get("id", "")) == disease_key
                or normalize(d.get("name", "")) == disease_key
            ) and normalize(d.get("crop", "")) == crop_key:
                data = d
                break

        if not data:
            return {
                "status": "error",
                "message": "Invalid image for selected crop"
            }

        if confidence >= 0.7:
            risk = "High"
            treatment = data.get("highRiskTreatments", [])
        else:
            risk = "Low"
            treatment = data.get("lowRiskTreatments", [])

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

# =========================
# 🆕 CHATBOT (UNCHANGED)
# =========================
class ChatRequest(BaseModel):
    question: str

@app.post("/chat")
def chat(req: ChatRequest):
    answer = ask_chatbot(req.question)
    return {"response": answer}