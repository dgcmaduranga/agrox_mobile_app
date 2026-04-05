import numpy as np
from PIL import Image
import tensorflow as tf

# ==============================
# 🔥 LOAD MODELS (ONCE)
# ==============================

models = {
    "paddy": tf.lite.Interpreter(model_path="models/rice_model.tflite"),
    "tea": tf.lite.Interpreter(model_path="models/tea_model.tflite"),
    "coconut": tf.lite.Interpreter(model_path="models/coconut_model.tflite"),
}

for model in models.values():
    model.allocate_tensors()


# ==============================
# 🔥 LABELS (MATCH YOUR DATASET)
# ==============================

labels = {

    "paddy": [
        "Brown_Spot",
        "Healthy_Rice_Leaf",
        "Leaf_Blast",
        "Leaf_scald",
        "Bacterial_Leaf_Blight",
        "Sheath_Blight"
    ],

    "tea": [
        "gray_blight",
        "algal_spot",
        "helopeltis",
        "healthy",
        "brown_blight",
        "red_spot"
    ],

    "coconut": [
        "WCLWD_Flaccidity",
        "WCLWD_DryingofLeaflets",
        "CCI_Leaflets",
        "WCLWD_Yellowing",
        "Healthy_Leaves",
        "CCI_Caterpillars"
    ]
}


# ==============================
# 🔥 PREPROCESS FUNCTION
# ==============================

def preprocess(image: Image.Image):
    # Resize
    image = image.resize((300, 300))

    # Convert to RGB
    image = image.convert("RGB")

    # Convert to numpy + normalize
    img = np.array(image).astype(np.float32) / 255.0

    # Add batch dimension
    img = np.expand_dims(img, axis=0)

    return img


# ==============================
# 🔥 PREDICT FUNCTION
# ==============================

def predict(image: Image.Image, crop: str):

    # Get correct model
    interpreter = models[crop]

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    # Preprocess image
    input_data = preprocess(image)

    # Run inference
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()

    # Get output
    output = interpreter.get_tensor(output_details[0]['index'])[0]

    # Get best prediction
    index = int(np.argmax(output))
    confidence = float(output[index])

    # Map to disease name
    disease = labels[crop][index]

    return disease, confidence