
import spacy
import fitz
from fastapi import FastAPI, UploadFile, File
from pydantic import BaseModel
from io import BytesIO
import os
import pickle
import re
import nltk
from nltk.corpus import stopwords

# Ensure NLTK stopwords are available
nltk.download('stopwords')
stop_words = set(stopwords.words('english'))

# === Load Models ===

# Load SpaCy NER model
ner_model_path = r"E:\Flutter_Projects\freelancing_system\model-20250327T022230Z-001\model\output\model-best"
nlp = spacy.load(ner_model_path)

# Load TF-IDF Vectorizer
with open(r"E:\Flutter_Projects\freelancing_system\model-20250327T022230Z-001\tfidf_vectorizer (2).pkl", "rb") as f:
    tfidf_vectorizer = pickle.load(f)

# Load Random Forest model
with open(r"E:\Flutter_Projects\freelancing_system\model-20250327T022230Z-001\rf_score_model (2).pkl", "rb") as f:
    rf_model = pickle.load(f)

# === FastAPI app ===
app = FastAPI()

# === Helper Functions ===
def extract_text_from_pdf(pdf_path):
    """Extract raw text from PDF using PyMuPDF (fitz)"""
    text = ""
    doc = fitz.open(pdf_path)
    for page in doc:
        text += page.get_text()
    return text.strip()

def preprocess_text(text):
    """Clean text and remove stopwords for TF-IDF vectorization"""
    text = re.sub(r'[^\w\s]', '', text)  # remove punctuation
    text = re.sub(r'\d+', '', text)      # remove digits
    text = text.lower()
    tokens = text.split()
    tokens = [word for word in tokens if word not in stop_words]
    return " ".join(tokens)

# === Resume Processing Function ===
def process_resume(file: UploadFile):
    upload_folder = "E:\\Flutter_Projects\\freelancing_system\\uploads"
    os.makedirs(upload_folder, exist_ok=True)
    
    file_path = os.path.join(upload_folder, file.filename)
    
    # Save uploaded file
    with open(file_path, "wb") as f:
        f.write(file.file.read())

    # Extract and preprocess text
    text = extract_text_from_pdf(file_path)
    cleaned_text = preprocess_text(text)

    # Predict score using TF-IDF + RF model
    tfidf_vector = tfidf_vectorizer.transform([cleaned_text])
    predicted_score = rf_model.predict(tfidf_vector)[0]

    # Extract entities with SpaCy NER model
    doc = nlp(text)
    entities = {}
    for ent in doc.ents:
        label = ent.label_
        if label not in entities:
            entities[label] = []
        entities[label].append(ent.text.strip())

    # Build simple feedback based on score
    review = []
    review.append(f"📊 Resume Score: {predicted_score}/10")
    if predicted_score >= 8:
        review.append("✅ Excellent resume! Well optimized.")
    elif predicted_score >= 6:
        review.append("🟡 Good resume. Consider improving a few areas.")
    else:
        review.append("🔴 Resume needs improvement for better visibility.")

    return {
        "message": "Resume processed successfully.",
        "file_path": file_path,
        "score": float(predicted_score),
        "entities": entities,
        "review": "\n".join(review)
    }

# === FastAPI Endpoint ===
@app.post("/process_resume/")
async def process_resume_endpoint(file: UploadFile = File(...)):
    result = process_resume(file)
    return result
