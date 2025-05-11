# src/api/app.py
import pickle, pandas as pd
from flask import Flask, jsonify, abort, request
from sklearn.neighbors import NearestNeighbors
from sklearn.preprocessing import StandardScaler

MODEL_DIR = "models"
DATA_CSV  = "data/playlist_enriched.csv"

df_meta = pd.read_csv(DATA_CSV).set_index("id")
X_full  = pd.read_pickle(f"{MODEL_DIR}/X_full.pkl")

with open(f"{MODEL_DIR}/scaler.pkl", "rb") as f:
    scaler: StandardScaler = pickle.load(f)
with open(f"{MODEL_DIR}/nn_model.pkl", "rb") as f:
    nn: NearestNeighbors = pickle.load(f)

X_scaled = scaler.transform(X_full.values)

def nearest(track_id: str, k: int):
    if track_id not in df_meta.index:
        abort(404, f"{track_id} not found")
    idx = X_full.index.get_loc(track_id)
    _, inds = nn.kneighbors([X_scaled[idx]], n_neighbors=k + 1)
    ids = X_full.index[inds.flatten()[1:]]
    return (df_meta.loc[ids, ["name", "artists"]]
              .reset_index().to_dict(orient="records"))

app = Flask(__name__)

@app.get("/recommend/<track_id>")
def recommend(track_id):
    k = int(request.args.get("k", 5))
    return jsonify(nearest(track_id, k))

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
