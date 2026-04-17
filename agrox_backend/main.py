from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import json
import traceback

from services.weather_service import get_weather
from services.ai_service import predict

from services.chatbot_service import ask_chatbot
from pydantic import BaseModel

from services.translate_service import translate_text

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
# WEATHER
# =========================
@app.get("/weather")
def weather(lat: float, lon: float):
    try:
        return get_weather(lat, lon)
    except Exception as e:
        print("WEATHER ERROR:", e)
        return {"status": "error", "message": "Weather fetch failed"}

# =========================
# DISEASES
# =========================
@app.get("/diseases")
def get_diseases():
    try:
        with open("data/diseases.json") as f:
            return json.load(f)
    except Exception as e:
        print("DISEASE ERROR:", e)
        return []

# =========================
# RISK
# =========================
@app.get("/risk")
def get_risk():
    try:
        with open("data/diseases.json") as f:
            return json.load(f)
    except Exception as e:
        print("RISK ERROR:", e)
        return []

# =========================
# LOAD DETECTION JSON
# =========================
def load_detection():
    try:
        with open("data/detection.json") as f:
            return json.load(f)
    except Exception as e:
        print("DETECTION LOAD ERROR:", e)
        return []

# =========================
# NORMALIZE
# =========================
def normalize(text):
    return text.lower().replace(" ", "_")

# =========================
# TRANSLATE
# =========================
@app.post("/translate")
def translate_api(
    text: str = Form(...),
    lang: str = Form("en")
):
    try:
        return {
            "translated": translate_text(text, lang)
        }
    except Exception as e:
        print("TRANSLATE ERROR:", e)
        return {"translated": text}

# =========================
# 🔥 DETECT (SUPER STABLE)
# =========================
@app.post("/detect")
async def detect(
    file: UploadFile = File(...),
    crop: str = Form(...),
    lang: str = Form("en")
):
    try:
        print("📥 Request received:", crop)

        # read image safely
        image = Image.open(file.file).convert("RGB")

        # 🔥 prediction (main part)
        disease, confidence = predict(image, crop)

        print("PREDICTED:", disease, "| CONF:", confidence)

        # ❌ invalid
        if disease == "unknown":
            return {
                "status": "error",
                "message": translate_text("Invalid image for selected crop", lang)
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
                "message": translate_text("Invalid image for selected crop", lang)
            }

        # 🔥 risk logic
        if confidence >= 0.7:
            risk = "High"
            treatment = data.get("highRiskTreatments", [])
        else:
            risk = "Low"
            treatment = data.get("lowRiskTreatments", [])

        return {
            "status": "success",
            "disease": translate_text(data["name"], lang),
            "accuracy": round(confidence * 100, 2),
            "risk": translate_text(risk, lang),
            "description": translate_text(data.get("description", ""), lang),
            "treatment": [translate_text(t, lang) for t in treatment]
        }

    except Exception as e:
        print("🔥 DETECT ERROR:")
        traceback.print_exc()

        return {
            "status": "error",
            "message": "Detection failed (server error)"
        }

# =========================
# CHATBOT
# =========================
class ChatRequest(BaseModel):
    question: str
    lang: str = "en"

@app.post("/chat")
def chat(req: ChatRequest):
    try:
        answer = ask_chatbot(req.question)
        return {
            "response": translate_text(answer, req.lang)
        }
    except Exception as e:
        print("CHAT ERROR:", e)
        return {
            "response": "Chatbot temporarily unavailable"
        }