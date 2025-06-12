from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from textblob import TextBlob

app = FastAPI()

# Allow connections from any origin for easy testing
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, narrow this!
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/mood")
async def analyze_mood(request: Request):
    data = await request.json()
    text = data.get("text")
    if not text:
        return {"mood": "neutral"}

    blob = TextBlob(text)
    polarity = blob.sentiment.polarity

    if polarity > 0.2:
        mood = "happy"
    elif polarity < -0.2:
        mood = "angry"
    else:
        mood = "neutral"
    return {"mood": mood}