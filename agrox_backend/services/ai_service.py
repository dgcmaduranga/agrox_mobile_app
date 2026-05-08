import os
import json
import numpy as np
from PIL import Image, ImageOps

# ============================================================
# TENSORFLOW SAFE MODE - BEFORE TensorFlow import
# ============================================================
os.environ["CUDA_VISIBLE_DEVICES"] = "-1"
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras.applications.efficientnet import preprocess_input

try:
    tf.config.set_visible_devices([], "GPU")
except Exception:
    pass

try:
    tf.config.threading.set_intra_op_parallelism_threads(1)
    tf.config.threading.set_inter_op_parallelism_threads(1)
except Exception:
    pass


# ============================================================
# BASE PATHS
# ============================================================
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MODELS_DIR = os.path.join(BASE_DIR, "models")
DATA_DIR = os.path.join(BASE_DIR, "data")

DETECTION_JSON_PATH = os.path.join(DATA_DIR, "detection.json")

IMG_SIZE = 380

print("\n================ AI SERVICE PATH CHECK ================")
print("BASE_DIR:", BASE_DIR)
print("MODELS_DIR:", MODELS_DIR)
print("DATA_DIR:", DATA_DIR)
print("DETECTION_JSON_PATH:", DETECTION_JSON_PATH)
print("=======================================================\n")


# ============================================================
# AUTO FIND MODEL FILE
# ============================================================
def find_model_file(crop_folder, preferred_name):
    folder_path = os.path.join(MODELS_DIR, crop_folder)
    preferred_path = os.path.join(folder_path, preferred_name)

    print(f"\n🔎 Checking {crop_folder} model path:")
    print(preferred_path)
    print("Exists:", os.path.exists(preferred_path))

    if os.path.exists(preferred_path):
        return preferred_path

    if os.path.exists(folder_path):
        print(f"📁 Files inside models/{crop_folder}:")

        try:
            files = os.listdir(folder_path)

            for f in files:
                print(" -", repr(f))

            for f in files:
                if f.lower().endswith(".keras"):
                    auto_path = os.path.join(folder_path, f)
                    print(f"✅ Auto found {crop_folder} keras model:", auto_path)
                    return auto_path

            for f in files:
                if f.lower().endswith(".h5"):
                    auto_path = os.path.join(folder_path, f)
                    print(f"✅ Auto found {crop_folder} h5 model:", auto_path)
                    return auto_path

        except Exception as e:
            print(f"❌ Could not list files in {folder_path}:", e)
    else:
        print(f"❌ Folder not found: {folder_path}")

    return preferred_path


# ============================================================
# MODEL CONFIG
# ============================================================
MODEL_CONFIG = {
    "tea": {
        "model_path": find_model_file("tea", "best_tea_model.keras"),
        "label_paths": [
            os.path.join(MODELS_DIR, "tea", "tea_class_labels.json"),
            os.path.join(MODELS_DIR, "tea", "class_names.json"),
            os.path.join(MODELS_DIR, "tea", "labels.json"),
        ],
        "threshold": 0.70,
        "fallback_labels": [
            "algal_spot",
            "brown_blight",
            "gray_blight",
            "healthy",
            "helopeltis",
            "red_spot",
            "unknown",
        ],
    },
    "coconut": {
        "model_path": find_model_file("coconut", "best_coconut_model.keras"),
        "label_paths": [
            os.path.join(MODELS_DIR, "coconut", "coconut_class_labels.json"),
            os.path.join(MODELS_DIR, "coconut", "class_names.json"),
            os.path.join(MODELS_DIR, "coconut", "labels.json"),
        ],
        "threshold": 0.70,
        "fallback_labels": [
            "CCI_Caterpillars",
            "CCI_Leaflets",
            "Healthy_Leaves",
            "WCLWD_DryingofLeaflets",
            "WCLWD_Flaccidity",
            "WCLWD_Yellowing",
            "unknown",
        ],
    },
    "rice": {
        # IMPORTANT: final selected rice model
        "model_path": find_model_file("rice", "best_rice_finetuned_model.keras"),
        "label_paths": [
            os.path.join(MODELS_DIR, "rice", "rice_class_labels.json"),
            os.path.join(MODELS_DIR, "rice", "class_names.json"),
            os.path.join(MODELS_DIR, "rice", "labels.json"),
        ],
        "threshold": 0.60,
        "fallback_labels": [
            "Bacterial_Leaf_Blight",
            "Brown_Spot",
            "Healthy_Rice_Leaf",
            "Leaf_Blast",
            "Leaf_Scald",
            "Rice_Tungro",
            "unknown",
        ],
    },
}


print("\n================ MODEL CONFIG CHECK ================")
for crop_name, cfg in MODEL_CONFIG.items():
    print(f"{crop_name} model path:", cfg["model_path"])
    print(f"{crop_name} model exists:", os.path.exists(cfg["model_path"]))

    for lp in cfg["label_paths"]:
        print(f"{crop_name} label path:", lp, "| exists:", os.path.exists(lp))

print("====================================================\n")


# ============================================================
# LOAD DETECTION DATA
# ============================================================
def load_detection_data():
    try:
        if not os.path.exists(DETECTION_JSON_PATH):
            print("❌ detection.json not found:", DETECTION_JSON_PATH)
            return []

        with open(DETECTION_JSON_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)

        if isinstance(data, list):
            print("✅ detection.json loaded:", len(data), "records")
            return data

        print("⚠️ detection.json is not a list")
        return []

    except Exception as e:
        print("❌ detection.json load error:", e)
        return []


detection_data = load_detection_data()


# ============================================================
# TEXT NORMALIZATION
# ============================================================
def normalize_text(value):
    return (
        str(value)
        .lower()
        .strip()
        .replace(" ", "_")
        .replace("-", "_")
    )


# ============================================================
# SMART LABEL LOADER
# ============================================================
def extract_labels_from_json(data):
    if isinstance(data, list):
        return [str(x) for x in data]

    if isinstance(data, dict):
        possible_keys = [
            "classes",
            "class_names",
            "labels",
            "names",
            "categories",
        ]

        for key in possible_keys:
            if key in data and isinstance(data[key], list):
                return [str(x) for x in data[key]]

        # {"0": "class_name", "1": "class_name"}
        if len(data) > 0 and all(str(k).isdigit() for k in data.keys()):
            sorted_items = sorted(data.items(), key=lambda x: int(x[0]))
            return [str(v) for _, v in sorted_items]

        # {"class_name": 0, "class_name": 1}
        if len(data) > 0 and all(isinstance(v, int) for v in data.values()):
            sorted_items = sorted(data.items(), key=lambda x: int(x[1]))
            return [str(k) for k, _ in sorted_items]

    return []


def load_labels(label_paths, fallback_labels):
    for labels_path in label_paths:
        try:
            if not os.path.exists(labels_path):
                continue

            with open(labels_path, "r", encoding="utf-8") as f:
                data = json.load(f)

            labels = extract_labels_from_json(data)

            if labels:
                print("✅ Labels loaded from:", labels_path)
                return labels

            print("⚠️ Label file found but invalid format:", labels_path)

        except Exception as e:
            print("❌ Label load error:", labels_path, e)

    print("⚠️ Using fallback labels")
    return fallback_labels


# ============================================================
# LOAD MODELS
# ============================================================
loaded_models = {}
loaded_labels = {}

for crop, config in MODEL_CONFIG.items():
    try:
        model_path = config["model_path"]

        print(f"\n🔎 Loading {crop} model from:")
        print(model_path)

        if not os.path.exists(model_path):
            print(f"❌ {crop} model not found:", model_path)
            continue

        model = keras.models.load_model(model_path, compile=False)

        labels = load_labels(
            config["label_paths"],
            config["fallback_labels"],
        )

        loaded_models[crop] = model
        loaded_labels[crop] = labels

        print(f"✅ {crop} model loaded:", model_path)
        print(f"✅ {crop} labels:", labels)

        try:
            print(f"✅ {crop} input shape:", model.input_shape)
            print(f"✅ {crop} output shape:", model.output_shape)
        except Exception:
            pass

    except Exception as e:
        print(f"❌ Failed to load {crop} model:", e)


# ============================================================
# FIND DISEASE DETAILS FROM detection.json
# ============================================================
def find_detection_details(crop, disease):
    crop_norm = normalize_text(crop)
    disease_norm = normalize_text(disease)

    for item in detection_data:
        if not isinstance(item, dict):
            continue

        item_crop = normalize_text(item.get("crop", ""))
        item_id = normalize_text(item.get("id", ""))
        item_name = normalize_text(item.get("name", ""))

        if item_crop == crop_norm and (
            item_id == disease_norm or item_name == disease_norm
        ):
            return item

    return None


# ============================================================
# RISK LEVEL
# ============================================================
def get_risk_level(confidence_percent, disease):
    disease_norm = normalize_text(disease)

    healthy_labels = [
        "healthy",
        "healthy_leaves",
        "healthy_rice_leaf",
    ]

    if disease_norm in healthy_labels:
        return "Low"

    if confidence_percent >= 80:
        return "High"

    if confidence_percent >= 60:
        return "Medium"

    return "Low"


# ============================================================
# TREATMENTS
# ============================================================
def get_treatment_list(details, risk):
    if not details:
        return ["No treatment recommendations available"]

    risk_lower = normalize_text(risk)

    if risk_lower == "high":
        treatments = details.get("highRiskTreatments", [])
    else:
        treatments = details.get("lowRiskTreatments", [])

    if isinstance(treatments, list) and len(treatments) > 0:
        return treatments

    fallback = (
        details.get("treatment")
        or details.get("treatments")
        or details.get("recommendations")
        or []
    )

    if isinstance(fallback, list) and len(fallback) > 0:
        return fallback

    if isinstance(fallback, str) and fallback.strip():
        return [fallback]

    return ["No treatment recommendations available"]


# ============================================================
# PREPROCESS IMAGE
# ============================================================
def preprocess_image(image):
    image = ImageOps.exif_transpose(image)
    image = image.convert("RGB")
    image = image.resize((IMG_SIZE, IMG_SIZE))

    arr = np.array(image).astype(np.float32)

    # EfficientNet preprocessing
    arr = preprocess_input(arr)

    arr = np.expand_dims(arr, axis=0)
    return arr


# ============================================================
# FAILED RESPONSE HELPER
# ============================================================
def failed_unknown(message, confidence=0.0, reason="wrong_crop_or_invalid_leaf"):
    return {
        "status": "failed",
        "prediction": "unknown",
        "reason": reason,
        "message": message,
        "confidence": round(float(confidence) * 100, 2),
    }


# ============================================================
# UNCERTAINTY CHECK
# ============================================================
def prediction_is_uncertain(preds, confidence):
    sorted_preds = np.sort(preds)
    second_confidence = float(sorted_preds[-2]) if len(sorted_preds) >= 2 else 0.0
    gap = confidence - second_confidence

    entropy = float(-np.sum(preds * np.log(preds + 1e-10)))

    print("Second confidence:", second_confidence)
    print("Confidence gap:", gap)
    print("Entropy:", entropy)

    # If top two predictions are too close, it is uncertain
    if gap < 0.08:
        return True

    # If probability distribution is too spread out
    if entropy > 1.80:
        return True

    return False


# ============================================================
# MAIN PREDICT FUNCTION
# ============================================================
def predict(image: Image.Image, crop: str):
    try:
        crop = normalize_text(crop)

        if crop not in MODEL_CONFIG:
            return failed_unknown(
                message="Invalid crop selected",
                confidence=0.0,
                reason="invalid_crop",
            )

        if crop not in loaded_models:
            return failed_unknown(
                message="Detection service is temporarily unavailable. Please try again later",
                confidence=0.0,
                reason="model_not_loaded",
            )

        model = loaded_models[crop]
        class_names = loaded_labels.get(crop, [])
        threshold = MODEL_CONFIG[crop]["threshold"]

        if not class_names:
            return failed_unknown(
                message="Detection service is temporarily unavailable. Please try again later",
                confidence=0.0,
                reason="labels_not_loaded",
            )

        img_array = preprocess_image(image)

        preds = model.predict(img_array, verbose=0)[0]
        preds = np.array(preds, dtype=np.float32)

        pred_index = int(np.argmax(preds))
        confidence = float(np.max(preds))

        if pred_index >= len(class_names):
            return failed_unknown(
                message="Detection could not be completed. Please try again",
                confidence=confidence,
                reason="label_index_mismatch",
            )

        predicted_label = class_names[pred_index]
        predicted_norm = normalize_text(predicted_label)

        print("\n========== MODEL PREDICTION ==========")
        print("Crop:", crop)
        print("Predicted:", predicted_label)
        print("Confidence:", confidence)
        print("Threshold:", threshold)
        print("All probabilities:")

        for i, p in enumerate(preds):
            label = class_names[i] if i < len(class_names) else f"class_{i}"
            print(label, ":", float(p))

        print("======================================\n")

        # ====================================================
        # UNKNOWN / WRONG IMAGE REJECTION
        # ====================================================
        if predicted_norm == "unknown":
            return failed_unknown(
                message="Selected crop does not match the image or image is not clear",
                confidence=confidence,
                reason="wrong_crop_or_invalid_leaf",
            )

        if confidence < threshold:
            return failed_unknown(
                message="Please upload a clear leaf image",
                confidence=confidence,
                reason="low_confidence",
            )

        if prediction_is_uncertain(preds, confidence):
            return failed_unknown(
                message="Please upload a clear leaf image",
                confidence=confidence,
                reason="uncertain_prediction",
            )

        # ====================================================
        # SUCCESS RESPONSE WITH detection.json DETAILS
        # ====================================================
        accuracy_percent = confidence * 100
        details = find_detection_details(crop, predicted_label)

        if details:
            disease_name = details.get("name", predicted_label)
            description = details.get("description", "No description available")
        else:
            disease_name = predicted_label
            description = "No detailed data found for this disease"

        risk = get_risk_level(accuracy_percent, predicted_label)
        treatment = get_treatment_list(details, risk)

        return {
            "status": "success",
            "crop": crop,
            "disease": disease_name,
            "prediction": predicted_label,
            "accuracy": round(accuracy_percent, 2),
            "confidence": round(confidence, 4),
            "risk": risk,
            "description": description,
            "treatment": treatment,
        }

    except Exception as e:
        print("❌ Prediction error:", e)

        return failed_unknown(
            message="Detection could not be completed. Please try again",
            confidence=0.0,
            reason="prediction_exception",
        )


# ============================================================
# DIRECT TEST
# ============================================================
if __name__ == "__main__":
    test_path = os.path.join(BASE_DIR, "test.jpg")

    if os.path.exists(test_path):
        img = Image.open(test_path)

        print("\nTea test:")
        print(predict(img, "tea"))

        print("\nCoconut test:")
        print(predict(img, "coconut"))

        print("\nRice test:")
        print(predict(img, "rice"))
    else:
        print("No test.jpg found")