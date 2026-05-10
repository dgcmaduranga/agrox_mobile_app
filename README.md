# AgroX Mobile Application 🌱

AgroX is a smart agriculture mobile application designed to support crop disease detection, disease awareness, weather-based risk monitoring, and agriculture-related guidance for Sri Lankan farmers. The system combines AI-based image classification, a FastAPI backend, Firebase services, weather data, and an agriculture-focused AI chatbot into one mobile solution.

This project was developed as a final year individual project for a BSc (Hons) Computer Science degree program.

---

## 📌 Project Overview

Agriculture plays an important role in Sri Lanka, but many farmers face difficulties in identifying crop diseases at an early stage. Delayed disease identification can reduce crop quality, increase treatment cost, and affect overall yield.

AgroX addresses this problem by allowing users to capture or upload a clear leaf image and receive an AI-based disease prediction with useful treatment guidance. The application focuses on three major crop categories:

- Tea Leaf
- Coconut Leaf
- Rice Leaf

The system also provides a Knowledge Hub, weather-based crop disease risk alerts, saved treatments, detection history, push notifications, and an AI chatbot for agriculture-related questions.

---

## 🚀 Key Features

### AI Crop Disease Detection

AgroX allows users to select a crop type and upload or capture a leaf image. The backend processes the image using trained AI models and returns the disease prediction result.

The result includes:

- Disease name
- Crop type
- Prediction accuracy
- Risk level
- Disease description
- Recommended treatment guidance

---

### Three Trained AI Models

AgroX uses three separately trained AI models for better crop-specific disease detection.

The trained models are:

- Tea disease detection model
- Coconut disease detection model
- Rice disease detection model

Each model is trained separately for its own crop category. This improves prediction quality and helps reduce incorrect classification between different crop types.

---

### Knowledge Hub

The Knowledge Hub provides structured disease information for tea, coconut, and rice crops.

Users can view:

- Disease descriptions
- Symptoms
- Causes
- High-risk treatments
- Low-risk treatments
- Prevention methods

This helps users learn about crop diseases even without running a new detection.

---

### Ask AgroX AI Chatbot

AgroX includes an agriculture-focused AI chatbot that supports users with farming-related questions.

The chatbot can help with questions related to:

- Crop diseases
- Pests
- Fertilizer
- Soil
- Irrigation
- Weather risks
- Crop care
- Harvesting
- General agriculture guidance

The chatbot is designed to focus only on agriculture-field questions, making it more useful and relevant for farmers.

---

### Weather-Based Risk Alerts

AgroX includes weather-based crop disease risk alerts. The system uses weather data such as temperature, humidity, rainfall, pressure, and wind conditions to identify possible disease risk levels.

This helps users take early action before diseases spread further.

---

### Firebase Services

Firebase is used to support authentication, data storage, and notification features.

Firebase features include:

- User login and signup
- User profile support
- Detection history saving
- Saved treatment management
- Push notifications using Firebase Cloud Messaging

---

## 🧠 AI Model Workflow

The disease detection workflow works as follows:

1. User selects the crop type.
2. User captures or uploads a clear leaf image.
3. The mobile app sends the image and crop type to the backend API.
4. The FastAPI backend selects the correct trained model.
5. The model processes the image and predicts the disease.
6. The backend returns the prediction result to the mobile app.
7. The app displays disease details, accuracy, risk level, and treatments.

---

## 🛠️ Technologies Used

### Mobile Frontend

- Flutter
- Dart
- Provider state management
- Responsive mobile UI design

### Backend

- FastAPI
- Python
- REST API architecture
- Backend-side AI model inference

### AI and Machine Learning

- TensorFlow
- Keras
- Deep learning-based image classification
- Crop-specific trained models
- Image preprocessing and prediction handling

### Cloud and APIs

- Firebase Authentication
- Firebase Firestore
- Firebase Cloud Messaging
- OpenAI API
- Weather API

### Testing and CI/CD

- Flutter testing
- GitHub Actions workflow
- Automated Flutter validation

---

## 📱 Application Screens

The AgroX mobile application includes the following main screens:

- Splash Screen
- Welcome Screen
- Login Screen
- Signup Screen
- Home Dashboard
- Disease Detection Page
- Detection Result Page
- Knowledge Hub
- Disease Detail Page
- Ask AgroX AI Chatbot Page
- Weather Risk Alert Page
- Notification Page
- Profile Page
- Detection History Page
- Saved Treatments Page

---

## 🌐 Backend API

The backend is developed using FastAPI and handles the main system logic of AgroX.

The backend supports:

- Disease detection requests
- AI model loading and prediction
- Disease information handling
- Weather data processing
- Agriculture chatbot requests
- API communication with the mobile application

---

## 🔐 Security and Repository Notes

Large trained model files and environment files are not included in this public repository.

The following files are excluded for security and file size reasons:

- Trained AI model files
- API keys
- Environment configuration files
- Sensitive backend credentials

During deployment, the backend server is configured separately with the required model files and environment variables.

---

## ⚙️ CI/CD Workflow

This project includes a GitHub Actions workflow for automated Flutter project validation.

The workflow runs when changes are pushed to the main, production, or dev branches.

The CI workflow includes:

- Checkout source code
- Setup Flutter SDK
- Install Flutter dependencies
- Run Flutter analyze check
- Run Flutter tests
- Validate project structure

---

## 📦 Project Status

AgroX is completed with the following components:

- Premium Flutter mobile UI
- Firebase Authentication
- Firebase Firestore integration
- AI disease detection support
- Three trained crop disease detection models
- FastAPI backend integration
- Agriculture-focused AI chatbot
- Knowledge Hub
- Weather-based risk alerts
- Detection history
- Saved treatments
- Push notification support
- CI/CD workflow configuration

---

## 🎯 Project Purpose

The main purpose of AgroX is to provide a practical digital solution for crop disease detection and agriculture support. It aims to help users identify diseases earlier, understand symptoms and treatments, and access agriculture-related guidance through a simple mobile application.

---

## 👨‍💻 Developer

Developed by Charith Gamage as a final year individual project for a BSc (Hons) Computer Science degree program.

---

## 📄 License

This project is developed for academic purposes.
