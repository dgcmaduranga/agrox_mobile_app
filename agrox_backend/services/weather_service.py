import requests
import os
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("OPENWEATHER_API_KEY")


def get_weather(lat, lon):
    """
    Fetch current weather from OpenWeather and return clean JSON.

    Important:
    - condition: raw main condition from OpenWeather, e.g. Clouds, Rain, Clear
    - description: full condition text, e.g. overcast clouds, light rain
    - display_condition: app-friendly text
    - hasRain: true only when API gives rain / drizzle / thunderstorm / rain amount
    """

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
            return {
                "error": "api_error",
                "status": res.status_code,
                "body": raw,
            }

        main = raw.get("main", {}) or {}
        weather_list = raw.get("weather", []) or []
        wind = raw.get("wind", {}) or {}
        sys = raw.get("sys", {}) or {}
        clouds = raw.get("clouds", {}) or {}
        rain_map = raw.get("rain", {}) or {}

        # =========================
        # SAFE CONVERTERS
        # =========================
        def to_float(value, default=None):
            try:
                if value is None:
                    return default
                return float(value)
            except Exception:
                return default

        def to_int(value, default=None):
            try:
                if value is None:
                    return default
                return int(value)
            except Exception:
                return default

        def clean_text(value, fallback=""):
            if value is None:
                return fallback
            text = str(value).strip()
            return text if text else fallback

        def title_case_weather(text):
            text = clean_text(text, "")
            if not text:
                return "Unknown"
            return " ".join(word.capitalize() for word in text.split())

        # =========================
        # MAIN WEATHER VALUES
        # =========================
        temp = to_float(main.get("temp"), 0.0)
        temp_max = to_float(main.get("temp_max"), temp)
        temp_min = to_float(main.get("temp_min"), temp)
        humidity = to_int(main.get("humidity"), 0)
        pressure = to_int(main.get("pressure"), 0)

        wind_speed = to_float(wind.get("speed"), 0.0)
        cloud_pct = to_int(clouds.get("all"), 0)

        condition = "Unknown"
        description = "Unknown"
        icon = ""

        weather_id = None

        if weather_list:
            first_weather = weather_list[0] or {}
            weather_id = first_weather.get("id")
            condition = clean_text(first_weather.get("main"), "Unknown")
            description = clean_text(first_weather.get("description"), condition)
            icon = clean_text(first_weather.get("icon"), "")

        # =========================
        # RAIN DETECTION
        # =========================
        rain_1h = to_float(rain_map.get("1h"), 0.0)
        rain_3h = to_float(rain_map.get("3h"), 0.0)
        rain = rain_1h if rain_1h > 0 else rain_3h

        condition_lower = condition.lower()
        description_lower = description.lower()

        has_rain = (
            rain > 0
            or "rain" in condition_lower
            or "drizzle" in condition_lower
            or "thunderstorm" in condition_lower
            or "rain" in description_lower
            or "drizzle" in description_lower
            or "shower" in description_lower
            or "thunderstorm" in description_lower
        )

        is_cloudy = (
            "cloud" in condition_lower
            or "cloud" in description_lower
            or cloud_pct >= 60
        )

        is_clear = (
            "clear" in condition_lower
            or "clear" in description_lower
        )

        # =========================
        # DISPLAY CONDITION FOR APP
        # =========================
        # Rain has priority over clouds.
        if has_rain:
            if "thunder" in condition_lower or "thunder" in description_lower:
                display_condition = "Thunderstorm"
            elif "drizzle" in condition_lower or "drizzle" in description_lower:
                display_condition = "Drizzle"
            elif "light rain" in description_lower:
                display_condition = "Light Rain"
            elif "heavy rain" in description_lower:
                display_condition = "Heavy Rain"
            else:
                display_condition = "Rain"
        else:
            display_condition = title_case_weather(description)

            if display_condition == "Unknown":
                display_condition = title_case_weather(condition)

        sunrise = to_int(sys.get("sunrise"), None)
        sunset = to_int(sys.get("sunset"), None)

        city_name = (
            clean_text(raw.get("name"), "")
            or clean_text(raw.get("location"), "")
            or "Nearby"
        )

        clean = {
            "location": city_name,
            "city": city_name,

            "temp": temp,
            "temp_max": temp_max,
            "temp_min": temp_min,
            "humidity": humidity,
            "pressure": pressure,
            "wind_speed": wind_speed,

            "condition": condition,
            "description": description,
            "display_condition": display_condition,

            "clouds": cloud_pct,
            "isCloudy": is_cloudy,
            "isClear": is_clear,

            "rain": rain,
            "rain_1h": rain_1h,
            "rain_3h": rain_3h,
            "hasRain": has_rain,

            "sunrise": sunrise,
            "sunset": sunset,

            "icon": icon,
            "weather_id": weather_id,
        }

        print(f"weather_service: clean -> {clean}")
        return clean

    except requests.exceptions.Timeout:
        print("weather_service error: request timeout")
        return {"error": "weather_timeout"}

    except requests.exceptions.RequestException as e:
        print(f"weather_service request error: {e}")
        return {"error": "weather_request_error", "message": str(e)}

    except Exception as e:
        print(f"weather_service error: {e}")
        return {"error": "weather_unknown_error", "message": str(e)}