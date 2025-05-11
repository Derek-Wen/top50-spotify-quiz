# Flask API - Spotify Recommendation Service

## API Overview

This Flask API serves as the backend recommendation engine for the Spotify Cover Art Quiz application. It provides song recommendations based on a k-Nearest Neighbors (k-NN) model.

## Structure

- **`app.py`**: Flask application script, handling API requests.
- **`Dockerfile`**: Docker Image.

## Endpoints:

- `GET /recommend/<track_id>?k=<num>`: Returns recommended songs in JSON format.

## *Run with Docker:

```bash
docker build -t spotify-api .
docker run -d --name spotify-api \
  -p 8000:8000 spotify-api
```