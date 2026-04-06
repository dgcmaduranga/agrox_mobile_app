import requests
import os
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("OPENWEATHER_API_KEY")


def get_weather(lat, lon):
    """Fetch weather from OpenWeather and return a clean JSON.

    Returns keys: temp (double), humidity (int), condition (string), city (string)
    """
    if not API_KEY:
        print("weather_service: OPENWEATHER_API_KEY not set in environment")
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
        print(f"weather_service: OpenWeather status={res.status_code}")
        raw = res.json()
        # Debug full response
        print(f"weather_service: raw -> {raw}")

        if res.status_code != 200:
            return {"error": "upstream_failure", "status": res.status_code, "body": raw}

        main = raw.get("main", {})
        weather_list = raw.get("weather", [])

        temp = None
        if "temp" in main:
            try:
                temp = float(main.get("temp"))
            except Exception:
                temp = None

        humidity = None
        if "humidity" in main:
            try:
                humidity = int(main.get("humidity"))
            except Exception:
                humidity = None

        condition = None
        if weather_list and isinstance(weather_list, list):
            condition = weather_list[0].get("main") or weather_list[0].get("description")

        city = raw.get("name")

        # Build clean response
        clean = {
            "temp": temp,
            "humidity": humidity,
            "condition": condition,
            "city": city,
        }

        print(f"weather_service: clean -> {clean}")
        return clean

    except Exception as e:
        print(f"weather_service: exception when calling OpenWeather: {e}")
        return {"error": "exception", "message": str(e)}