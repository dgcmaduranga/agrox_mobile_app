import numpy as np
from PIL import Image
from tensorflow.keras.models import load_model

# =========================
# LOAD H5 MODELS 🔥
# =========================
coconut_model = load_model("models/coconut_model.h5")
rice_model = load_model("models/rice_model.h5")
tea_model = load_model("models/tea_model.h5")

print("✅ Models loaded")

# =========================
# CONFIDENCE THRESHOLD 🔥
# =========================
CONFIDENCE_THRESHOLD = 0.75

# =========================
# CLASS LABELS (EXACT MATCH 🔥)
# =========================

# 🥥 COCONUT
coconut_classes = [
    "CCI_Caterpillars",
    "CCI_Leaflets",
    "Healthy_Leaves",
    "WCLWD_DryingofLeaflets",
    "WCLWD_Flaccidity",
    "WCLWD_Yellowing"
]

# 🌾 RICE
rice_classes = [
    "Bacterial_Leaf_Blight",
    "Brown_Spot",
    "Healthy_Rice_Leaf",
    "Leaf_Blast",
    "Leaf_scald",
    "Sheath_Blight"
]

# 🍃 TEA
tea_classes = [
    "algal_spot",
    "brown_blight",
    "gray_blight",
    "healthy",
    "helopeltis",
    "red_spot"
]

# =========================
# PREPROCESS (MATCH TRAINING 🔥)
# =========================
def preprocess(image: Image.Image, crop: str):

    crop = crop.lower()

    if crop == "rice":
        size = 380
    elif crop == "tea":
        size = 300
    elif crop == "coconut":
        size = 300
    else:
        size = 300

    image = image.resize((size, size))

    img_array = np.array(image) / 255.0
    img_array = np.expand_dims(img_array, axis=0).astype(np.float32)

    return img_array


# =========================
# PREDICT FUNCTION 🔥🔥🔥
# =========================
def predict(image: Image.Image, crop: str):

    crop = crop.lower()

    img = preprocess(image, crop)

    # =========================
    # SELECT MODEL
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
    # PREDICTION
    # =========================
    preds = model.predict(img, verbose=0)[0]

    predicted_index = int(np.argmax(preds))
    confidence = float(preds[predicted_index])
    predicted_label = classes[predicted_index]

    # =========================
    # 🔥 CONFIDENCE FILTER (KEY FIX)
    # =========================
    if confidence < CONFIDENCE_THRESHOLD:
        print("⚠️ Low confidence → rejecting prediction")
        return "unknown", confidence

    # =========================
    # DEBUG
    # =========================
    print("----- AI DEBUG -----")
    print("Crop:", crop)
    print("Index:", predicted_index)
    print("Label:", predicted_label)
    print("Confidence:", confidence)
    print("--------------------")

    return predicted_label, confidence