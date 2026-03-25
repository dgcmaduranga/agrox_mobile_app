from fastapi import FastAPI
from weather import get_weather

app = FastAPI()

@app.get("/weather")
def weather_api(lat: float, lon: float):
    return get_weather(lat, lon)