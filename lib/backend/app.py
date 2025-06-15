from flask import Flask, request, jsonify
from flask_cors import CORS
from textblob import TextBlob

app = Flask(__name__)
CORS(app)  # Allow cross-origin requests

@app.route('/analyze', methods=['POST'])
def analyze():
    data = request.json
    text = data.get('text', '')
    if not text:
        return jsonify({"error": "No text provided"}), 400

    blob = TextBlob(text)
    polarity = blob.sentiment.polarity

    if polarity > 0.2:
        mood = "happy"
    elif polarity < -0.2:
        mood = "sad"
    else:
        mood = "neutral"

    return jsonify({'mood': mood, 'score': polarity})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)