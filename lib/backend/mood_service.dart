import 'dart:convert';
import 'package:http/http.dart' as http;

class MoodService {
  static Future<String> getMood(String text) async {
    final url = Uri.parse('http://YOUR_BACKEND_IP:8000/mood'); // Change this
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['mood'] ?? 'neutral';
    } else {
      return 'neutral';
    }
  }
}