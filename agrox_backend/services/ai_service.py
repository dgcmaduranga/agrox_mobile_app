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
    "Leaf_scald",
    "Sheath_Blight"
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
        threshold = 0.75

    elif crop == "rice":
        model = rice_model
        classes = rice_classes
        threshold = 0.60   # 🔥 rice fix

    elif crop == "tea":
        model = tea_model
        classes = tea_classes
        threshold = 0.75

    else:
        return "unknown", 0.0

    # =========================
    # PREDICTION
    # =========================
    preds = model.predict(img, verbose=0)[0]

    # 🔥 DEBUG FULL OUTPUT
    print("RAW PREDICTIONS:", preds)

    # =========================
    # 🔥 TOP-2 FIX (VERY IMPORTANT)
    # =========================
    top2 = np.argsort(preds)[-2:][::-1]

    best_idx = int(top2[0])
    second_idx = int(top2[1])

    best_conf = float(preds[best_idx])
    second_conf = float(preds[second_idx])

    # 🔥 if predictions too close → switch
    if abs(best_conf - second_conf) < 0.10:
        print("⚠️ Close predictions → using second best")
        predicted_index = second_idx
        confidence = second_conf
    else:
        predicted_index = best_idx
        confidence = best_conf

    predicted_label = classes[predicted_index]

    # =========================
    # CONFIDENCE FILTER
    # =========================
    if confidence < threshold:
        print("⚠️ Low confidence → rejecting")
        print("Confidence:", confidence)
        return "unknown", confidence

    # =========================
    # DEBUG
    # =========================
    print("----- AI DEBUG -----")
    print("Crop:", crop)
    print("Best Index:", best_idx, "| Conf:", best_conf)
    print("Second Index:", second_idx, "| Conf:", second_conf)
    print("Final Label:", predicted_label)
    print("Final Confidence:", confidence)
    print("--------------------")

    return predicted_label, confidence