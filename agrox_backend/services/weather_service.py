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
        wind = raw.get("wind", {})
        sys = raw.get("sys", {})
        clouds = raw.get("clouds", {})

        # normalize numeric fields with safe fallbacks
        def to_float(v):
            try:
                return float(v) if v is not None else None
            except Exception:
                return None

        def to_int(v):
            try:
                return int(v) if v is not None else None
            except Exception:
                return None

        temp = to_float(main.get("temp"))
        temp_max = to_float(main.get("temp_max"))
        temp_min = to_float(main.get("temp_min"))
        humidity = to_int(main.get("humidity"))
        pressure = to_int(main.get("pressure"))

        wind_speed = to_float(wind.get("speed")) if wind.get("speed") is not None else 0.0

        condition = None
        description = None
        icon = None
        if weather_list:
            first = weather_list[0]
            condition = first.get("main")
            description = first.get("description")
            icon = first.get("icon")

        # safe rain fallback (1h preferred, then 3h, else 0)
        rain = 0.0
        try:
            rain = float(raw.get("rain", {}).get("1h", raw.get("rain", {}).get("3h", 0.0)))
        except Exception:
            rain = 0.0

        cloud_pct = to_int(clouds.get("all")) or 0

        sunrise = sys.get("sunrise")
        sunset = sys.get("sunset")

        city_name = raw.get("name") or "Nearby"

        clean = {
            "location": city_name,
            "temp": temp,
            "temp_max": temp_max,
            "temp_min": temp_min,
            "humidity": humidity,
            "pressure": pressure,
            "wind_speed": wind_speed,
            "condition": condition,
            "description": description,
            "clouds": cloud_pct,
            "sunrise": int(sunrise) if sunrise is not None else None,
            "sunset": int(sunset) if sunset is not None else None,
            "rain": rain,
            "icon": icon,
        }

        print(f"weather_service: clean -> {clean}")
        return clean

    except Exception as e:
        print(f"weather_service error: {e}")
        return {"error": str(e)}