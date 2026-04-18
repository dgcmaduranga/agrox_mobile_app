import os
os.environ["CUDA_VISIBLE_DEVICES"] = "-1"

# =========================
# IMPORTS
# =========================
import numpy as np
from PIL import Image

import tensorflow as tf
from keras.models import load_model
from tensorflow.keras.applications.efficientnet import preprocess_input

import base64
from openai import OpenAI
from dotenv import load_dotenv

# =========================
# 🔥 TENSORFLOW SAFE MODE
# =========================
tf.config.set_visible_devices([], 'GPU')
tf.config.threading.set_intra_op_parallelism_threads(1)
tf.config.threading.set_inter_op_parallelism_threads(1)

# =========================
# LOAD ENV
# =========================
load_dotenv()
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# =========================
# LOAD MODELS
# =========================
coconut_model = load_model("models/coconut_model.h5", compile=False, safe_mode=False)
rice_model = load_model("models/rice_model.h5", compile=False, safe_mode=False)
tea_model = load_model("models/tea_model.h5", compile=False, safe_mode=False)

print("✅ Models loaded (SAFE MODE)")

# =========================
# CLASS LABELS
# =========================
coconut_classes = [
    "CCI_Caterpillars",
    "CCI_Leaflets",
    "Healthy_Leaves",
    "WCLWD_DryingofLeaflets",
    "WCLWD_Flaccidity",
    "WCLWD_Yellowing"
]

rice_classes = [
    "Bacterial_Leaf_Blight",
    "Brown_Spot",
    "Healthy_Rice_Leaf",
    "Leaf_Blast",
    "Leaf_Scald",
    "Rice_Tungro"
]

tea_classes = [
    "algal_spot",
    "brown_blight",
    "gray_blight",
    "healthy",
    "helopeltis",
    "red_spot"
]

# =========================
# PREPROCESS
# =========================
def preprocess(image: Image.Image, crop: str):
    image = image.resize((300, 300))
    img_array = np.array(image)

    if crop == "rice":
        img_array = preprocess_input(img_array)
    else:
        img_array = img_array / 255.0

    img_array = np.expand_dims(img_array, axis=0).astype(np.float32)
    return img_array


# =========================
# 🤖 GPT LEAF CHECK (STRICT)
# =========================
def gpt_leaf_check(image: Image.Image):

    try:
        import io
        buf = io.BytesIO()
        image.save(buf, format="JPEG")
        img_base64 = base64.b64encode(buf.getvalue()).decode()

        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "Is this a plant leaf? Answer yes or no."},
                        {
                            "type": "image_url",
                            "image_url": {"url": f"data:image/jpeg;base64,{img_base64}"}
                        }
                    ]
                }
            ],
            max_tokens=3
        )

        answer = response.choices[0].message.content.lower().strip()
        answer = answer.replace(".", "").replace(",", "").strip()

        print("GPT leaf RAW:", repr(answer))

        return "yes" in answer

    except Exception as e:
        print("GPT ERROR:", e)
        return True


# =========================
# 🤖 GPT CROP CHECK (SOFT ONLY)
# =========================
def gpt_crop_check(image: Image.Image):

    try:
        import io
        buf = io.BytesIO()
        image.save(buf, format="JPEG")
        img_base64 = base64.b64encode(buf.getvalue()).decode()

        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "rice, tea, coconut or unknown? one word only"},
                        {
                            "type": "image_url",
                            "image_url": {"url": f"data:image/jpeg;base64,{img_base64}"}
                        }
                    ]
                }
            ],
            max_tokens=3
        )

        answer = response.choices[0].message.content.lower().strip()
        answer = answer.replace(".", "").replace(",", "").strip()

        print("GPT crop RAW:", repr(answer))

        return answer

    except Exception as e:
        print("GPT crop ERROR:", e)
        return "unknown"


# =========================
# 🔥 ADVANCED VALIDATION
# =========================
def advanced_validation(preds):

    preds = np.array(preds)

    best = np.max(preds)
    sorted_preds = np.sort(preds)
    second = sorted_preds[-2]
    gap = best - second

    entropy = -np.sum(preds * np.log(preds + 1e-10))

    print("Confidence:", best)
    print("Gap:", gap)
    print("Entropy:", entropy)

    if best < 0.65:
        return False

    if gap < 0.15:
        return False

    if entropy > 1.5:
        return False

    return True


# =========================
# 🚀 FINAL PREDICT (🔥 FIXED)
# =========================
def predict(image: Image.Image, crop: str):

    crop = crop.lower()

    # =========================
    # GPT CHECK
    # =========================
    gpt_leaf = gpt_leaf_check(image)
    gpt_crop = gpt_crop_check(image)

    print("GPT leaf result:", gpt_leaf)
    print("GPT crop result:", gpt_crop)

    # 🚨 HARD RULE: MUST BE LEAF
    if not gpt_leaf:
        print("❌ Rejected: Not a leaf (GPT)")
        return "unknown", 0.0

    # ⚠️ SOFT RULE: crop mismatch (NO REJECT)
    if crop not in gpt_crop:
        print("⚠️ Warning: GPT crop mismatch")

    # =========================
    # PREPROCESS
    # =========================
    img = preprocess(image, crop)

    # =========================
    # MODEL SELECT
    # =========================
    if crop == "coconut":
        model = coconut_model
        classes = coconut_classes
    elif crop == "rice":
        model = rice_model
        classes = rice_classes
    elif crop == "tea":
        model = tea_model
        classes = tea_classes
    else:
        return "unknown", 0.0

    # =========================
    # PREDICT
    # =========================
    preds = model.predict(img, verbose=0)[0]

    print("RAW:", preds)

    predicted_index = int(np.argmax(preds))
    confidence = float(preds[predicted_index])
    predicted_label = classes[predicted_index]

    # =========================
    # VALIDATION
    # =========================
    if not advanced_validation(preds):
        print("❌ Rejected by model validation")
        return "unknown", confidence

    print("----- FINAL RESULT -----")
    print("Crop:", crop)
    print("Prediction:", predicted_label)
    print("Confidence:", confidence)
    print("------------------------")

    return predicted_label, confidence