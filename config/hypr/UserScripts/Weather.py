#!/usr/bin/env python3
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# Rewritten to use Open-Meteo APIs (worldwide, no API key) for robust weather data.
# Outputs Waybar-compatible JSON and a simple text cache.

from __future__ import annotations

import json
import os
import sys
import time
import html
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, TypeVar, Union, cast
from typing import NamedTuple
import requests

from dataclasses import dataclass

@dataclass
class Location:
    lat: float
    lon: float
    place: Optional[str] = None


@dataclass
class WeatherData:
    temp_str: str
    feels_str: str
    icon: str
    status: str
    min_max: str
    wind_text: str
    humidity_text: str
    visibility_text: str
    aqi_text: str
    hourly_precip: str
    is_day: int
    code: int

# =============== Configuration ===============
# You can configure behavior via environment variables OR the constants below.
# Examples (zsh):
#   # One-off run
#   # WEATHER_UNITS can be "metric" or "imperial"
#   WEATHER_UNITS=imperial WEATHER_PLACE="Concord, NH" python3 ~/.config/hypr/UserScripts/Weather.py
#
#   # Persist in current shell session
#   export WEATHER_UNITS=imperial
#   export WEATHER_LAT=43.2229
#   export WEATHER_LON=-71.332
#   export WEATHER_PLACE="Concord, NH"
#   export WEATHER_TOOLTIP_MARKUP=1   # 1 to enable Pango markup, 0 to disable
#   export WEATHER_LOC_ICON="📍"      # or "*" for ASCII-only
#
CACHE_DIR: Path = Path.home() / ".cache"
API_CACHE_PATH: Path = CACHE_DIR / "open_meteo_cache.json"
SIMPLE_TEXT_CACHE_PATH: Path = CACHE_DIR / ".weather_cache"
CACHE_TTL_SECONDS = int(os.getenv("WEATHER_CACHE_TTL", "300"))  # default 5 minutes

# Units: metric or imperial (default metric)
UNITS = os.getenv("WEATHER_UNITS", "metric").strip().lower()  # metric|imperial

# Optional manual coordinates
ENV_LAT = os.getenv("WEATHER_LAT")
ENV_LON = os.getenv("WEATHER_LON")
# Optional manual place override for tooltip (and optional forward geocoding)
ENV_PLACE = os.getenv("WEATHER_PLACE")
# Manual place name set inside this file. If set (non-empty), this takes top priority for display
# and, if coordinates are not provided, will be used to geocode latitude/longitude.
# Example: MANUAL_PLACE = "Concord, NH, US"
MANUAL_PLACE: Optional[str] = "" #Set your city HERE

# Location icon in tooltip (default to a standard emoji to avoid missing glyphs)
LOC_ICON = os.getenv("WEATHER_LOC_ICON", "📍")
# Enable/disable Pango markup in tooltip (1/0, true/false)
TOOLTIP_MARKUP = os.getenv("WEATHER_TOOLTIP_MARKUP", "0").lower() in ("1", "true", "yes")
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
        # CACHE_DIR is a Path
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
    except Exception as e:
        print(f"Error creating cache dir: {e}", file=sys.stderr)


def _coerce_numeric(value: Any, to_int: bool) -> Optional[Union[int, float]]:
    if to_int:
        if isinstance(value, int):
            return value
        if isinstance(value, (float, str)):
            try:
                return int(float(value))
            except (ValueError, TypeError):
                return None
        return None
    else:
        if isinstance(value, float):
            return value
        if isinstance(value, int):
            return float(value)
        if isinstance(value, str):
            try:
                return float(value)
            except (ValueError, TypeError):
                return None
        return None


def coerce_int(value: Any) -> Optional[int]:
    return cast(Optional[int], _coerce_numeric(value, True))


def coerce_float(value: Any) -> Optional[float]:
    return cast(Optional[float], _coerce_numeric(value, False))


def coerce_number(value: Any) -> Union[int, float, None]:
    if isinstance(value, (int, float)):
        return value
    if isinstance(value, str):
        try:
            # Parse to float, then return int if it has no fractional part
            f = float(value)
            return int(f) if f.is_integer() else f
        except (ValueError, TypeError):
            return None
    return None


def read_api_cache() -> Optional[Dict[str, Any]]:
    try:
        if not API_CACHE_PATH.exists():
            return None
        with API_CACHE_PATH.open("r", encoding="utf-8") as f:
            data = json.load(f)
        # Use ensure_dict for safety
        data_dict = ensure_dict(data)

        # Invalidate cache if units mismatch
        if data_dict.get("units") != UNITS:
            log_debug(f"Cache units '{data_dict.get('units')}' mismatch current '{UNITS}'.")
            return None

        timestamp_val = data_dict.get("timestamp", 0)
        timestamp = coerce_float(timestamp_val) or 0
        if (time.time() - timestamp) <= CACHE_TTL_SECONDS:
            return data_dict
        return None
    except Exception as e:
        print(f"Error reading cache: {e}", file=sys.stderr)
        return None


def write_api_cache(payload: Dict[str, Any]) -> None:
    try:
        ensure_cache_dir()
        payload["timestamp"] = time.time()
        payload["units"] = UNITS
        with API_CACHE_PATH.open("w", encoding="utf-8") as f:
            json.dump(payload, f)
    except Exception as e:
        print(f"Error writing API cache: {e}", file=sys.stderr)


def write_simple_text_cache(text: str) -> None:
    try:
        ensure_cache_dir()
        with SIMPLE_TEXT_CACHE_PATH.open("w", encoding="utf-8") as f:
            f.write(text)
    except Exception as e:
        print(f"Error writing simple cache: {e}", file=sys.stderr)


def get_coords_from_env() -> Optional[Tuple[float, float]]:
    if ENV_LAT and ENV_LON:
        try:
            return float(ENV_LAT), float(ENV_LON)
        except ValueError:
            print("Invalid WEATHER_LAT/WEATHER_LON; falling back to IP geolocation", file=sys.stderr)
    return None


def get_coords_from_cache() -> Optional[Tuple[float, float]]:
    try:
        cached = read_api_cache()
        if cached:
            fc = ensure_dict(cached.get("forecast"))
            lat_raw = safe_get(fc, "latitude")
            lon_raw = safe_get(fc, "longitude")
            lat = coerce_float(lat_raw)
            lon = coerce_float(lon_raw)
            if lat is None:
                log_debug(f"Unexpected type for cached latitude: {type(lat_raw)}")
            if lon is None:
                log_debug(f"Unexpected type for cached longitude: {type(lon_raw)}")
            if lat is not None and lon is not None:
                return lat, lon
    except Exception as e:
        print(f"Reading cached coords failed: {e}", file=sys.stderr)
    return None


def get_coords_from_ipwho() -> Optional[Tuple[float, float]]:
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
    return None


def get_coords_from_ipapi() -> Optional[Tuple[float, float]]:
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
    return None


def get_coords_from_ipinfo() -> Optional[Tuple[float, float]]:
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
    return None


def get_coords_from_place_name(name: str) -> Optional[Tuple[float, float]]:
    """Forward geocode a place name to coordinates using Open-Meteo Geocoding API.

    Returns (lat, lon) if found, else None.
    """
    try:
        base = "https://geocoding-api.open-meteo.com/v1/search"
        params: Dict[str, Union[str, float]] = {
            "name": name,
            "count": 1,
            "language": os.getenv("WEATHER_LANG", "en"),
            "format": "json",
        }
        resp = SESSION.get(base, params=params, timeout=TIMEOUT)
        resp.raise_for_status()
        data = ensure_dict(resp.json())
        results = ensure_list(data.get("results"))
        if results:
            p = ensure_dict(results[0])
            lat = coerce_float(p.get("latitude"))
            lon = coerce_float(p.get("longitude"))
            if lat is not None and lon is not None:
                return float(lat), float(lon)
    except Exception as e:
        print(f"Place geocoding failed: {e}", file=sys.stderr)
    return None


def get_coords() -> Tuple[float, float]:
    # 1) Forward geocode from MANUAL_PLACE first (highest priority)
    if MANUAL_PLACE:
        place_name = MANUAL_PLACE.strip()
        coords = get_coords_from_place_name(place_name)
        if coords:
            return coords

    # 2) Explicit env coordinates
    coords = get_coords_from_env()
    if coords:
        return coords

    # 3) Forward geocode from ENV_PLACE
    if ENV_PLACE:
        place_name = ENV_PLACE.strip()
        coords = get_coords_from_place_name(place_name)
        if coords:
            return coords

    # 4) Try cached coordinates
    coords = get_coords_from_cache()
    if coords:
        return coords

    # 5) IP-based geolocation
    coords = get_coords_from_ipwho() or get_coords_from_ipapi() or get_coords_from_ipinfo()
    if coords:
        return coords

    # 6) Last resort
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
    params: Dict[str, Union[str, float]] = {
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
        params: Dict[str, Union[str, float]] = {
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


def extract_place_parts_nominatim(data_dict: JSONDict) -> List[str]:
    address = ensure_dict(data_dict.get("address"))
    candidates = [data_dict.get("name"), address.get("city"), address.get("town"), address.get("village"), address.get("hamlet")]
    name = cast(Optional[str], next((c for c in candidates if c is not None and c != ""), None))
    admin1 = cast(Optional[str], address.get("state"))
    country = cast(Optional[str], address.get("country"))
    parts: List[str] = []
    if name is not None and name != "":
        parts.append(name)
    if admin1 is not None and admin1 != "":
        parts.append(admin1)
    if country is not None and country != "":
        parts.append(country)
    return parts


def extract_place_parts_open_meteo(p: JSONDict) -> List[str]:
    name = cast(Optional[str], p.get("name"))
    admin1 = cast(Optional[str], p.get("admin1"))
    country = cast(Optional[str], p.get("country"))
    parts: List[str] = []
    if name is not None:
        parts.append(name)
    if admin1 is not None:
        parts.append(admin1)
    if country is not None:
        parts.append(country)
    return parts


def reverse_geocode(base: str, params: Dict[str, Union[str, float]], headers: Optional[Dict[str, str]] = None) -> Optional[str]:
    try:
        resp = SESSION.get(base, params=params, headers=headers, timeout=TIMEOUT)
        resp.raise_for_status()
        data = resp.json()
        data_dict = ensure_dict(data)
        parts = extract_place_parts_nominatim(data_dict)
        if parts:
            return ", ".join(parts)
    except Exception as e:
        log_debug(f"Reverse geocoding failed: {e}")
    return None


def reverse_geocode_open_meteo(lat: float, lon: float, lang: str) -> Optional[str]:
    try:
        base = "https://geocoding-api.open-meteo.com/v1/reverse"
        params: Dict[str, Union[str, float]] = {
            "latitude": lat,
            "longitude": lon,
            "language": lang,
            "format": "json",
        }
        resp = SESSION.get(base, params=params, timeout=TIMEOUT)
        resp.raise_for_status()
        data = resp.json()
        data_dict = ensure_dict(data)
        results = ensure_list(data_dict.get("results"))
        if results:
            p = ensure_dict(results[0])
            parts = extract_place_parts_open_meteo(p)
            if parts:
                return ", ".join(parts)
    except Exception as e:
        log_debug(f"Reverse geocoding (Open-Meteo) failed: {e}")
    return None


def fetch_place(lat: float, lon: float) -> Optional[str]:
    """Reverse geocode lat/lon to an approximate place. Tries Nominatim first, then Open-Meteo."""
    lang = os.getenv("WEATHER_LANG", "en")

    # 1) Nominatim (OpenStreetMap)
    base = "https://nominatim.openstreetmap.org/reverse"
    params: Dict[str, Union[str, float]] = {
        "lat": lat,
        "lon": lon,
        "format": "jsonv2",
        "accept-language": lang,
    }
    headers = {"User-Agent": UA + " Weather.py/1.0"}
    place = reverse_geocode(base, params, headers)
    if place:
        return place

    # 2) Open-Meteo reverse (fallback)
    return reverse_geocode_open_meteo(lat, lon, lang)


# =============== Build Output ===============

_T = TypeVar("_T")

JSONValue = Union[str, int, float, bool, None, "JSONDict", "JSONList"]
JSONDict = Dict[str, JSONValue]
JSONList = List[JSONValue]


def ensure_dict(value: Any) -> JSONDict:
    """Return a JSON-like dict when the incoming value looks like one."""
    if isinstance(value, dict):
        return cast(JSONDict, value)
    # Warn about unexpected type to catch API shape mismatches
    val_repr = repr(value) if value is not None else "None"
    if len(val_repr) > 100:
        val_repr = val_repr[:100] + "..."
    print(f"Warning: ensure_dict received {type(value).__name__} instead of dict: {val_repr}", file=sys.stderr)
    return cast(JSONDict, {})


def ensure_list(value: Any) -> JSONList:
    """Return a JSON-like list when the incoming value looks like one."""
    if isinstance(value, list):
        return cast(JSONList, value)
    # Warn about unexpected type to catch API shape mismatches
    val_repr = repr(value) if value is not None else "None"
    if len(val_repr) > 100:
        val_repr = val_repr[:100] + "..."
    print(f"Warning: ensure_list received {type(value).__name__} instead of list: {val_repr}", file=sys.stderr)
    return cast(JSONList, [])


def safe_get(
    obj: JSONValue | None,
    *keys: Union[str, int],
    default: _T | None = None,
) -> _T | JSONValue | None:
    """Safely traverse nested dict/list structures.

    Keys may be strings (for mapping lookups) or ints (for list indices).
    Returns ``default`` if any lookup fails.
    """

    cur: JSONValue | None = obj
    for key in keys:
        if isinstance(cur, dict):
            if not isinstance(key, str) or key not in cur:
                return default
            cur = cur[key]
        elif isinstance(cur, list):
            if not isinstance(key, int) or key < 0 or key >= len(cur):
                return default
            cur = cur[key]
        else:
            return default
    return cast(_T | JSONValue | None, cur)


def get_precipitation_probabilities(forecast: JSONDict) -> List[Optional[float]]:
    probs_raw = safe_get(forecast, "hourly", "precipitation_probability")
    probs_raw_list = ensure_list(probs_raw)
    return [coerce_float(p) if p is not None else None for p in probs_raw_list]


def find_current_index(times: List[str], cur_time: Optional[str]) -> int:
    if cur_time is not None and cur_time in times:
        return times.index(cur_time)
    return 0


def build_hourly_precip(forecast: JSONDict) -> str:
    try:
        times_raw = safe_get(forecast, "hourly", "time")
        times: List[str] = cast(List[str], ensure_list(times_raw))
        probs = get_precipitation_probabilities(forecast)
        cur_time: Optional[str] = cast(Optional[str], safe_get(forecast, "current", "time"))
        idx = find_current_index(times, cur_time)
        window = probs[idx : idx + 6]
        if not window:
            return ""
        parts = [f"{int(p)}%" if p is not None else "-" for p in window]
        return " (next 6h) " + " ".join(parts)
    except Exception:
        return ""


def build_weather_strings(cur: JSONDict, cur_units: JSONDict, daily: JSONDict, daily_units: JSONDict, temp_unit: str) -> Tuple[str, str, int, int, str, str, str]:
    temp_val = coerce_float(cur.get("temperature_2m"))
    temp_unit_str = cast(str, cur_units.get("temperature_2m", ""))
    temp_str = f"{int(round(temp_val))}{temp_unit_str}" if temp_val is not None else "N/A"

    feels_val = coerce_float(cur.get("apparent_temperature"))
    feels_unit = cast(str, cur_units.get("apparent_temperature", ""))
    feels_str = f"Feels like {int(round(feels_val))}{feels_unit}" if feels_val is not None else ""

    is_day_val = cur.get("is_day")
    is_day_int = coerce_int(is_day_val)
    is_day = is_day_int if is_day_int is not None else 1
    weather_code_val = cur.get("weather_code")
    code_int = coerce_int(weather_code_val)
    code = code_int if code_int is not None else -1
    icon = wmo_to_icon(code, is_day)
    status = wmo_to_status(code)

    tmin_val = coerce_float(safe_get(daily, "temperature_2m_min", 0))
    tmax_val = coerce_float(safe_get(daily, "temperature_2m_max", 0))
    dtemp_unit = cast(str, daily_units.get("temperature_2m_min", temp_unit))
    tmin_str = f"{int(round(tmin_val))}{dtemp_unit}" if tmin_val is not None else ""
    tmax_str = f"{int(round(tmax_val))}{dtemp_unit}" if tmax_val is not None else ""
    min_max = f"  {tmin_str}\t\t  {tmax_str}" if tmin_str and tmax_str else ""

    return temp_str, feels_str, is_day, code, icon, status, min_max


def build_weather_details(cur: JSONDict, cur_units: JSONDict) -> Tuple[str, str, str]:
    wind_val_raw = cur.get("wind_speed_10m")
    wind_val = coerce_float(wind_val_raw)
    wind_unit = cast(str, cur_units.get("wind_speed_10m", ""))
    if wind_val is None:
        log_debug(f"Unexpected type for wind_speed_10m: {type(wind_val_raw)}")
    wind_text = f"  {int(round(wind_val))}{wind_unit}" if wind_val is not None else ""

    hum_val_raw = cur.get("relative_humidity_2m")
    hum_val = coerce_float(hum_val_raw)
    if hum_val is None:
        log_debug(f"Unexpected type for relative_humidity_2m: {type(hum_val_raw)}")
    humidity_text = f"  {int(hum_val)}%" if hum_val is not None else ""

    vis_val_raw = cur.get("visibility")
    vis_val = coerce_float(vis_val_raw)
    if vis_val is None:
        log_debug(f"Unexpected type for visibility: {type(vis_val_raw)}")
    visibility_text = f"  {format_visibility(vis_val)}" if vis_val is not None else ""

    return wind_text, humidity_text, visibility_text


def build_aqi_info(aqi: Optional[Dict[str, Any]]) -> str:
    aqi_dict = ensure_dict(aqi)
    aqi_val_raw = safe_get(aqi_dict, "current", "european_aqi")
    aqi_val = coerce_float(aqi_val_raw)
    if aqi_val is None:
        log_debug(f"Unexpected type for european_aqi: {type(aqi_val_raw)}")
    return f"AQI {int(aqi_val)}" if aqi_val is not None else "AQI N/A"


def build_place_str(lat: float, lon: float, place: Optional[str]) -> str:
    effective_place = MANUAL_PLACE or ENV_PLACE or place
    if effective_place:
        return effective_place
    return f"{lat:.3f}, {lon:.3f}"




class TooltipParams(NamedTuple):
    temp_str: str
    icon: str
    status: str
    location_text: str
    feels_str: str
    min_max: str
    wind_text: str
    humidity_text: str
    visibility_text: str
    aqi_text: str
    hourly_precip: str


def build_tooltip_markup(params: TooltipParams) -> str:
    return str.format(
        "\t\t{}\t\t\n{}\n{}\n{}\n{}\n\n{}\n{}\n{}{}",
        f'<span size="xx-large">{esc(params.temp_str)}</span>',
        f"<big> {params.icon}</big>",
        f"<b>{esc(params.status)}</b>",
        esc(params.location_text),
        f"<small>{esc(params.feels_str)}</small>" if params.feels_str else "",
        f"<b>{esc(params.min_max)}</b>" if params.min_max else "",
        f"{esc(params.wind_text)}\t{esc(params.humidity_text)}",
        f"{esc(params.visibility_text)}\t{esc(params.aqi_text)}",
        f"<i> {esc(params.hourly_precip)}</i>" if params.hourly_precip else "",
    )


def build_tooltip_plain(params: TooltipParams) -> str:
    lines = [
        f"{params.icon}  {params.temp_str}",
        params.status,
        params.location_text,
    ]
    if params.feels_str:
        lines.append(params.feels_str)
    if params.min_max:
        lines.append(params.min_max)
    combined_wind = f"{params.wind_text} {params.humidity_text}".strip()
    if combined_wind:
        lines.append(combined_wind)
    combined_visibility = f"{params.visibility_text} {params.aqi_text}".strip()
    if combined_visibility:
        lines.append(combined_visibility)
    if params.hourly_precip:
        lines.append(params.hourly_precip)
    return "\n".join([ln for ln in lines if ln])


def build_tooltip_text(params: TooltipParams) -> str:
    if TOOLTIP_MARKUP:
        return build_tooltip_markup(params)
    else:
        return build_tooltip_plain(params)


def gather_weather_data(forecast: Optional[Dict[str, Any]], aqi: Optional[Dict[str, Any]]) -> WeatherData:
    forecast_dict = ensure_dict(forecast)
    cur = ensure_dict(forecast_dict.get("current"))
    cur_units = ensure_dict(forecast_dict.get("current_units"))
    daily = ensure_dict(forecast_dict.get("daily"))
    daily_units = ensure_dict(forecast_dict.get("daily_units"))

    temp_str, feels_str, is_day, code, icon, status, min_max = build_weather_strings(cur, cur_units, daily, daily_units, cast(str, cur_units.get("temperature_2m", "")))
    wind_text, humidity_text, visibility_text = build_weather_details(cur, cur_units)
    aqi_text = build_aqi_info(aqi)
    hourly_precip = build_hourly_precip(forecast_dict)

    return WeatherData(
        temp_str=temp_str,
        feels_str=feels_str,
        icon=icon,
        status=status,
        min_max=min_max,
        wind_text=wind_text,
        humidity_text=humidity_text,
        visibility_text=visibility_text,
        aqi_text=aqi_text,
        hourly_precip=hourly_precip,
        is_day=is_day,
        code=code,
    )


def build_output(loc: Location, forecast: Optional[Dict[str, Any]], aqi: Optional[Dict[str, Any]]) -> Tuple[Dict[str, str], str]:
    data = gather_weather_data(forecast, aqi)

    place_str = build_place_str(loc.lat, loc.lon, loc.place)
    location_text = f"{LOC_ICON}  {place_str}"

    tooltip_text = build_tooltip_text(
        TooltipParams(
            data.temp_str, data.icon, data.status, location_text, data.feels_str, data.min_max,
            data.wind_text, data.humidity_text, data.visibility_text, data.aqi_text, data.hourly_precip
        )
    )

    out_data: Dict[str, Any] = {
        "text": f"{data.icon}  {data.temp_str}",
        "alt": data.status,
        "tooltip": tooltip_text,
        "class": f"wmo-{data.code} {'day' if data.is_day else 'night'}",
    }

    simple_weather = (
        f"{place_str}\n"
        f"{data.icon}  {data.status}\n"
        + f"  {data.temp_str} ({data.feels_str})\n"
        + (f" {data.wind_text} \n" if data.wind_text else "")
        + (f" {data.humidity_text} \n" if data.humidity_text else "")
        + f" {data.visibility_text} {data.aqi_text}\n"
    )

    return out_data, simple_weather


def try_cached_weather(lat: float, lon: float) -> Optional[Tuple[Dict[str, str], str]]:
    cached = read_api_cache()
    if cached:
        forecast = cast(Optional[Dict[str, Any]], cached.get("forecast"))
        aqi = cast(Optional[Dict[str, Any]], cached.get("aqi"))
        place_val = cached.get("place")
        cached_place = place_val if isinstance(place_val, str) else None
        # Ensure the cached forecast corresponds to the requested lat/lon
        fc = ensure_dict(cached.get("forecast"))
        c_lat = coerce_float(safe_get(fc, "latitude"))
        c_lon = coerce_float(safe_get(fc, "longitude"))
        if c_lat is not None and c_lon is not None:
            if abs(c_lat - lat) > 0.1 or abs(c_lon - lon) > 0.1:
                return None  # force fresh fetch for new location
        try:
            return build_output(Location(lat, lon, cached_place), forecast, aqi)
        except Exception as e:
            print(f"Cached data build failed, refetching: {e}", file=sys.stderr)
    return None


def fetch_fresh_weather(lat: float, lon: float) -> Optional[Tuple[Dict[str, str], str]]:
    try:
        forecast = fetch_open_meteo(lat, lon)
        aqi = fetch_aqi(lat, lon)
        # If MANUAL_PLACE is set, don't reverse geocode - use the manual place instead
        place = MANUAL_PLACE if MANUAL_PLACE else fetch_place(lat, lon)
        write_api_cache({"forecast": forecast, "aqi": aqi, "place": place})
        return build_output(Location(lat, lon, place), forecast, aqi)
    except Exception as e:
        print(f"Open-Meteo fetch failed: {e}", file=sys.stderr)
    return None


def try_stale_weather(lat: float, lon: float) -> Optional[Tuple[Dict[str, str], str]]:
    try:
        if API_CACHE_PATH.exists():
            with API_CACHE_PATH.open("r", encoding="utf-8") as f:
                stale = json.load(f)
            stale_dict = ensure_dict(stale)
            place_val = stale_dict.get("place")
            place = place_val if isinstance(place_val, str) else None
            forecast = cast(Optional[Dict[str, Any]], stale_dict.get("forecast"))
            aqi = cast(Optional[Dict[str, Any]], stale_dict.get("aqi"))
            return build_output(Location(lat, lon, place), forecast, aqi)
    except Exception as e2:
        print(f"Failed to use stale cache: {e2}", file=sys.stderr)
    return None


def main() -> None:
    lat, lon = get_coords()

    # Try cache first
    result = try_cached_weather(lat, lon)
    if result:
        out, simple = result
        print(json.dumps(out, ensure_ascii=False))
        write_simple_text_cache(simple)
        return

    # Fetch fresh
    result = fetch_fresh_weather(lat, lon)
    if result:
        out, simple = result
        print(json.dumps(out, ensure_ascii=False))
        write_simple_text_cache(simple)
        return

    # Last resort: try stale cache
    result = try_stale_weather(lat, lon)
    if result:
        out, simple = result
        print(json.dumps(out, ensure_ascii=False))
        write_simple_text_cache(simple)
        return

    # Fallback minimal output
    fallback = {
        "text": f"{WEATHER_ICONS['default']}  N/A",
        "alt": "Unavailable",
        "tooltip": "Weather unavailable",
        "class": "unavailable",
    }
    print(json.dumps(fallback, ensure_ascii=False))


def test_coerce_functions():
    """Manual testing for coerce functions."""
    # Test coerce_int
    assert coerce_int(5) == 5
    assert coerce_int(5.5) == 5
    assert coerce_int("5") == 5
    assert coerce_int("5.7") == 5
    assert coerce_int("abc") is None
    assert coerce_int(None) is None

    # Test coerce_float
    assert coerce_float(5.5) == 5.5
    assert coerce_float(5) == 5.0
    assert coerce_float("5.5") == 5.5
    assert coerce_float("abc") is None
    assert coerce_float(None) is None

    # Test coerce_number
    assert coerce_number(5) == 5
    assert coerce_number(5.5) == 5.5
    assert coerce_number("5") == 5
    assert coerce_number("5.5") == 5.5
    assert coerce_number("abc") is None

    print("All coerce function tests passed.", file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--test":
        test_coerce_functions()
    else:
        main()
