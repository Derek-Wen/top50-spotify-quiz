# src/train_recommender.py
"""
Train k-NN on numeric metadata + genre & country dummies.
Stores:
  models/scaler.pkl
  models/nn_model.pkl
  models/feature_order.json
"""
import os, json, pickle, pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.neighbors import NearestNeighbors

DATA_CSV  = "data/playlist_enriched.csv"
MODEL_DIR = "models"
os.makedirs(MODEL_DIR, exist_ok=True)

df = pd.read_csv(DATA_CSV).set_index("id")

# numeric base
numeric_cols = [
    "popularity","duration_ms","explicit",
    "age_days","artist_popularity","artist_followers",
    "n_artist_genres"
]
X_num = df[numeric_cols]

# genre dummies
all_genres = (
    df["genres"].fillna("").str.split("|").explode()
      .str.lower().value_counts()
)
top_genres = all_genres.head(10).index.tolist()

def genre_vec(s):
    gset = set(map(str.lower, s.split("|"))) if pd.notna(s) else set()
    return [int(g in gset) for g in top_genres]

genre_df = pd.DataFrame(
    df["genres"].apply(genre_vec).tolist(),
    columns=[f"genre_{g}" for g in top_genres],
    index=df.index
)

# country dummies
freq_cty = df["isrc_country"].value_counts()
freq_cty = freq_cty[freq_cty >= 2].index.tolist()

country_df = pd.get_dummies(
    df["isrc_country"].where(df["isrc_country"].isin(freq_cty), "OTHER"),
    prefix="cty"
)

# combine
X_full = pd.concat([X_num, genre_df, country_df], axis=1)
feature_order = X_full.columns.tolist()

# scale & train
scaler = StandardScaler().fit(X_full.values)
X_scaled = scaler.transform(X_full.values)
nn = NearestNeighbors(n_neighbors=6, metric="euclidean").fit(X_scaled)

# save
X_full.to_pickle(f"{MODEL_DIR}/X_full.pkl")
with open(f"{MODEL_DIR}/scaler.pkl", "wb") as f: pickle.dump(scaler, f)
with open(f"{MODEL_DIR}/nn_model.pkl", "wb") as f: pickle.dump(nn, f)
with open(f"{MODEL_DIR}/feature_order.json", "w") as f:
    json.dump(feature_order, f)

seed = df.index[0]
_, inds = nn.kneighbors([X_scaled[0]], n_neighbors=6)
print("Model trained. 5 nearest to", df.loc[seed,"name"], "→")
for rid in df.index[inds.flatten()[1:]]:
    print(" •", df.loc[rid,"name"], "—", df.loc[rid,"artists"])
