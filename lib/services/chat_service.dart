import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String baseUrl =
      'https://nongnghiep-xanh-ai.nguyenduytuong093.workers.dev';

  static Future<String> sendMessage(
    String message, {
    String context = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'context': context,
      }),
    ).timeout(const Duration(seconds: 90));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error'] ?? 'AI lỗi HTTP ${response.statusCode}');
    }

    final answer = data['answer'];
    if (answer is! String || answer.trim().isEmpty) {
      throw Exception('AI chưa trả về câu trả lời.');
    }

    return answer;
  }
}
