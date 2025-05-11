# src/fetch_top50.py
"""
Fetch playlist, enrich with metadata + cover_url.
Now excludes album_total_tracks and preview_url,
but keeps genres, isrc_country, n_artist_genres.
"""

import os, pandas as pd
from datetime import datetime
from dotenv import load_dotenv
import spotipy
from spotipy.oauth2 import SpotifyClientCredentials

def fetch_all(sp, playlist_id):
    res = sp.playlist_items(playlist_id, fields="items.track,next", limit=100)
    items = res["items"]
    while res["next"]:
        res = sp.next(res)
        items.extend(res["items"])
    return [it["track"] for it in items if it.get("track")]

def main():
    load_dotenv()
    sp = spotipy.Spotify(
        auth_manager=SpotifyClientCredentials(
            os.getenv("SPOTIPY_CLIENT_ID"), os.getenv("SPOTIPY_CLIENT_SECRET"))
    )

    PLAYLIST_ID = "7z4ebkPXukjtS08NxvoyoN"
    tracks = fetch_all(sp, PLAYLIST_ID)
    print("Fetched", len(tracks), "tracks")

    today = datetime.utcnow(); recs = []

    for tr in tracks:
        full = sp.track(tr["id"]); art = sp.artist(full["artists"][0]["id"])
        rd   = full["album"]["release_date"] or "1900"
        fmt  = "%Y-%m-%d" if len(rd) == 10 else "%Y"
        age  = (today - datetime.strptime(rd, fmt)).days
        genres = art.get("genres", [])
        recs.append({
            "id"      : full["id"],
            "name"    : full["name"],
            "artists" : ", ".join(a["name"] for a in full["artists"]),
            "cover_url": full["album"]["images"][1]["url"],
            # numeric
            "popularity"       : full["popularity"],
            "duration_ms"      : full["duration_ms"],
            "explicit"         : int(full["explicit"]),
            "age_days"         : age,
            "artist_popularity": art["popularity"],
            "artist_followers" : art["followers"]["total"],
            # categorical helpers
            "genres"           : "|".join(genres),
            "n_artist_genres"  : len(genres),
            "isrc_country"     : (full.get("external_ids", {})
                                     .get("isrc","")[:2].upper() or "NA")
        })

    os.makedirs("data", exist_ok=True)
    pd.DataFrame(recs).to_csv("data/playlist_enriched.csv", index=False)
    print("→ playlist_enriched.csv written with", len(recs), "rows")

if __name__ == "__main__":
    main()
