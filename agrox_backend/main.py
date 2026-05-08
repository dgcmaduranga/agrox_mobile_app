from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import json
import traceback

from services.weather_service import get_weather
from services.ai_service import predict
from services.chatbot_service import ask_chatbot
from services.translate_service import translate_text
from services.notification_service import send_risk_alert_notification

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
    return {"message": "Backend running (AgroX crop detection models)"}


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
        with open("data/diseases.json", "r", encoding="utf-8") as f:
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
        with open("data/diseases.json", "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print("RISK ERROR:", e)
        return []


# =========================
# LOAD DETECTION JSON
# =========================
def load_detection():
    try:
        with open("data/detection.json", "r", encoding="utf-8") as f:
            data = json.load(f)

        if isinstance(data, list):
            return data

        print("DETECTION JSON ERROR: detection.json must be a list")
        return []

    except Exception as e:
        print("DETECTION LOAD ERROR:", e)
        return []


# =========================
# NORMALIZE
# =========================
def normalize(text):
    return str(text).lower().strip().replace(" ", "_").replace("-", "_")


# =========================
# SAFE TRANSLATE
# =========================
def safe_translate(text, lang: str):
    try:
        if lang == "en":
            return text
        return translate_text(str(text), lang)
    except Exception:
        return str(text)


def safe_translate_list(items, lang: str):
    if not isinstance(items, list):
        return []

    translated = []
    for item in items:
        translated.append(safe_translate(str(item), lang))

    return translated


# =========================
# TRANSLATE
# =========================
@app.post("/translate")
def translate_api(
    text: str = Form(...),
    lang: str = Form("en"),
):
    try:
        return {
            "translated": safe_translate(text, lang)
        }
    except Exception as e:
        print("TRANSLATE ERROR:", e)
        return {"translated": text}


# =========================
# FIND DETECTION DATA
# =========================
def find_detection_data(crop: str, disease: str):
    detection_data = load_detection()

    crop_key = normalize(crop)
    disease_key = normalize(disease)

    for item in detection_data:
        if not isinstance(item, dict):
            continue

        item_crop = normalize(item.get("crop", ""))
        item_id = normalize(item.get("id", ""))
        item_name = normalize(item.get("name", ""))

        if item_crop == crop_key and (
            item_id == disease_key or item_name == disease_key
        ):
            return item

    return None


# =========================
# RISK LOGIC
# =========================
def calculate_risk(confidence_percent: float, disease: str):
    disease_key = normalize(disease)

    if disease_key in ["healthy", "healthy_leaves", "healthy_rice_leaf"]:
        return "Low"

    if confidence_percent >= 80:
        return "High"

    if confidence_percent >= 60:
        return "Medium"

    return "Low"


# =========================
# GET TREATMENT
# =========================
def get_treatment(data: dict, risk: str):
    if not data:
        return ["No treatment recommendations available"]

    risk_key = normalize(risk)

    if risk_key == "high":
        treatment = data.get("highRiskTreatments", [])
    else:
        treatment = data.get("lowRiskTreatments", [])

    if isinstance(treatment, list) and len(treatment) > 0:
        return treatment

    fallback = (
        data.get("treatment")
        or data.get("treatments")
        or data.get("recommendations")
        or []
    )

    if isinstance(fallback, list) and len(fallback) > 0:
        return fallback

    return ["No treatment recommendations available"]


# =========================
# DETECT
# Supports both Flutter fields:
# image OR file
# =========================
@app.post("/detect")
async def detect(
    image: UploadFile | None = File(None),
    file: UploadFile | None = File(None),
    crop: str = Form(...),
    lang: str = Form("en"),
):
    try:
        print("\n====================================")
        print("📥 DETECT REQUEST RECEIVED")
        print("Selected crop:", crop)
        print("Language:", lang)
        print("====================================")

        crop = normalize(crop)

        if crop not in ["tea", "coconut", "rice"]:
            return {
                "status": "failed",
                "prediction": "unknown",
                "message": safe_translate("Invalid crop selected", lang),
            }

        upload_file = image if image is not None else file

        if upload_file is None:
            return {
                "status": "failed",
                "prediction": "unknown",
                "message": safe_translate("No image uploaded", lang),
            }

        # =========================
        # READ IMAGE SAFELY
        # =========================
        try:
            pil_image = Image.open(upload_file.file).convert("RGB")
        except Exception as e:
            print("IMAGE READ ERROR:", e)
            return {
                "status": "failed",
                "prediction": "unknown",
                "message": safe_translate("Please upload a clear leaf image", lang),
            }

        # =========================
        # AI SERVICE PREDICT
        # ai_service.py returns dict
        # =========================
        prediction_result = predict(pil_image, crop)

        print("AI SERVICE RESULT:", prediction_result)

        # =========================
        # IF AI SERVICE RETURNS FAILED
        # =========================
        if not isinstance(prediction_result, dict):
            return {
                "status": "failed",
                "prediction": "unknown",
                "message": safe_translate("Invalid prediction response", lang),
            }

        if prediction_result.get("status") != "success":
            return {
                "status": "failed",
                "prediction": "unknown",
                "message": safe_translate(
                    prediction_result.get(
                        "message",
                        "Selected crop does not match the image",
                    ),
                    lang,
                ),
            }

        # =========================
        # GET PREDICTION DATA
        # =========================
        disease_raw = (
            prediction_result.get("prediction")
            or prediction_result.get("disease")
            or "unknown"
        )

        accuracy = prediction_result.get("accuracy", 0)
        confidence = prediction_result.get("confidence", 0)

        try:
            accuracy_float = float(accuracy)
        except Exception:
            accuracy_float = 0.0

        detection_item = find_detection_data(crop, disease_raw)

        if detection_item:
            disease_name = detection_item.get(
                "name",
                prediction_result.get("disease", disease_raw),
            )
            description = detection_item.get(
                "description",
                prediction_result.get("description", ""),
            )

            risk = prediction_result.get("risk") or calculate_risk(
                accuracy_float,
                disease_raw,
            )

            treatment = get_treatment(detection_item, risk)

        else:
            disease_name = prediction_result.get("disease", disease_raw)
            description = prediction_result.get(
                "description",
                "No detailed data found for this disease",
            )
            risk = prediction_result.get("risk") or calculate_risk(
                accuracy_float,
                disease_raw,
            )
            treatment = prediction_result.get("treatment", [])

            if not treatment:
                treatment = ["No treatment recommendations available"]

        # =========================
        # SUCCESS RESPONSE
        # =========================
        return {
            "status": "success",
            "crop": crop,
            "disease": safe_translate(str(disease_name), lang),
            "prediction": disease_raw,
            "accuracy": round(accuracy_float, 2),
            "confidence": confidence,
            "risk": safe_translate(str(risk), lang),
            "description": safe_translate(str(description), lang),
            "treatment": safe_translate_list(treatment, lang),
        }

    except Exception as e:
        print("🔥 DETECT ERROR:")
        traceback.print_exc()

        return {
            "status": "failed",
            "prediction": "unknown",
            "message": "Detection failed. Please check backend logs.",
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
            "response": safe_translate(answer, req.lang)
        }
    except Exception as e:
        print("CHAT ERROR:", e)
        return {
            "response": "Chatbot temporarily unavailable"
        }


# =========================
# NOTIFICATION MODEL
# =========================
class RiskNotificationRequest(BaseModel):
    token: str
    crop: str
    disease_name: str
    risk_level: str
    severity: str = "medium"


# =========================
# SEND RISK NOTIFICATION
# =========================
@app.post("/send-risk-notification")
def send_risk_notification(req: RiskNotificationRequest):
    try:
        result = send_risk_alert_notification(
            token=req.token,
            crop=req.crop,
            disease_name=req.disease_name,
            risk_level=req.risk_level,
            severity=req.severity,
        )

        return result

    except Exception as e:
        print("NOTIFICATION ERROR:", e)
        traceback.print_exc()

        return {
            "success": False,
            "message": "Notification failed"
        }