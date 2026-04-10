import requests
import os
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("OPENWEATHER_API_KEY")


def get_weather(lat, lon):
    """Fetch weather from OpenWeather and return clean JSON"""

    if not API_KEY:
        print("weather_service: OPENWEATHER_API_KEY not set")
        return {"error": "missing_api_key"}

    url = "https://api.openweathermap.org/data/2.5/weather"

    params = {
        "lat": lat,
        "lon": lon,
        "appid": API_KEY,
        "units": "metric",
    }

    try:
        res = requests.get(url, params=params, timeout=8)
        raw = res.json()

        print(f"weather_service: status={res.status_code}")
        print(f"weather_service: raw -> {raw}")

        if res.status_code != 200:
            return {"error": "api_error", "body": raw}

        main = raw.get("main", {})
        weather_list = raw.get("weather", [])

        temp = float(main.get("temp")) if main.get("temp") else None
        humidity = int(main.get("humidity")) if main.get("humidity") else None

        condition = None
        if weather_list:
            condition = weather_list[0].get("main")

        # ❌ REMOVE CITY FROM HERE
        clean = {
            "temp": temp,
            "humidity": humidity,
            "condition": condition,
        }

        print(f"weather_service: clean -> {clean}")
        return clean

    except Exception as e:
        print(f"weather_service error: {e}")
        return {"error": str(e)}