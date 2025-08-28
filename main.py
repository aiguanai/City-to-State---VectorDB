import pandas as pd
from sentence_transformers import SentenceTransformer
import faiss
import numpy as np

# Load dataset
DATA_PATH = "indian_states_cities.csv"  # make sure this file is in the same folder
df = pd.read_csv(DATA_PATH)

# Load sentence transformer model
print("Loading model...")
model = SentenceTransformer("all-MiniLM-L6-v2")

# Encode city names into embeddings
print("Encoding city names...")
city_embeddings = model.encode(df["City"].tolist(), convert_to_numpy=True)

# Build FAISS index
dim = city_embeddings.shape[1]  # embedding dimension
index = faiss.IndexFlatL2(dim)
index.add(city_embeddings)

print(f"FAISS index built with {index.ntotal} cities.")

# Helper dictionary: city -> state
city_to_state = df.set_index("City")["State"].to_dict()

# Function to fetch state for a city
def get_state_for_city(query_city: str, k: int = 1):
    query_vec = model.encode([query_city], convert_to_numpy=True)
    distances, indices = index.search(query_vec, k=k)

    results = []
    for idx in indices[0]:
        matched_city = df.iloc[idx]["City"]
        matched_state = city_to_state[matched_city]
        results.append((matched_city, matched_state))
    
    return results

# Example queries
if __name__ == "__main__":
    while True:
        query = input("\nEnter city name (or 'exit' to quit): ").strip()
        if query.lower() == "exit":
            break
        matches = get_state_for_city(query, k=1)
        best_city, state = matches[0]
        print(f"✅ Closest match: {best_city} → State: {state}")
