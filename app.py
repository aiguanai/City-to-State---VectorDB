from flask import Flask, render_template, request, jsonify
import pandas as pd
import faiss
import numpy as np
import os

# Set cache directories before importing sentence_transformers
cache_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), '.cache')
os.environ['TRANSFORMERS_CACHE'] = cache_dir
os.environ['HF_HOME'] = cache_dir
os.environ['HF_DATASETS_CACHE'] = cache_dir

from sentence_transformers import SentenceTransformer

app = Flask(__name__)

# Global variables for the model and index
model = None
index = None
city_to_state = None
df = None

def initialize_model():
    """Initialize the sentence transformer model and FAISS index"""
    global model, index, city_to_state, df
    
    print("Loading model...")
    try:
        # Create cache directory if it doesn't exist
        os.makedirs(cache_dir, exist_ok=True)
        
        # Try to load the model
        model = SentenceTransformer("all-MiniLM-L6-v2")
        print("Model loaded successfully!")
    except Exception as e:
        print(f"Error loading model: {e}")
        raise e  # Re-raise the error to stop the app if model fails
    
    # Load dataset
    DATA_PATH = "indian_states_cities.csv"
    df = pd.read_csv(DATA_PATH)
    
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
    
    print("Model initialization complete!")

def get_state_for_city(query_city: str, k: int = 1):
    """Function to fetch state for a city using vector similarity"""
    query_vec = model.encode([query_city], convert_to_numpy=True)
    distances, indices = index.search(query_vec, k=k)

    results = []
    for idx in indices[0]:
        matched_city = df.iloc[idx]["City"]
        matched_state = city_to_state[matched_city]
        distance = distances[0][len(results)]  # Get the distance for this result
        results.append({
            'city': matched_city, 
            'state': matched_state, 
            'distance': float(distance)
        })
    
    return results

@app.route('/')
def index_page():
    """Main page with the search form"""
    return render_template('index.html')

@app.route('/search', methods=['POST'])
def search_city():
    """API endpoint to search for city and return state"""
    try:
        # Check if model is loaded
        if model is None or index is None:
            return jsonify({'error': 'Model not loaded. Please try again later.'}), 503
        
        data = request.get_json()
        city_name = data.get('city', '').strip()
        
        if not city_name:
            return jsonify({'error': 'City name is required'}), 400
        
        # Get the best match
        results = get_state_for_city(city_name, k=1)
        
        if not results:
            return jsonify({'error': 'No results found'}), 404
        
        best_match = results[0]
        
        return jsonify({
            'success': True,
            'query': city_name,
            'matched_city': best_match['city'],
            'state': best_match['state'],
            'confidence': 1 - best_match['distance']  # Convert distance to confidence score
        })
        
    except Exception as e:
        return jsonify({'error': f'Internal server error: {str(e)}'}), 500

@app.route('/search_multiple', methods=['POST'])
def search_multiple_cities():
    """API endpoint to search for multiple cities and return top matches"""
    try:
        data = request.get_json()
        city_name = data.get('city', '').strip()
        k = min(int(data.get('k', 3)), 10)  # Limit to max 10 results
        
        if not city_name:
            return jsonify({'error': 'City name is required'}), 400
        
        # Get multiple matches
        results = get_state_for_city(city_name, k=k)
        
        if not results:
            return jsonify({'error': 'No results found'}), 404
        
        formatted_results = []
        for result in results:
            formatted_results.append({
                'city': result['city'],
                'state': result['state'],
                'confidence': 1 - result['distance']
            })
        
        return jsonify({
            'success': True,
            'query': city_name,
            'results': formatted_results
        })
        
    except Exception as e:
        return jsonify({'error': f'Internal server error: {str(e)}'}), 500

@app.route('/health')
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None,
        'index_loaded': index is not None,
        'total_cities': index.ntotal if index else 0
    })

# Initialize the model when the module is imported (for Gunicorn)
print("Initializing model on app startup...")
try:
    initialize_model()
    print("Model initialization completed successfully!")
except Exception as e:
    print(f"Error during model initialization: {e}")
    import traceback
    traceback.print_exc()
    # Don't exit, let the app start but mark model as failed
    model = None
    index = None
    city_to_state = None
    df = None

# Model loading is handled at startup, no need for before_first_request

if __name__ == '__main__':
    # Run the Flask app
    app.run(host='0.0.0.0', port=5000, debug=False)
