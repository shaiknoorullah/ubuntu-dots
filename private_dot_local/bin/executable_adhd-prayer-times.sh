#!/usr/bin/env bash
# adhd-prayer-times.sh — regenerate ~/.config/adhd/prayer-times.conf OFFLINE.
#
# Location: Hyderabad, India · Hanafi madhab · University of Islamic Sciences,
# Karachi calculation method. Computed locally with adhanpy (no network, no
# location sent anywhere) in a self-bootstrapping venv. Edit the constants
# below to change location/convention.
set -euo pipefail

LAT=17.3850
LON=78.4867
TZ="Asia/Kolkata"
METHOD=KARACHI      # CalculationMethod name (KARACHI = University of Islamic Sciences)
MADHAB=HANAFI       # HANAFI (later Asr) or SHAFI

VDIR="$HOME/.local/share/adhd/venv"
CONF="$HOME/.config/adhd/prayer-times.conf"
mkdir -p "$(dirname "$CONF")"

# one-time bootstrap (needs network once); fully offline thereafter
if [ ! -x "$VDIR/bin/python" ]; then
    /usr/bin/python3 -m venv "$VDIR"
    "$VDIR/bin/pip" install -q --disable-pip-version-check adhanpy
fi

"$VDIR/bin/python" - "$LAT" "$LON" "$TZ" "$METHOD" "$MADHAB" "$CONF" <<'PY'
import sys
from datetime import datetime
from zoneinfo import ZoneInfo
from adhanpy.PrayerTimes import PrayerTimes
from adhanpy.calculation.CalculationMethod import CalculationMethod
from adhanpy.calculation.CalculationParameters import CalculationParameters
from adhanpy.calculation.Madhab import Madhab

lat, lon, tzname, method, madhab, conf = (
    float(sys.argv[1]), float(sys.argv[2]), sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6])
tz = ZoneInfo(tzname)
params = CalculationParameters(method=getattr(CalculationMethod, method))
params.madhab = getattr(Madhab, madhab)
pt = PrayerTimes((lat, lon), datetime.now(tz), calculation_parameters=params, time_zone=tz)

hdr = [
    f"# auto-generated {datetime.now(tz):%Y-%m-%d} — {tzname} · {madhab.title()} · "
    f"{method.title()} method · offline (adhanpy)",
    "# regenerated daily by adhd-prayer-times.timer; change location in "
    "~/.local/bin/adhd-prayer-times.sh",
]
rows = [f"{n} {t:%H:%M}" for n, t in [
    ("Fajr", pt.fajr), ("Dhuhr", pt.dhuhr), ("Asr", pt.asr),
    ("Maghrib", pt.maghrib), ("Isha", pt.isha)]]
open(conf, "w").write("\n".join(hdr + rows) + "\n")
print("wrote", conf)
PY
