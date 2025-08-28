# City2State VectorDB (India)

![Python](https://img.shields.io/badge/python-3.9%2B-blue)
![FAISS](https://img.shields.io/badge/FAISS-vector%20db-orange)
![SentenceTransformers](https://img.shields.io/badge/Sentence--Transformers-NLP-green)
![Pandas](https://img.shields.io/badge/Pandas-Data%20Handling-yellow)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

This project demonstrates how to use **Sentence Transformers** and **FAISS (Vector Database)** to find the **state of any Indian city** using semantic search.

---

## 📌 Project Overview
- Input: A city name (e.g., `Mumbai`).
- Output: The corresponding state (e.g., `Maharashtra`).
- Dataset: List of **Indian states and their cities**, stored in `indian_states_cities.csv`.
- Vector Search: Uses embeddings to semantically match city names with their states.

---

## ⚙️ Installation

1. Clone this repository and navigate to the folder.
2. Make sure you have Python 3.9+ installed.
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

---

## 📂 Dataset
The dataset `indian_states_cities.csv` contains:
```
State,City
Maharashtra,Mumbai
Tamil Nadu,Chennai
Karnataka,Bengaluru Urban
...
```

---

## 🚀 Usage

Run the main script:

```bash
python main.py
```

Then type a city name when prompted:

```
Enter city name (or 'exit' to quit): Mumbai
✅ Closest match: Mumbai → State: Maharashtra
```

---

## 🛠️ Tech Stack
- [Sentence Transformers](https://www.sbert.net/) for text embeddings.
- [FAISS](https://github.com/facebookresearch/faiss) for vector similarity search.
- [Pandas](https://pandas.pydata.org/) for CSV handling.

---

## 📌 Future Improvements
- Extend dataset to include **all countries** (using GeoNames or similar).
- Build a **FastAPI/Flask API** for web-based queries.
- Add fuzzy matching for misspellings (optional).

---

## 👨‍💻 Author
Developed as a learning project for **Vector Databases + NLP embeddings**. 
