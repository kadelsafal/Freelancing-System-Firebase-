import spacy
import fitz
from fastapi import FastAPI, UploadFile, File
from pydantic import BaseModel
from io import BytesIO
import os

# Load your trained model
model_path = "/content/drive/MyDrive/model/output/model-best"
nlp = spacy.load(model_path)

# FastAPI app instance
app = FastAPI()

# Function to extract text from PDF
def extract_text_from_pdf(pdf_path):
    text = ""
    doc = fitz.open(pdf_path)
    for page in doc:
        text += page.get_text()
    return text

# Function to calculate resume score
def calculate_resume_score(entities):
    score = 0

    # Core Information (30%)
    score += 0.02 if 'NAME' in entities else 0
    score += 0.03 if 'CONTACT' in entities else 0
    score += 0.03 if 'EMAIL ADDRESS' in entities else 0
    score += 0.02 if 'LOCATION' in entities else 0
    score += 0.02 if 'LINKEDIN LINK' in entities else 0
    score += 0.05 if 'YEARS OF EXPERIENCE' in entities else 0
    score += 0.03 if 'YEAR OF GRADUATION' in entities else 0
    score += 0.05 if 'DEGREE' in entities else 0
    score += 0.05 if ('COLLEGE NAME' in entities or 'UNIVERSITY' in entities) else 0

    # Professional Experience (30%)
    companies_score = min(0.10, 0.02 * len(entities.get('COMPANIES WORKED AT', [])))
    score += companies_score
    score += 0.10 if 'DESIGNATION' in entities else 0
    score += 0.10 if 'WORKED AS' in entities else 0

    # Skills & Qualifications (25%)
    skills_score = min(0.15, 0.015 * len(entities.get('SKILLS', [])))
    score += skills_score
    score += min(0.05, 0.01 * len(entities.get('CERTIFICATION', [])))
    score += min(0.03, 0.01 * len(entities.get('AWARDS', [])))
    score += min(0.02, 0.005 * len(entities.get('LANGUAGE', [])))

    # Completeness & Structure (15%)
    core_present = ('NAME' in entities and 'CONTACT' in entities and
                   'EMAIL ADDRESS' in entities and
                   ('DEGREE' in entities or 'SKILLS' in entities))
    score += 0.10 if core_present else 0
    score += 0.05 if core_present else 0

    return round(score * 10, 1)  # Convert to 10-point scale

# Function to generate resume review
def generate_resume_review(entities, score):
    review = []
    strengths = []
    improvements = []

    # Core information analysis
    if 'NAME' in entities:
        strengths.append(f"Name provided: {entities['NAME'][0]}")
    else:
        improvements.append("Missing name - this is essential")

    if 'CONTACT' in entities:
        strengths.append("Contact information provided")
    else:
        improvements.append("Missing contact information - recruiters can't reach you")

    if 'EMAIL ADDRESS' in entities:
        strengths.append(f"Email provided: {entities['EMAIL ADDRESS'][0]}")
    else:
        improvements.append("Missing email address - crucial for communication")

    if 'DEGREE' in entities:
        strengths.append(f"Educational qualification: {', '.join(entities['DEGREE'])}")
    else:
        improvements.append("Missing degree information - important for most roles")

    # Professional experience
    if 'COMPANIES WORKED AT' in entities:
        strength_msg = f"Work experience at {len(entities['COMPANIES WORKED AT'])} company(s)"
        if len(entities['COMPANIES WORKED AT']) > 0:
            strength_msg += f": {', '.join(entities['COMPANIES WORKED AT'][:3])}..."
        strengths.append(strength_msg)
    else:
        improvements.append("Missing work experience details - highlight your professional journey")

    # Skills section
    if 'SKILLS' in entities:
        skills_msg = f"Skills listed ({len(entities['SKILLS'])} total)"
        if len(entities['SKILLS']) > 0:
            skills_msg += f": {', '.join(entities['SKILLS'][:5])}..."
        strengths.append(skills_msg)
    else:
        improvements.append("Missing skills section - crucial for applicant tracking systems")

    # Additional qualifications
    if 'CERTIFICATION' in entities:
        strengths.append(f"{len(entities['CERTIFICATION'])} certification(s) listed")
    if 'AWARDS' in entities:
        strengths.append(f"{len(entities['AWARDS'])} award(s) listed")

    # Generate final review
    review.append(f"\n=== Resume Score: {score}/10 ===")

    if score >= 8:
        review.append("\nExcellent resume! Strong in most areas.")
    elif score >= 6:
        review.append("\nGood resume. Some areas could be strengthened.")
    else:
        review.append("\nResume needs significant improvement to be competitive.")

    review.append("\n=== STRENGTHS ===")
    review.extend(strengths if strengths else ["- No major strengths identified"])

    review.append("\n=== AREAS FOR IMPROVEMENT ===")
    review.extend(improvements if improvements else ["- No major improvements needed!"])

    return "\n".join(review)

# Main processing function
def process_resume(file: UploadFile):
    # Save the uploaded file temporarily
    file_path = "/tmp/uploaded_resume.pdf"
    with open(file_path, "wb") as f:
        f.write(file.file.read())

    # Extract text from PDF
    text = extract_text_from_pdf(file_path)

    # Process with spaCy model
    doc = nlp(text)

    # Extract entities and organize them
    entities = {}
    for ent in doc.ents:
        if ent.label_ not in entities:
            entities[ent.label_] = []
        entities[ent.label_].append(ent.text)

    # Calculate score
    score = calculate_resume_score(entities)

    # Generate review
    review = generate_resume_review(entities, score)

    return {"score": score, "review": review}

# FastAPI endpoint for resume processing
@app.post("/process_resume/")
async def process_resume_endpoint(file: UploadFile = File(...)):
    result = process_resume(file)
    return result
