import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatAiScreen extends StatefulWidget {
  const ChatAiScreen({super.key});

  @override
  State<ChatAiScreen> createState() => _ChatAiScreenState();
}

class _ChatAiScreenState extends State<ChatAiScreen> {
  final controller = TextEditingController();
  final scrollController = ScrollController();
  final messages = <Map<String, String>>[];

  bool loading = false;

  Future<void> sendMessage() async {
    final question = controller.text.trim();
    if (question.isEmpty || loading) return;

    controller.clear();

    setState(() {
      messages.add({'role': 'user', 'text': question});
      loading = true;
    });

    try {
      final result = await ApiService.chat(
        message: question,
        context: 'Ứng dụng Nông Nghiệp Xanh',
      );

      if (!mounted) return;

      setState(() {
        messages.add({
          'role': 'ai',
          'text': result['answer']?.toString() ??
              'AI chưa có câu trả lời.',
        });
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        messages.add({
          'role': 'ai',
          'text': 'Lỗi kết nối AI: $e',
        });
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.eco, color: Colors.green),
            SizedBox(width: 8),
            Text('Nông Nghiệp Xanh AI'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.smart_toy,
                              size: 65, color: Colors.green),
                          SizedBox(height: 15),
                          Text(
                            'Xin chào! Tôi là Nông Nghiệp Xanh AI.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Hỏi tôi về cây trồng, sâu bệnh, '
                            'phân bón, thời tiết và mùa vụ nhé!',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length + (loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircularProgressIndicator(
                                  strokeWidth: 2),
                              SizedBox(width: 12),
                              Text('AI đang suy nghĩ...'),
                            ],
                          ),
                        );
                      }

                      final msg = messages[index];
                      final isUser = msg['role'] == 'user';

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.85,
                          ),
                          margin: const EdgeInsets.symmetric(
                              vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.green.shade700
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SelectableText(
                            msg['text'] ?? '',
                            style: TextStyle(
                              color: isUser
                                  ? Colors.white
                                  : Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Nhập câu hỏi nông nghiệp...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: loading ? null : sendMessage,
                    icon: const Icon(Icons.send),
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
