#!/usr/bin/env python3
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# Rewritten to use Open-Meteo APIs (worldwide, no API key) for robust weather data.
# Outputs Waybar-compatible JSON and a simple text cache.

import json
import os
import sys
import time
import html
from typing import Any, Dict, List, Optional, Tuple

import requests

# =============== Configuration ===============
# You can configure behavior via environment variables OR the constants below.
# Examples (zsh):
#   # One-off run
#   # WEATHER_UNITS can be "metric" or "imperial"
#   WEATHER_UNITS=imperial WEATHER_PLACE="Concord, NH" python3 /home/dwilliams/Projects/Weather.py
#
#   # Persist in current shell session
#   export WEATHER_UNITS=imperial
#   export WEATHER_LAT=43.2229
#   export WEATHER_LON=-71.332
#   export WEATHER_PLACE="Concord, NH"
#   export WEATHER_TOOLTIP_MARKUP=1   # 1 to enable Pango markup, 0 to disable
#   export WEATHER_LOC_ICON="📍"      # or "*" for ASCII-only
#
CACHE_DIR = os.path.expanduser("~/.cache")
API_CACHE_PATH = os.path.join(CACHE_DIR, "open_meteo_cache.json")
SIMPLE_TEXT_CACHE_PATH = os.path.join(CACHE_DIR, ".weather_cache")
CACHE_TTL_SECONDS = int(os.getenv("WEATHER_CACHE_TTL", "600"))  # default 10 minutes

# Units: metric or imperial (default metric)
UNITS = os.getenv("WEATHER_UNITS", "metric").strip().lower()  # metric|imperial

# Optional manual coordinates
ENV_LAT = os.getenv("WEATHER_LAT")
ENV_LON = os.getenv("WEATHER_LON")
# Optional manual place override for tooltip
ENV_PLACE = os.getenv("WEATHER_PLACE")
# Manual place name set inside this file. If set (non-empty), this takes top priority.
# Example: MANUAL_PLACE = "Concord, NH, US"
MANUAL_PLACE: Optional[str] = None

# Location icon in tooltip (default to a standard emoji to avoid missing glyphs)
LOC_ICON = os.getenv("WEATHER_LOC_ICON", "📍")
# Enable/disable Pango markup in tooltip (1/0, true/false)
TOOLTIP_MARKUP = os.getenv("WEATHER_TOOLTIP_MARKUP", "1").lower() not in ("0", "false", "no")
# Optional debug logging to stderr (set WEATHER_DEBUG=1 to enable)
DEBUG = os.getenv("WEATHER_DEBUG", "0").lower() not in ("0", "false", "no")

# HTTP settings
UA = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/128.0 Safari/537.36"
)
TIMEOUT = 8

SESSION = requests.Session()
SESSION.headers.update({"User-Agent": UA})

# =============== Icon and status mapping ===============
# Reuse prior icon set for continuity
WEATHER_ICONS = {
    "sunnyDay": "󰖙",
    "clearNight": "󰖔",
    "cloudyFoggyDay": "",
    "cloudyFoggyNight": "",
    "rainyDay": "",
    "rainyNight": "",
    "snowyIcyDay": "",
    "snowyIcyNight": "",
    "severe": "",
    "default": "",
}

WMO_STATUS = {
    0: "Clear sky",
    1: "Mainly clear",
    2: "Partly cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Depositing rime fog",
    51: "Light drizzle",
    53: "Moderate drizzle",
    55: "Dense drizzle",
    56: "Freezing drizzle",
    57: "Freezing drizzle",
    61: "Light rain",
    63: "Moderate rain",
    65: "Heavy rain",
    66: "Freezing rain",
    67: "Freezing rain",
    71: "Slight snow",
    73: "Moderate snow",
    75: "Heavy snow",
    77: "Snow grains",
    80: "Rain showers",
    81: "Rain showers",
    82: "Violent rain showers",
    85: "Snow showers",
    86: "Heavy snow showers",
    95: "Thunderstorm",
    96: "Thunderstorm w/ hail",
    99: "Thunderstorm w/ hail",
}


def wmo_to_icon(code: int, is_day: int) -> str:
    day = bool(is_day)
    if code == 0:
        return WEATHER_ICONS["sunnyDay" if day else "clearNight"]
    if code in (1, 2, 3, 45, 48):
        return WEATHER_ICONS["cloudyFoggyDay" if day else "cloudyFoggyNight"]
    if code in (51, 53, 55, 61, 63, 65, 80, 81, 82):
        return WEATHER_ICONS["rainyDay" if day else "rainyNight"]
    if code in (56, 57, 66, 67, 71, 73, 75, 77, 85, 86):
        return WEATHER_ICONS["snowyIcyDay" if day else "snowyIcyNight"]
    if code in (95, 96, 99):
        return WEATHER_ICONS["severe"]
    return WEATHER_ICONS["default"]


def wmo_to_status(code: int) -> str:
    return WMO_STATUS.get(code, "Unknown")


# =============== Utilities ===============

def esc(s: Optional[str]) -> str:
    return html.escape(s, quote=False) if s else ""

def log_debug(msg: str) -> None:
    if DEBUG:
        print(msg, file=sys.stderr)

def ensure_cache_dir() -> None:
    try:
        os.makedirs(CACHE_DIR, exist_ok=True)
    except Exception as e:
        print(f"Error creating cache dir: {e}", file=sys.stderr)


def read_api_cache() -> Optional[Dict[str, Any]]:
    try:
        if not os.path.exists(API_CACHE_PATH):
            return None
        with open(API_CACHE_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
        if (time.time() - data.get("timestamp", 0)) <= CACHE_TTL_SECONDS:
            return data
        return None
    except Exception as e:
        print(f"Error reading cache: {e}", file=sys.stderr)
        return None


def write_api_cache(payload: Dict[str, Any]) -> None:
    try:
        ensure_cache_dir()
        payload["timestamp"] = time.time()
        with open(API_CACHE_PATH, "w", encoding="utf-8") as f:
            json.dump(payload, f)
    except Exception as e:
        print(f"Error writing API cache: {e}", file=sys.stderr)


def write_simple_text_cache(text: str) -> None:
    try:
        ensure_cache_dir()
        with open(SIMPLE_TEXT_CACHE_PATH, "w", encoding="utf-8") as f:
            f.write(text)
    except Exception as e:
        print(f"Error writing simple cache: {e}", file=sys.stderr)


def get_coords() -> Tuple[float, float]:
    # 1) Explicit env
    if ENV_LAT and ENV_LON:
        try:
            return float(ENV_LAT), float(ENV_LON)
        except ValueError:
            print("Invalid WEATHER_LAT/WEATHER_LON; falling back to IP geolocation", file=sys.stderr)

    # 2) Try cached coordinates from last successful forecast
    try:
        cached = read_api_cache()
        if cached and isinstance(cached, dict):
            fc = cached.get("forecast") or {}
            lat = fc.get("latitude")
            lon = fc.get("longitude")
            if isinstance(lat, (int, float)) and isinstance(lon, (int, float)):
                return float(lat), float(lon)
    except Exception as e:
        print(f"Reading cached coords failed: {e}", file=sys.stderr)

    # 3) IP-based geolocation with multiple providers (prefer ipwho.is, ipapi.co; ipinfo.io as fallback)
    # ipwho.is
    try:
        resp = SESSION.get("https://ipwho.is/", timeout=TIMEOUT)
        resp.raise_for_status()
        data = resp.json()
        if data.get("success"):
            lat = data.get("latitude")
            lon = data.get("longitude")
            if isinstance(lat, (int, float)) and isinstance(lon, (int, float)):
                return float(lat), float(lon)
    except Exception as e:
        print(f"ipwho.is failed: {e}", file=sys.stderr)

    # ipapi.co
    try:
        resp = SESSION.get("https://ipapi.co/json", timeout=TIMEOUT)
        resp.raise_for_status()
        data = resp.json()
        lat = data.get("latitude")
        lon = data.get("longitude")
        if isinstance(lat, (int, float)) and isinstance(lon, (int, float)):
            return float(lat), float(lon)
    except Exception as e:
        print(f"ipapi.co failed: {e}", file=sys.stderr)

    # ipinfo.io (fallback)
    try:
        resp = SESSION.get("https://ipinfo.io/json", timeout=TIMEOUT)
        resp.raise_for_status()
        data = resp.json()
        loc = data.get("loc")
        if loc and "," in loc:
            lat_s, lon_s = loc.split(",", 1)
            return float(lat_s), float(lon_s)
    except Exception as e:
        print(f"ipinfo.io failed: {e}", file=sys.stderr)

    # 4) Last resort
    print("IP geolocation failed: no providers succeeded", file=sys.stderr)
    return 0.0, 0.0


def units_params(units: str) -> Dict[str, str]:
    if units == "imperial":
        return {
            "temperature_unit": "fahrenheit",
            "wind_speed_unit": "mph",
            "precipitation_unit": "inch",
        }
    # default metric
    return {
        "temperature_unit": "celsius",
        "wind_speed_unit": "kmh",
        "precipitation_unit": "mm",
    }


def format_visibility(meters: Optional[float]) -> str:
    if meters is None:
        return ""
    try:
        if UNITS == "imperial":
            miles = meters / 1609.344
            return f"{miles:.1f} mi"
        else:
            km = meters / 1000.0
            return f"{km:.1f} km"
    except Exception:
        return ""


# =============== API Fetching ===============

def fetch_open_meteo(lat: float, lon: float) -> Dict[str, Any]:
    base = "https://api.open-meteo.com/v1/forecast"
    params = {
        "latitude": lat,
        "longitude": lon,
        "current": "temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,wind_direction_10m,weather_code,visibility,precipitation,pressure_msl,is_day",
        "hourly": "precipitation_probability",
        "daily": "temperature_2m_max,temperature_2m_min",
        "timezone": "auto",
    }
    params.update(units_params(UNITS))
    resp = SESSION.get(base, params=params, timeout=TIMEOUT)
    resp.raise_for_status()
    return resp.json()


def fetch_aqi(lat: float, lon: float) -> Optional[Dict[str, Any]]:
    try:
        base = "https://air-quality-api.open-meteo.com/v1/air-quality"
        params = {
            "latitude": lat,
            "longitude": lon,
            "current": "european_aqi",
            "timezone": "auto",
        }
        resp = SESSION.get(base, params=params, timeout=TIMEOUT)
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        print(f"AQI fetch failed: {e}", file=sys.stderr)
        return None


def fetch_place(lat: float, lon: float) -> Optional[str]:
    """Reverse geocode lat/lon to an approximate place. Tries Nominatim first, then Open-Meteo."""
    lang = os.getenv("WEATHER_LANG", "en")

    # 1) Nominatim (OpenStreetMap)
    try:
        base = "https://nominatim.openstreetmap.org/reverse"
        params = {
            "lat": lat,
            "lon": lon,
            "format": "jsonv2",
            "accept-language": lang,
        }
        headers = {"User-Agent": UA + " Weather.py/1.0"}
        resp = SESSION.get(base, params=params, headers=headers, timeout=TIMEOUT)
        resp.raise_for_status()
        data = resp.json()
        address = data.get("address", {})
        name = data.get("name") or address.get("city") or address.get("town") or address.get("village") or address.get("hamlet")
        admin1 = address.get("state")
        country = address.get("country")
        parts = [part for part in [name, admin1, country] if part]
        if parts:
            return ", ".join(parts)
    except Exception as e:
        log_debug(f"Reverse geocoding (Nominatim) failed: {e}")

    # 2) Open-Meteo reverse (fallback)
    try:
        base = "https://geocoding-api.open-meteo.com/v1/reverse"
        params = {
            "latitude": lat,
            "longitude": lon,
            "language": lang,
            "format": "json",
        }
        resp = SESSION.get(base, params=params, timeout=TIMEOUT)
        resp.raise_for_status()
        data = resp.json()
        results = data.get("results") or []
        if results:
            p = results[0]
            name = p.get("name")
            admin1 = p.get("admin1")
            country = p.get("country")
            parts = [part for part in [name, admin1, country] if part]
            if parts:
                return ", ".join(parts)
    except Exception as e:
        log_debug(f"Reverse geocoding (Open-Meteo) failed: {e}")

    return None


# =============== Build Output ===============

def safe_get(dct: Dict[str, Any], *keys, default=None):
    cur: Any = dct
    for k in keys:
        if isinstance(cur, dict):
            if k not in cur:
                return default
            cur = cur[k]
        elif isinstance(cur, list):
            try:
                cur = cur[k]  # type: ignore[index]
            except Exception:
                return default
        else:
            return default
    return cur


def build_hourly_precip(forecast: Dict[str, Any]) -> str:
    try:
        times: List[str] = safe_get(forecast, "hourly", "time", default=[]) or []
        probs: List[Optional[float]] = safe_get(
            forecast, "hourly", "precipitation_probability", default=[]
        ) or []
        cur_time: Optional[str] = safe_get(forecast, "current", "time")
        idx = times.index(cur_time) if cur_time in times else 0
        window = probs[idx : idx + 6]
        if not window:
            return ""
        parts = [f"{int(p)}%" if p is not None else "-" for p in window]
        return " (next 6h) " + " ".join(parts)
    except Exception:
        return ""


def build_output(lat: float, lon: float, forecast: Dict[str, Any], aqi: Optional[Dict[str, Any]], place: Optional[str] = None) -> Tuple[Dict[str, Any], str]:
    cur = forecast.get("current", {})
    cur_units = forecast.get("current_units", {})
    daily = forecast.get("daily", {})
    daily_units = forecast.get("daily_units", {})

    temp_val = cur.get("temperature_2m")
    temp_unit = cur_units.get("temperature_2m", "")
    temp_str = f"{int(round(temp_val))}{temp_unit}" if isinstance(temp_val, (int, float)) else "N/A"

    feels_val = cur.get("apparent_temperature")
    feels_unit = cur_units.get("apparent_temperature", "")
    feels_str = f"Feels like {int(round(feels_val))}{feels_unit}" if isinstance(feels_val, (int, float)) else ""

    is_day = int(cur.get("is_day", 1) or 1)
    code = int(cur.get("weather_code", -1) or -1)
    icon = wmo_to_icon(code, is_day)
    status = wmo_to_status(code)

    # min/max today (index 0)
    tmin_val = safe_get(daily, "temperature_2m_min", 0)
    tmax_val = safe_get(daily, "temperature_2m_max", 0)
    dtemp_unit = daily_units.get("temperature_2m_min", temp_unit)
    tmin_str = f"{int(round(tmin_val))}{dtemp_unit}" if isinstance(tmin_val, (int, float)) else ""
    tmax_str = f"{int(round(tmax_val))}{dtemp_unit}" if isinstance(tmax_val, (int, float)) else ""
    min_max = f"  {tmin_str}\t\t  {tmax_str}" if tmin_str and tmax_str else ""

    wind_val = cur.get("wind_speed_10m")
    wind_unit = cur_units.get("wind_speed_10m", "")
    wind_text = f"  {int(round(wind_val))}{wind_unit}" if isinstance(wind_val, (int, float)) else ""

    hum_val = cur.get("relative_humidity_2m")
    humidity_text = f"  {int(hum_val)}%" if isinstance(hum_val, (int, float)) else ""

    vis_val = cur.get("visibility")
    visibility_text = f"  {format_visibility(vis_val)}" if isinstance(vis_val, (int, float)) else ""

    aqi_val = safe_get(aqi or {}, "current", "european_aqi")
    aqi_text = f"AQI {int(aqi_val)}" if isinstance(aqi_val, (int, float)) else "AQI N/A"

    hourly_precip = build_hourly_precip(forecast)
    prediction = f"\n\n{hourly_precip}" if hourly_precip else ""

    # Build place string (priority: MANUAL_PLACE > ENV_PLACE > reverse geocode > lat,lon)
    place_str = (MANUAL_PLACE or ENV_PLACE or place or f"{lat:.3f}, {lon:.3f}")
    location_text = f"{LOC_ICON}  {place_str}"

    # Build tooltip (markup or plain)
    if TOOLTIP_MARKUP:
        # Escape dynamic text to avoid breaking Pango markup
        tooltip_text = str.format(
            "\t\t{}\t\t\n{}\n{}\n{}\n{}\n\n{}\n{}\n{}{}",
            f'<span size="xx-large">{esc(temp_str)}</span>',
            f"<big> {icon}</big>",
            f"<b>{esc(status)}</b>",
            esc(location_text),
            f"<small>{esc(feels_str)}</small>" if feels_str else "",
            f"<b>{esc(min_max)}</b>" if min_max else "",
            f"{esc(wind_text)}\t{esc(humidity_text)}",
            f"{esc(visibility_text)}\t{esc(aqi_text)}",
            f"<i> {esc(prediction)}</i>" if prediction else "",
        )
    else:
        lines = [
            f"{icon}  {temp_str}",
            status,
            location_text,
        ]
        if feels_str:
            lines.append(feels_str)
        if min_max:
            lines.append(min_max)
        lines.append(f"{wind_text} {humidity_text}".strip())
        lines.append(f"{visibility_text} {aqi_text}".strip())
        if prediction:
            lines.append(hourly_precip)
        tooltip_text = "\n".join([ln for ln in lines if ln])

    out_data = {
        "text": f"{icon}  {temp_str}",
        "alt": status,
        "tooltip": tooltip_text,
        "class": f"wmo-{code} {'day' if is_day else 'night'}",
    }

    simple_weather = (
        f"{icon}  {status}\n"
        + f"  {temp_str} ({feels_str})\n"
        + (f"{wind_text} \n" if wind_text else "")
        + (f"{humidity_text} \n" if humidity_text else "")
        + f"{visibility_text} {aqi_text}\n"
    )

    return out_data, simple_weather


def main() -> None:
    lat, lon = get_coords()

    # Try cache first
    cached = read_api_cache()
    if cached and isinstance(cached, dict):
        forecast = cached.get("forecast")
        aqi = cached.get("aqi")
        cached_place = cached.get("place") if isinstance(cached.get("place"), str) else None
        place_effective = MANUAL_PLACE or ENV_PLACE or cached_place
        try:
            out, simple = build_output(lat, lon, forecast, aqi, place_effective)
            print(json.dumps(out, ensure_ascii=False))
            write_simple_text_cache(simple)
            return
        except Exception as e:
            print(f"Cached data build failed, refetching: {e}", file=sys.stderr)

    # Fetch fresh
    try:
        forecast = fetch_open_meteo(lat, lon)
        aqi = fetch_aqi(lat, lon)
        # Use manual/env place if provided; otherwise reverse geocode
        place_effective = MANUAL_PLACE or ENV_PLACE or fetch_place(lat, lon)
        write_api_cache({"forecast": forecast, "aqi": aqi, "place": place_effective})
        out, simple = build_output(lat, lon, forecast, aqi, place_effective)
        print(json.dumps(out, ensure_ascii=False))
        write_simple_text_cache(simple)
    except Exception as e:
        print(f"Open-Meteo fetch failed: {e}", file=sys.stderr)
        # Last resort: try stale cache without TTL
        try:
            if os.path.exists(API_CACHE_PATH):
                with open(API_CACHE_PATH, "r", encoding="utf-8") as f:
                    stale = json.load(f)
                out, simple = build_output(lat, lon, stale.get("forecast", {}), stale.get("aqi"), stale.get("place") if isinstance(stale.get("place"), str) else None)
                print(json.dumps(out, ensure_ascii=False))
                write_simple_text_cache(simple)
                return
        except Exception as e2:
            print(f"Failed to use stale cache: {e2}", file=sys.stderr)
        # Fallback minimal output
        fallback = {
            "text": f"{WEATHER_ICONS['default']}  N/A",
            "alt": "Unavailable",
            "tooltip": "Weather unavailable",
            "class": "unavailable",
        }
        print(json.dumps(fallback, ensure_ascii=False))


if __name__ == "__main__":
    main()
