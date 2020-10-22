import json, os
from urllib.request import urlopen

LASTFM_API_KEY = "7a4d07b562808c8719440b8ff387e5ef"
USERNAME = "andrewfinke"
TIMEPERIOD = "1month"

url = "http://ws.audioscrobbler.com/2.0/?method=user.gettoptracks&user={}&api_key={}&format=json&period={}".format(USERNAME, LASTFM_API_KEY, TIMEPERIOD)

with urlopen(url) as resource:
    j = json.load(resource)

    track = j["toptracks"]["track"][0]
    text = "{} has played {} {} times".format(USERNAME, track["name"], track["playcount"]).replace("\"", "\\\"")

    os.system("""
              osascript -e 'display dialog "{}"'
              """.format(text))
