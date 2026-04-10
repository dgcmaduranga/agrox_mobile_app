from openai import OpenAI
from dotenv import load_dotenv
import os
import json

load_dotenv()

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# =========================
# LOAD DETECTION DATA
# =========================
def load_detection():
    try:
        with open("data/detection.json") as f:
            return json.load(f)
    except:
        return []

detection_data = load_detection()

# =========================
# STRICT CROPS
# =========================
STRICT_CROPS = [
    "tea", "rice", "paddy", "coconut",
    "තේ", "වී", "පොල්",
    "தேயிலை", "நெல்", "தேங்காய்"
]

def is_strict_crop(question):
    q = question.lower()
    return any(crop in q for crop in STRICT_CROPS)

# =========================
# FIND FROM JSON
# =========================
def find_from_json(question):
    q = question.lower()

    for d in detection_data:
        name = d.get("name", "").lower()
        crop = d.get("crop", "").lower()

        if name in q or crop in q:
            return d

    return None

# =========================
# LANGUAGE DETECTION
# =========================
def detect_language(text):
    for char in text:
        if '\u0D80' <= char <= '\u0DFF':
            return "sinhala"
        if '\u0B80' <= char <= '\u0BFF':
            return "tamil"
    return "english"

# =========================
# RESPONSES
# =========================
def greeting_response(lang):
    if lang == "sinhala":
        return "ආයුබෝවන්! 🌱 කෘෂිකර්මයට අදාළ ප්‍රශ්න මගෙන් අහන්න පුළුවන්."
    elif lang == "tamil":
        return "வணக்கம்! 🌱 வேளாண்மை தொடர்பான கேள்விகளை என்னிடம் கேளுங்கள்."
    else:
        return "Hello! 👋 Ask me any agriculture-related question."

def reject_response(lang):
    if lang == "sinhala":
        return "සමාවෙන්න, මට කෘෂිකර්මයට අදාළ ප්‍රශ්න වලට පමණක් පිළිතුරු දිය හැක."
    elif lang == "tamil":
        return "மன்னிக்கவும், நான் வேளாண்மை தொடர்பான கேள்விகளுக்கே பதில் அளிக்க முடியும்."
    else:
        return "Sorry, I can only answer agriculture-related questions."

# =========================
# GREETING CHECK
# =========================
GREETINGS = ["hi","hello","hey","hii","ආයුබෝවන්","හයි","வணக்கம்","ஹாய்"]

def is_greeting(q):
    q = q.lower()
    return any(word in q for word in GREETINGS)

# =========================
# MEMORY
# =========================
chat_history = []

# =========================
# MAIN FUNCTION
# =========================
def ask_chatbot(question):
    try:
        lang = detect_language(question)

        # =========================
        # FORCE LANGUAGE PROMPT 🔥
        # =========================
        if lang == "english":
            lang_instruction = "Answer ONLY in English."
        elif lang == "sinhala":
            lang_instruction = "සිංහලෙන් පමණක් පිළිතුරු දෙන්න."
        else:
            lang_instruction = "தமிழில் மட்டும் பதில் அளிக்கவும்."

        # =========================
        # GREETING
        # =========================
        if is_greeting(question):
            return greeting_response(lang)

        # =========================
        # STRICT CROPS
        # =========================
        if is_strict_crop(question):

            data = find_from_json(question)

            if data:
                if lang == "sinhala":
                    return f"""
🌾 {data.get("name")}

📝 විස්තරය:
{data.get("description", "")}

⚠️ ප්‍රතිකාර:
- High Risk: {", ".join(data.get("highRiskTreatments", []))}
- Low Risk: {", ".join(data.get("lowRiskTreatments", []))}
"""
                elif lang == "tamil":
                    return f"""
🌾 {data.get("name")}

📝 விளக்கம்:
{data.get("description", "")}

⚠️ சிகிச்சை:
- High Risk: {", ".join(data.get("highRiskTreatments", []))}
- Low Risk: {", ".join(data.get("lowRiskTreatments", []))}
"""
                else:
                    return f"""
🌾 {data.get("name")}

📝 Description:
{data.get("description", "")}

⚠️ Treatments:
- High Risk: {", ".join(data.get("highRiskTreatments", []))}
- Low Risk: {", ".join(data.get("lowRiskTreatments", []))}
"""

            else:
                if lang == "sinhala":
                    return "නිවැරදි රෝග හඳුනාගැනීම සඳහා scan feature භාවිතා කරන්න 📷"
                elif lang == "tamil":
                    return "துல்லியமான நோய் கண்டறிதலுக்காக scan வசதியை பயன்படுத்தவும் 📷"
                else:
                    return "Please use the scan feature for accurate detection 📷"

        # =========================
        # ADD USER MESSAGE
        # =========================
        chat_history.append({
            "role": "user",
            "content": question
        })

        # =========================
        # GPT CALL (FIXED 🔥)
        # =========================
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": f"""
You are AgroX AI, an agriculture expert in Sri Lanka.

{lang_instruction}

RULES:
- ONLY answer agriculture-related questions.
- If not agriculture → politely refuse.
- Use Sri Lankan context.
- Keep answers simple and practical.
- Include cause, solution, prevention when possible.
"""
                }
            ] + chat_history,
            temperature=0.6
        )

        reply = response.choices[0].message.content

        # =========================
        # SAVE RESPONSE
        # =========================
        chat_history.append({
            "role": "assistant",
            "content": reply
        })

        return reply

    except Exception as e:
        return f"Error: {str(e)}"