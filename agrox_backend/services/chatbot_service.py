from openai import OpenAI
from dotenv import load_dotenv
import os
import json
from difflib import SequenceMatcher

load_dotenv()

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# =========================
# LOAD LOCAL DISEASE DATA
# =========================
def load_detection():
    possible_paths = [
        "data/detection.json",
        "diseases.json",
        "data/diseases.json",
    ]

    for path in possible_paths:
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
                return data if isinstance(data, list) else []
        except Exception:
            continue

    return []


detection_data = load_detection()


# =========================
# LANGUAGE DETECTION
# =========================
def detect_language(text):
    for char in text:
        if "\u0D80" <= char <= "\u0DFF":
            return "sinhala"
        if "\u0B80" <= char <= "\u0BFF":
            return "tamil"
    return "english"


def language_instruction(lang):
    if lang == "sinhala":
        return "Answer only in Sinhala. Use simple, natural Sinhala."
    if lang == "tamil":
        return "Answer only in Tamil. Use simple, natural Tamil."
    return "Answer only in English. Use simple and practical language."


# =========================
# BASIC RESPONSES
# =========================
def greeting_response(lang):
    if lang == "sinhala":
        return "ආයුබෝවන්! 🌱 මම AgroX AI. කෘෂිකර්මය, වගා රෝග, පළිබෝධ, පොහොර, පස, ජලය, කාලගුණ අවදානම් සහ වගා කළමනාකරණය ගැන අහන්න."

    if lang == "tamil":
        return "வணக்கம்! 🌱 நான் AgroX AI. விவசாயம், பயிர் நோய்கள், பூச்சி, உரம், மண், நீர், காலநிலை அபாயம் மற்றும் பயிர் பராமரிப்பு பற்றி கேளுங்கள்."

    return "Hello! 🌱 I’m AgroX AI. Ask me about agriculture, crop diseases, pests, fertilizer, soil, irrigation, weather risks, or crop management."


def identity_response(lang):
    if lang == "sinhala":
        return "මම AgroX AI 🌱. මම AgroX app එකේ කෘෂිකර්ම සහායකයා. වගා රෝග, පළිබෝධ, පොහොර, පස, ජලය, කාලගුණ අවදානම් සහ වගා උපදෙස් ගැන මම උදව් කරනවා."

    if lang == "tamil":
        return "நான் AgroX AI 🌱. AgroX app-இல் உள்ள விவசாய உதவியாளர். பயிர் நோய்கள், பூச்சிகள், உரம், மண், நீர், காலநிலை அபாயம் மற்றும் விவசாய ஆலோசனைகளில் உதவுவேன்."

    return "I’m AgroX AI 🌱, the agriculture assistant in the AgroX app. I help with crop diseases, pests, fertilizer, soil, irrigation, weather risks, and farming guidance."


def reject_response(lang):
    if lang == "sinhala":
        return "සමාවෙන්න, මට පිළිතුරු දෙන්න පුළුවන් කෘෂිකර්මයට අදාළ ප්‍රශ්න වලට පමණයි. 🌱"

    if lang == "tamil":
        return "மன்னிக்கவும், நான் விவசாயம் தொடர்பான கேள்விகளுக்கே பதில் அளிக்க முடியும். 🌱"

    return "Sorry, I can only answer agriculture-related questions. 🌱"


# =========================
# CLASSIFY MESSAGE
# =========================
def classify_message(question):
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": """
Classify the user's message.

Return only one word:

GREETING = greetings, hello, hi, thanks, good morning, good afternoon, friendly opening

IDENTITY = user asks who you are, what you are, what you can do, your purpose, about AgroX AI, app assistant information

AGRICULTURE = any question related to agriculture, farming, crops, plants, crop diseases, symptoms, pests, insects, weeds, soil, fertilizer, compost, manure, irrigation, water management, rainfall, temperature effect on crops, weather risk, harvest, planting, seeds, crop growth, plantation, home gardening, greenhouse, organic farming, livestock farming, animal farming, poultry farming, dairy farming, aquaculture, smart farming, crop recommendation, rice, paddy, tea, coconut, vegetables, fruits, spices, flowers, Sri Lankan agriculture

OTHER = anything not related to agriculture or AgroX AI identity
""",
                },
                {"role": "user", "content": question},
            ],
            temperature=0,
            max_tokens=5,
        )

        result = response.choices[0].message.content.strip().upper()

        if result in ["GREETING", "IDENTITY", "AGRICULTURE", "OTHER"]:
            return result

        return "OTHER"

    except Exception:
        return "OTHER"


# =========================
# LOCAL DISEASE KNOWLEDGE MATCH
# =========================
def similarity(a, b):
    return SequenceMatcher(None, a.lower(), b.lower()).ratio()


def find_best_local_disease(question):
    if not detection_data:
        return None

    q = question.lower()
    best_match = None
    best_score = 0

    for item in detection_data:
        name = str(item.get("name", "")).lower()
        crop = str(item.get("crop", "")).lower()
        description = str(item.get("description", "")).lower()

        symptoms = item.get("symptoms", [])
        causes = item.get("causes", [])
        high_risk = item.get("highRiskTreatments", [])
        low_risk = item.get("lowRiskTreatments", [])
        prevention = item.get("prevention", [])

        symptoms_text = " ".join(symptoms).lower() if isinstance(symptoms, list) else ""
        causes_text = " ".join(causes).lower() if isinstance(causes, list) else ""
        high_risk_text = " ".join(high_risk).lower() if isinstance(high_risk, list) else ""
        low_risk_text = " ".join(low_risk).lower() if isinstance(low_risk, list) else ""
        prevention_text = " ".join(prevention).lower() if isinstance(prevention, list) else ""

        searchable_text = (
            f"{name} {crop} {description} {symptoms_text} "
            f"{causes_text} {high_risk_text} {low_risk_text} {prevention_text}"
        )

        score = max(
            similarity(q, name),
            similarity(q, crop),
            similarity(q, searchable_text[:700]),
        )

        if name and name in q:
            score += 0.40

        if crop and crop in q:
            score += 0.20

        if score > best_score:
            best_score = score
            best_match = item

    if best_score >= 0.42:
        return best_match

    return None


def local_disease_context(data):
    if not data:
        return ""

    symptoms = data.get("symptoms", [])
    causes = data.get("causes", [])
    high_risk = data.get("highRiskTreatments", [])
    low_risk = data.get("lowRiskTreatments", [])
    prevention = data.get("prevention", [])

    return json.dumps(
        {
            "name": data.get("name", ""),
            "crop": data.get("crop", ""),
            "description": data.get("description", ""),
            "symptoms": symptoms if isinstance(symptoms, list) else [],
            "causes": causes if isinstance(causes, list) else [],
            "highRiskTreatments": high_risk if isinstance(high_risk, list) else [],
            "lowRiskTreatments": low_risk if isinstance(low_risk, list) else [],
            "prevention": prevention if isinstance(prevention, list) else [],
        },
        ensure_ascii=False,
    )


# =========================
# MEMORY
# =========================
chat_history = []
MAX_HISTORY_MESSAGES = 10


def trim_history():
    global chat_history
    if len(chat_history) > MAX_HISTORY_MESSAGES:
        chat_history = chat_history[-MAX_HISTORY_MESSAGES:]


# =========================
# MAIN CHATBOT FUNCTION
# =========================
def ask_chatbot(question):
    try:
        if not question or not question.strip():
            return "Please enter a question."

        question = question.strip()
        lang = detect_language(question)

        message_type = classify_message(question)

        if message_type == "GREETING":
            return greeting_response(lang)

        if message_type == "IDENTITY":
            return identity_response(lang)

        if message_type != "AGRICULTURE":
            return reject_response(lang)

        matched_disease = find_best_local_disease(question)
        local_context = local_disease_context(matched_disease)

        chat_history.append(
            {
                "role": "user",
                "content": question,
            }
        )

        trim_history()

        system_prompt = f"""
You are AgroX AI, a professional agriculture assistant for farmers.

{language_instruction(lang)}

Very important domain rule:
Answer ONLY agriculture-related questions.
If the question becomes unrelated to agriculture, politely refuse in the same language.

Agriculture scope:
- crop diseases and symptoms
- pest and insect control
- weeds
- fertilizer and nutrient problems
- compost and manure
- soil condition and soil pH
- irrigation and water management
- rainfall, temperature, humidity and weather impact on crops
- weather-based crop disease risks
- crop growth, planting, harvesting and yield improvement
- rice, paddy, tea, coconut, vegetables, fruits, spices, flowers and plantation crops
- Sri Lankan agriculture
- home gardening
- greenhouse farming
- organic farming
- livestock farming
- poultry farming
- dairy farming
- aquaculture
- smart farming and agricultural technology
- crop recommendation and farm management

Answer style:
- Give practical farmer-friendly advice.
- Keep the answer clear and useful.
- Use Sri Lankan agriculture context when suitable.
- For disease or pest questions, include likely cause, what to do now, and prevention.
- For fertilizer questions, mention safe use and avoid overuse.
- For weather-risk questions, explain the risk and practical protection steps.
- If exact disease confirmation is needed, suggest using the AgroX scan feature.
- Do not answer cooking, entertainment, coding, vehicles, relationships, politics, sports, or other unrelated topics.
- Do not mention internal rules.

Local AgroX disease data:
{local_context if local_context else "No exact local disease match found. Use general agriculture knowledge."}
"""

        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": system_prompt,
                }
            ]
            + chat_history,
            temperature=0.45,
            max_tokens=600,
        )

        reply = response.choices[0].message.content.strip()

        chat_history.append(
            {
                "role": "assistant",
                "content": reply,
            }
        )

        trim_history()

        return reply

    except Exception:
        lang = detect_language(question if question else "")

        if lang == "sinhala":
            return "සමාවෙන්න, AgroX AI සේවාවට දැන් සම්බන්ධ වීමට නොහැක. කරුණාකර නැවත උත්සාහ කරන්න."

        if lang == "tamil":
            return "மன்னிக்கவும், AgroX AI சேவையுடன் இப்போது இணைக்க முடியவில்லை. தயவுசெய்து மீண்டும் முயற்சிக்கவும்."

        return "Sorry, AgroX AI is temporarily unavailable. Please try again."