from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from textblob import TextBlob

app = FastAPI()

# CORS middleware to allow frontend apps to call the API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change this to your frontend domain in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/mood")
async def analyze_mood(request: Request):
    try:
        data = await request.json()
        text: str = data.get("text")

        if not text:
            raise HTTPException(status_code=400, detail="Missing 'text' in request.")

        blob = TextBlob(text)
        polarity = blob.sentiment.polarity

        if polarity > 0.2:
            mood = "happy"
        elif polarity < -0.2:
            mood = "angry"
        else:
            mood = "neutral"

        return {"mood": mood}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
