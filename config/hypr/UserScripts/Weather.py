#!/usr/bin/env python3
# Weather module for Waybar using Open-Meteo API
# Original: https://github.com/JaKooLit/Hyprland-Dots

import requests
import json
import os

# Weather icons (Nerd Font)
weather_icons = {
    "0": "󰖙",   # Clear sky (day)
    "1": "󰖙",   # Mainly clear (day)
    "2": "",   # Partly cloudy
    "3": "",   # Overcast
    "45": "",  # Fog
    "48": "",  # Freezing fog
    "51": "",  # Light drizzle
    "53": "",  # Moderate drizzle
    "55": "",  # Dense drizzle
    "56": "",  # Freezing drizzle
    "57": "",  # Heavy freezing drizzle
    "61": "",  # Slight rain
    "63": "",  # Moderate rain
    "65": "",  # Heavy rain
    "66": "",  # Freezing rain
    "67": "",  # Heavy freezing rain
    "71": "",  # Slight snow
    "73": "",  # Moderate snow
    "75": "",  # Heavy snow
    "77": "",  # Snow grains
    "80": "",  # Slight rain showers
    "81": "",  # Moderate rain showers
    "82": "",  # Violent rain showers
    "85": "",  # Slight snow showers
    "86": "",  # Heavy snow showers
    "95": "",  # Thunderstorm
    "96": "",  # Thunderstorm + hail
    "99": "",  # Heavy thunderstorm + hail
    "default": ""
}

# Get location (latitude/longitude)
def get_location():
    try:
        response = requests.get("https://ipinfo.io/json", timeout=5)
        data = response.json()
        lat, lon = data["loc"].split(",")
        return float(lat), float(lon)
    except:
        return 54.9914, 73.3645

latitude, longitude = get_location()

# Fetch weather data from Open-Meteo
try:
    url = f"https://api.open-meteo.com/v1/forecast?latitude={latitude}&longitude={longitude}&current_weather=true"
    response = requests.get(url, timeout=10)
    data = response.json()
    
    temp = round(data["current_weather"]["temperature"])
    status_code = str(data["current_weather"]["weathercode"])
    wind_speed = data["current_weather"]["windspeed"]
    icon = weather_icons.get(status_code, weather_icons["default"])
    
    # Simple status text (you can customize this)
    status_mapping = {
        "0": "Clear", "1": "Mostly Clear", "2": "Partly Cloudy", "3": "Overcast",
        "45": "Fog", "61": "Light Rain", "63": "Rain", "80": "Showers"
    }
    status = status_mapping.get(status_code, "N/A")

except Exception as e:
    temp = "?"
    status = "No Data"
    icon = weather_icons["default"]
    wind_speed = "?"

# Waybar output
output = {
    "text": f"{icon}  {temp}°C",
    "alt": status,
    "tooltip": f"<b>{status}</b>\n🌡️ {temp}°C\n🌬️ {wind_speed} km/h",
    "class": status_code
}

print(json.dumps(output))

# Optional: Cache simple weather for other scripts
try:
    with open(os.path.expanduser("~/.cache/.weather_cache"), "w") as f:
        f.write(f"{icon} {temp}°C | {status}")
except:
    pass